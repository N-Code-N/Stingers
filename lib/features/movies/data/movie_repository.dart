import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/integrity/attestation_service.dart';
import '../../../core/integrity/install_identity.dart';
import 'local_store.dart';
import 'movie_models.dart';
import 'scene_vote_service.dart';
import 'tmdb_service.dart';

/// What a vote actually did. Queuing is a normal outcome, not a failure — the plan's
/// acceptance test is "vote in airplane mode, it flies off by itself later".
enum VoteOutcome { sent, queued }

abstract interface class MovieRepository {
  Stream<FeedSnapshot> watchFeed();

  /// Returns whether TMDb says another page exists, which is the only piece of paging
  /// state the local database cannot answer on its own.
  Future<bool> refreshFeed({int page, bool force});

  Stream<MovieDetails?> watchMovie(int tmdbId);
  Future<void> refreshMovie(int tmdbId, {bool force});

  Stream<List<MovieWithStats>> watchSearch(String query);
  Future<void> refreshSearch(String query, {bool force});

  Stream<List<MyVoteEntry>> watchMyVotes();
  Future<void> refreshMyVotes();

  Future<VoteOutcome> castVote({
    required int tmdbId,
    required bool hasScene,
    required bool? worthIt,
  });

  Future<int> flushPendingVotes();
}

/// Where the two data sources are sewn together.
///
/// This is the layer the whole architecture exists for: film metadata comes from TMDb,
/// the verdict comes from our own votes, and neither knows about the other. Two rules
/// hold everywhere below:
///
///  * **Reads are served from Drift, never straight from the network.** Every `watch*`
///    returns a database stream; every `refresh*` writes into the database and lets the
///    stream repaint. `UI → API` is the bug this app is built to avoid.
///  * **A stats failure degrades, it does not propagate.** If the vote service is down
///    the feed still renders, just without badges. Losing the secondary read must not
///    cost the screen.
class ApiMovieRepository implements MovieRepository {
  ApiMovieRepository({
    required LocalStore local,
    required TmdbService tmdb,
    required SceneVoteService votes,
    required InstallIdentity identity,
    required AttestationService attestation,
    DateTime Function() now = DateTime.now,
  }) : _local = local,
       _tmdb = tmdb,
       _votes = votes,
       _identity = identity,
       _attestation = attestation,
       _now = now;

  /// Refresh intervals from PROJECT_PLAN.md §7. Cached content is always shown first;
  /// these only decide whether it is worth spending a request to refresh it.
  static const Duration feedTtl = Duration(hours: 6);
  static const Duration detailsTtl = Duration(hours: 24);
  static const Duration statsTtl = Duration(hours: 1);
  static const Duration searchTtl = Duration(hours: 24);

  final LocalStore _local;
  final TmdbService _tmdb;
  final SceneVoteService _votes;
  final InstallIdentity _identity;
  final AttestationService _attestation;
  final DateTime Function() _now;

  /// Deliveries run one at a time. Each holds a snapshot to roll back to, and two in
  /// flight at once would each restore their own — the loser undoing the winner. The
  /// *local* write is deliberately not in this queue: see [castVote].
  Future<void> _delivery = Future<void>.value();

  // --- feed ----------------------------------------------------------------

  @override
  Stream<FeedSnapshot> watchFeed() => _local.watchFeed();

  @override
  Future<bool> refreshFeed({int page = 1, bool force = false}) async {
    // A page already inside its TTL is left alone; the stream is already showing it.
    // "Maybe" is the honest answer about further pages in that case.
    if (!force && _isFresh(await _local.feedPageFetchedAt(page), feedTtl)) return true;

    final result = await _tmdb.nowPlaying(page: page);
    final ids = result.movies.map((m) => m.tmdbId).toList(growable: false);
    // Sequential rather than `Future.wait`, because the ids to ask about only exist once
    // the first call has returned. The degradation is the same.
    final stats = await _statsOrEmpty(ids);

    await _local.saveFeedPage(
      page: page,
      movies: result.movies,
      stats: stats,
      fetchedAt: _now(),
    );

    // The network is demonstrably up, which is the trigger the offline queue waits for.
    await flushPendingVotes();

    return result.hasMore;
  }

  // --- one film ------------------------------------------------------------

  @override
  Stream<MovieDetails?> watchMovie(int tmdbId) => _local.watchMovie(tmdbId);

  @override
  Future<void> refreshMovie(int tmdbId, {bool force = false}) async {
    final needsDetails =
        force || !_isFresh(await _local.detailsFetchedAt(tmdbId), detailsTtl);
    final needsStats = force || !_isFresh(await _local.statsFetchedAt(tmdbId), statsTtl);
    if (!needsDetails && !needsStats) return;

    // Here the id *is* known up front, so the two reads genuinely are independent and go
    // out together.
    final results = await Future.wait([
      if (needsDetails) _tmdb.details(tmdbId) else Future.value(null),
      if (needsStats)
        _statsOrEmpty([tmdbId])
      else
        Future.value(const <int, SceneStats>{}),
    ]);

    final movie = results[0] as Movie?;
    final stats = results[1] as Map<int, SceneStats>;
    final at = _now();

    if (movie != null) await _local.saveMovieDetails(movie, at);
    if (stats.isNotEmpty) await _local.saveStats(stats, at);
  }

  // --- search --------------------------------------------------------------

  @override
  Stream<List<MovieWithStats>> watchSearch(String query) => _local.watchSearch(query);

  @override
  Future<void> refreshSearch(String query, {bool force = false}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (!force && _isFresh(await _local.searchFetchedAt(trimmed), searchTtl)) return;

    final result = await _tmdb.search(trimmed);
    final ids = result.movies.map((m) => m.tmdbId).toList(growable: false);
    final stats = await _statsOrEmpty(ids);

    await _local.saveSearch(
      query: trimmed,
      movies: result.movies,
      stats: stats,
      fetchedAt: _now(),
    );
  }

  // --- votes ---------------------------------------------------------------

  @override
  Stream<List<MyVoteEntry>> watchMyVotes() => _local.watchMyVotes();

  @override
  Future<void> refreshMyVotes() async {
    final server = await _votes.myVotes();
    await _local.mergeServerVotes(server);
  }

  /// Writes the vote locally first, then tries to send it.
  ///
  /// The local row is what the UI reads, so writing it first *is* the optimistic update
  /// — and it is also what survives a restart. Rolling back therefore has to happen
  /// here, in the database, not in the controller that cannot reach it.
  ///
  /// A transport failure leaves the row queued and reports [VoteOutcome.queued]; a
  /// server-side rejection restores whatever was there before and rethrows, because a
  /// rejected vote must not sit in the queue retrying forever.
  ///
  /// The local write happens immediately and is **not** serialised behind an earlier
  /// vote's delivery. Answering "yes, there was" and then "worth it" two taps apart is
  /// the normal way to use the screen, and the second tap arrives while the first is
  /// still two round trips from the server. Making the second write wait for the first
  /// delivery is what made the screen sit frozen for a couple of seconds.
  @override
  Future<VoteOutcome> castVote({
    required int tmdbId,
    required bool hasScene,
    required bool? worthIt,
  }) async {
    final previous = await _local.readVote(tmdbId);
    final previousStats = await _local.readStats(tmdbId);
    final at = _now();
    final resolvedWorthIt = hasScene ? worthIt : null;

    await _local.saveVote(
      MyVote(
        tmdbId: tmdbId,
        hasScene: hasScene,
        worthIt: resolvedWorthIt,
        updatedAt: at,
        pendingSync: true,
      ),
    );
    await _local.saveStats({
      tmdbId: previousStats.withOwnVote(
        previous: previous,
        hasScene: hasScene,
        worthIt: resolvedWorthIt,
      ),
    }, at);

    final delivery = _delivery.then(
      (_) => _deliver(
        tmdbId: tmdbId,
        hasScene: hasScene,
        worthIt: resolvedWorthIt,
        previous: previous,
        previousStats: previousStats,
        at: at,
      ),
    );
    // Two futures on purpose: the caller gets the one that reports the failure, and the
    // chain gets one that never fails, because a rejected error left in `_delivery`
    // would make every later vote wait on a future that can only throw.
    _delivery = delivery.then((_) {}, onError: (_) {});
    return delivery;
  }

  Future<VoteOutcome> _deliver({
    required int tmdbId,
    required bool hasScene,
    required bool? worthIt,
    required MyVote? previous,
    required SceneStats previousStats,
    required DateTime at,
  }) async {
    try {
      final stats = await _sendVote(tmdbId: tmdbId, hasScene: hasScene, worthIt: worthIt);
      await _local.markSynced(tmdbId);
      await _local.saveStats({tmdbId: stats}, _now());
      return VoteOutcome.sent;
    } on NetworkException {
      return VoteOutcome.queued;
    } on ApiException {
      if (previous == null) {
        await _local.deleteVote(tmdbId);
      } else {
        await _local.saveVote(previous);
      }
      await _local.saveStats({tmdbId: previousStats}, at);
      rethrow;
    }
  }

  /// Sends whatever is queued. Safe to call at any time and as often as you like: a vote
  /// is upserted on (film, device) server-side, so a duplicate send is a no-op.
  @override
  Future<int> flushPendingVotes() async {
    final pending = await _local.pendingVotes();
    if (pending.isEmpty) return 0;

    var sent = 0;

    for (final vote in pending) {
      try {
        final stats = await _sendVote(
          tmdbId: vote.tmdbId,
          hasScene: vote.hasScene,
          worthIt: vote.worthIt,
        );
        await _local.markSynced(vote.tmdbId);
        await _local.saveStats({vote.tmdbId: stats}, _now());
        sent++;
      } on NetworkException {
        // Still offline. Stop rather than grind through the rest of the queue.
        break;
      } on ApiException catch (e) {
        // Refused rather than undeliverable: dropping it is the only way out of a queue
        // that would otherwise retry it on every resume forever.
        debugPrint('dropping rejected queued vote for ${vote.tmdbId}: $e');
        await _local.deleteVote(vote.tmdbId);
      }
    }

    return sent;
  }

  /// The full three-step write: ask for a single-use nonce, get the platform to vouch
  /// for the build against that nonce, then send the vote with both.
  ///
  /// The nonce is fetched here rather than when the screen opens, so a vote queued in
  /// airplane mode gets a fresh one at the moment it is finally sent — a nonce minted
  /// hours earlier would have expired.
  ///
  /// Attestation never blocks the vote. A device that cannot attest still votes; it just
  /// carries less weight, decided server-side.
  Future<SceneStats> _sendVote({
    required int tmdbId,
    required bool hasScene,
    required bool? worthIt,
  }) async {
    final installId = await _identity.installId();
    final platform = _identity.platform;

    final nonce = await _votes.requestChallenge(
      tmdbId: tmdbId,
      installId: installId,
      platform: platform,
    );
    final attestation = await _attestation.attest(nonce);

    return _votes.submit(
      tmdbId: tmdbId,
      installId: installId,
      platform: platform,
      hasScene: hasScene,
      worthIt: worthIt,
      nonce: nonce,
      attestationToken: attestation.token,
      attestationVerdict: attestation.verdict.wireName,
    );
  }

  // --- shared --------------------------------------------------------------

  /// The degradation rule in one place: no stats is a feed without badges, never a
  /// failed feed. Only the vote service's own failures are swallowed — a TMDb failure
  /// still propagates, because without films there is no screen.
  Future<Map<int, SceneStats>> _statsOrEmpty(List<int> ids) async {
    try {
      return await _votes.statsFor(ids);
    } on AppException catch (e) {
      debugPrint('stats unavailable, feed degrades to no badges: $e');
      return const {};
    }
  }

  bool _isFresh(DateTime? fetchedAt, Duration ttl) =>
      fetchedAt != null && _now().difference(fetchedAt) < ttl;
}
