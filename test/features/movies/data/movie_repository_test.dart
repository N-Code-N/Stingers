import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/db/app_database.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/integrity/attestation_service.dart';
import 'package:stingers/core/integrity/install_identity.dart';
import 'package:stingers/features/movies/data/local_store.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/data/movie_repository.dart';
import 'package:stingers/features/movies/data/scene_vote_service.dart';
import 'package:stingers/features/movies/data/tmdb_service.dart';

/// Hand-rolled fakes. The services are thin wrappers around one external system each,
/// so there is nothing in them worth mocking a framework for — the repository is what
/// is under test.
class FakeTmdbService implements TmdbService {
  FakeTmdbService({this.pages = const {}, this.movies = const {}});

  Map<int, MoviesPage> pages;
  Map<int, Movie> movies;
  Object? failure;

  int nowPlayingCalls = 0;
  int detailsCalls = 0;
  final List<String> searches = [];

  @override
  Future<MoviesPage> nowPlaying({int page = 1}) async {
    nowPlayingCalls++;
    if (failure != null) throw failure!;
    return pages[page] ?? const MoviesPage(movies: [], page: 1, totalPages: 1);
  }

  @override
  Future<Movie> details(int tmdbId) async {
    detailsCalls++;
    if (failure != null) throw failure!;
    final movie = movies[tmdbId];
    if (movie == null) throw const NotFoundException('no such film');
    return movie;
  }

  @override
  Future<MoviesPage> search(String query, {int page = 1}) async {
    searches.add(query);
    if (failure != null) throw failure!;
    return MoviesPage(
      movies: movies.values.toList(growable: false),
      page: 1,
      totalPages: 1,
    );
  }
}

class FakeSceneVoteService implements SceneVoteService {
  Map<int, SceneStats> stats = {};
  List<MyVote> serverVotes = [];
  Object? statsFailure;
  Object? submitFailure;
  Object? challengeFailure;

  int statsCalls = 0;
  int challengeCalls = 0;
  final List<int> submitted = [];
  final List<String> noncesUsed = [];

  /// Runs before the submit is recorded, so a test can hold one delivery open or decide
  /// per call whether the server accepts it.
  Future<void> Function()? beforeSubmit;

  @override
  Future<String> requestChallenge({
    required int tmdbId,
    required String installId,
    required String platform,
  }) async {
    challengeCalls++;
    if (challengeFailure != null) throw challengeFailure!;
    return 'nonce-$tmdbId-$challengeCalls';
  }

  @override
  Future<Map<int, SceneStats>> statsFor(List<int> tmdbIds) async {
    statsCalls++;
    if (statsFailure != null) throw statsFailure!;
    return {
      for (final id in tmdbIds)
        if (stats.containsKey(id)) id: stats[id]!,
    };
  }

  @override
  Future<List<MyVote>> myVotes() async => serverVotes;

  @override
  Future<SceneStats> submit({
    required int tmdbId,
    required String installId,
    required String platform,
    required bool hasScene,
    required bool? worthIt,
    required String nonce,
    required String? attestationToken,
    required String? attestationVerdict,
  }) async {
    if (beforeSubmit != null) await beforeSubmit!();
    submitted.add(tmdbId);
    noncesUsed.add(nonce);
    if (submitFailure != null) throw submitFailure!;
    return stats[tmdbId] ?? SceneStats.empty;
  }
}

void main() {
  // InstallIdentity probes a platform channel and expects the miss.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalStore local;
  late FakeTmdbService tmdb;
  late FakeSceneVoteService votes;
  late ApiMovieRepository repository;
  late DateTime now;

  Movie movie(int id, [String title = 'Film']) => Movie(
    tmdbId: id,
    title: title,
    posterPath: null,
    releaseDate: null,
    originalTitle: '',
  );

  SceneStats stats({double total = 4, double scene = 3}) => SceneStats(
    rawVotes: total.round(),
    totalWeight: total,
    sceneWeight: scene,
    worthWeight: 0,
    worthTotal: 0,
  );

  setUp(() {
    now = DateTime(2026, 8, 15, 12);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalStore(db);
    tmdb = FakeTmdbService();
    votes = FakeSceneVoteService();
    repository = ApiMovieRepository(
      local: local,
      tmdb: tmdb,
      votes: votes,
      identity: InstallIdentity(db: db),
      // No native side in a test, so every attestation is 'unavailable' — which is
      // exactly the path a simulator takes in production, and it must still vote.
      attestation: AttestationService(),
      now: () => now,
    );
  });

  tearDown(() => db.close());

  group('feed', () {
    test('joins TMDb films to our own stats by tmdb_id', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1, 'A'), movie(2, 'B')], page: 1, totalPages: 3),
      };
      votes.stats = {1: stats(total: 14, scene: 12)};

      await repository.refreshFeed();
      final snapshot = await repository.watchFeed().first;

      expect(snapshot.items.map((i) => i.movie.title), ['A', 'B']);
      expect(snapshot.items.first.stats.verdictPercent, 86);
      expect(snapshot.items.first.stats.hasScene, isTrue);
    });

    test('a film with no votes yet gets a zero state, not an exception', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1)], page: 1, totalPages: 1),
      };
      votes.stats = {};

      await repository.refreshFeed();
      final snapshot = await repository.watchFeed().first;

      expect(snapshot.items.single.stats.hasVerdict, isFalse);
      expect(snapshot.items.single.stats.rawVotes, 0);
    });

    test('the vote service going down costs the badges, not the feed', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1, 'A')], page: 1, totalPages: 1),
      };
      votes.statsFailure = const UnknownApiException('votes are down');

      await repository.refreshFeed();
      final snapshot = await repository.watchFeed().first;

      expect(snapshot.items.single.movie.title, 'A');
      expect(snapshot.items.single.stats.hasVerdict, isFalse);
    });

    test('a failed refresh leaves the cached feed readable', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1, 'A')], page: 1, totalPages: 1),
      };
      await repository.refreshFeed();

      tmdb.failure = const NetworkException();
      now = now.add(const Duration(days: 1)); // past the TTL, so it really tries

      // The repository reports the failure — deciding between "banner" and "error
      // screen" is the controller's job, and it needs to know.
      await expectLater(repository.refreshFeed(), throwsA(isA<NetworkException>()));

      final snapshot = await repository.watchFeed().first;
      expect(snapshot.items.single.movie.title, 'A');
    });

    test('a page inside its TTL is not refetched', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1)], page: 1, totalPages: 1),
      };

      await repository.refreshFeed();
      now = now.add(const Duration(hours: 1));
      await repository.refreshFeed();

      expect(tmdb.nowPlayingCalls, 1);
    });

    test('a forced refresh ignores the TTL', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1)], page: 1, totalPages: 1),
      };

      await repository.refreshFeed();
      await repository.refreshFeed(force: true);

      expect(tmdb.nowPlayingCalls, 2);
    });

    test('reports whether TMDb has another page', () async {
      tmdb.pages = {
        1: MoviesPage(movies: [movie(1)], page: 1, totalPages: 1),
        2: MoviesPage(movies: [movie(2)], page: 2, totalPages: 5),
      };

      expect(await repository.refreshFeed(page: 1), isFalse);
      expect(await repository.refreshFeed(page: 2), isTrue);
    });

    test('asks for a whole page of stats in one request, never one per row', () async {
      tmdb.pages = {
        1: MoviesPage(
          movies: List.generate(20, (i) => movie(i + 1)),
          page: 1,
          totalPages: 1,
        ),
      };

      await repository.refreshFeed();

      expect(votes.statsCalls, 1);
    });
  });

  group('one film', () {
    test('fetches details and stats together', () async {
      tmdb.movies = {7: movie(7, 'Dune')};
      votes.stats = {7: stats()};

      await repository.refreshMovie(7);
      final details = await repository.watchMovie(7).first;

      expect(details!.movie.title, 'Dune');
      expect(details.stats.totalWeight, 4);
      expect(details.detailsFetchedAt, now);
    });

    test('a stats failure still leaves the film readable', () async {
      tmdb.movies = {7: movie(7, 'Dune')};
      votes.statsFailure = const UnknownApiException('down');

      await repository.refreshMovie(7);
      final details = await repository.watchMovie(7).first;

      expect(details!.movie.title, 'Dune');
      expect(details.stats.hasVerdict, isFalse);
    });

    test('a failed details read keeps its own type on the way up', () async {
      tmdb.movies = {7: movie(7)};
      tmdb.failure = const UpstreamUnavailableException('tmdb is down');

      // The details and the stats read are joined here, and the controller above
      // dispatches on the exception type. A join that repackaged the failure would turn
      // the film's error screen into an unhandled async error.
      await expectLater(
        repository.refreshMovie(7),
        throwsA(isA<UpstreamUnavailableException>()),
      );
    });

    test('refreshes only the stats when the details are still fresh', () async {
      tmdb.movies = {7: movie(7)};
      votes.stats = {7: stats()};
      await repository.refreshMovie(7);

      // Past the 1h stats TTL, inside the 24h details TTL.
      now = now.add(const Duration(hours: 2));
      await repository.refreshMovie(7);

      expect(tmdb.detailsCalls, 1);
      expect(votes.statsCalls, 2);
    });
  });

  group('casting a vote', () {
    setUp(() async {
      tmdb.movies = {7: movie(7)};
      await repository.refreshMovie(7);
    });

    test('writes locally, sends, and clears the queue', () async {
      votes.stats = {7: stats(total: 5, scene: 5)};

      final outcome = await repository.castVote(tmdbId: 7, hasScene: true, worthIt: true);

      expect(outcome, VoteOutcome.sent);
      expect(votes.submitted, [7]);

      final details = await repository.watchMovie(7).first;
      expect(details!.myVote!.hasScene, isTrue);
      expect(details.myVote!.pendingSync, isFalse);
      expect(details.stats.totalWeight, 5, reason: 'the server aggregate wins');
    });

    test('moves the percentage before the round trip finishes', () async {
      // The vote is written to the database, and the database is what the UI reads —
      // so the optimistic update is a real row, not a UI-only illusion.
      await local.saveStats({7: stats(total: 9, scene: 9)}, now);
      votes.submitFailure = const NetworkException();

      await repository.castVote(tmdbId: 7, hasScene: false, worthIt: null);

      final details = await repository.watchMovie(7).first;
      expect(details!.stats.totalWeight, closeTo(9 + SceneStats.assumedOwnWeight, 1e-9));
      expect(details.stats.sceneWeight, 9);
      // 9 of 9.12 still say there is a scene, so the number moves off 100 without
      // pretending one unattested device is worth a whole unit of weight.
      expect(details.stats.verdictPercent, 99);
    });

    test('offline, the vote is queued rather than lost', () async {
      votes.submitFailure = const NetworkException();

      final outcome = await repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);

      expect(outcome, VoteOutcome.queued);
      expect((await local.pendingVotes()).map((v) => v.tmdbId), [7]);
    });

    test('a server rejection rolls the vote and the aggregate back', () async {
      await local.saveStats({7: stats(total: 9, scene: 9)}, now);
      votes.submitFailure = const VoteRejectedException('rate limited');

      await expectLater(
        repository.castVote(tmdbId: 7, hasScene: true, worthIt: null),
        throwsA(isA<VoteRejectedException>()),
      );

      final details = await repository.watchMovie(7).first;
      expect(details!.myVote, isNull, reason: 'there was no previous vote to restore');
      expect(details.stats.totalWeight, 9);
    });

    test('a rejected change restores the previous vote, not nothing', () async {
      await repository.castVote(tmdbId: 7, hasScene: true, worthIt: true);
      votes.submitFailure = const VoteRejectedException('rate limited');

      await expectLater(
        repository.castVote(tmdbId: 7, hasScene: false, worthIt: null),
        throwsA(isA<VoteRejectedException>()),
      );

      final details = await repository.watchMovie(7).first;
      expect(details!.myVote!.hasScene, isTrue);
      expect(details.myVote!.worthIt, isTrue);
    });

    test('every vote carries a fresh single-use nonce', () async {
      await repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);
      await repository.castVote(tmdbId: 7, hasScene: false, worthIt: null);

      expect(votes.challengeCalls, 2);
      expect(votes.noncesUsed.toSet(), hasLength(2));
    });

    test('a failure to get a challenge queues the vote like any other outage', () async {
      votes.challengeFailure = const NetworkException();

      final outcome = await repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);

      expect(outcome, VoteOutcome.queued);
      expect(votes.submitted, isEmpty);
    });

    test('a refused vote does not erase the answer given after it', () async {
      tmdb.movies = {7: movie(7)};
      await repository.refreshMovie(7);

      final gate = Completer<void>();
      votes.beforeSubmit = () async {
        // The first tap is refused; the second is accepted.
        votes.submitFailure = votes.submitted.isEmpty
            ? const VoteRejectedException('slow down')
            : null;
        await gate.future;
      };

      // "Yes, there was", then "worth it" — two taps a moment apart, which is the normal
      // way to use the screen. The second lands while the first is still in flight.
      final first = repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);
      final second = repository.castVote(tmdbId: 7, hasScene: true, worthIt: true);
      await pumpEventQueue();
      expect((await local.readVote(7))!.worthIt, isTrue, reason: 'both taps written');

      gate.complete();
      await expectLater(first, throwsA(isA<VoteRejectedException>()));
      await second;

      // Rolling the first tap back must not take the second one with it: the server
      // accepted it, so the screen has to keep showing it.
      final vote = await local.readVote(7);
      expect(vote, isNotNull);
      expect(vote!.hasScene, isTrue);
      expect(vote.worthIt, isTrue);
      expect(vote.pendingSync, isFalse);
    });

    test('a no-scene vote cannot carry a worth-it answer', () async {
      await repository.castVote(tmdbId: 7, hasScene: false, worthIt: true);

      final details = await repository.watchMovie(7).first;
      expect(details!.myVote!.worthIt, isNull);
    });
  });

  group('the offline queue', () {
    setUp(() async {
      tmdb.movies = {7: movie(7)};
      await repository.refreshMovie(7);
      votes.submitFailure = const NetworkException();
      await repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);
      votes.submitFailure = null;
      votes.submitted.clear();
    });

    test('flushes when the network comes back', () async {
      final sent = await repository.flushPendingVotes();

      expect(sent, 1);
      expect(votes.submitted, [7]);
      expect(await local.pendingVotes(), isEmpty);
    });

    test('a queued vote gets its nonce when it is sent, not when it was cast', () async {
      // A nonce minted at voting time would have expired hours ago; this is why the
      // challenge is requested at submit time.
      final before = votes.challengeCalls;

      await repository.flushPendingVotes();

      expect(votes.challengeCalls, before + 1);
    });

    test('a refresh that succeeds is itself the trigger', () async {
      tmdb.pages = {1: const MoviesPage(movies: [], page: 1, totalPages: 1)};

      await repository.refreshFeed();

      expect(votes.submitted, [7]);
    });

    test('re-sending is harmless, so a second flush is a no-op', () async {
      await repository.flushPendingVotes();
      final again = await repository.flushPendingVotes();

      expect(again, 0);
      expect(votes.submitted, [7]);
    });

    test('still offline, the queue is kept', () async {
      votes.submitFailure = const NetworkException();

      expect(await repository.flushPendingVotes(), 0);
      expect(await local.pendingVotes(), hasLength(1));
    });

    test('a permanently refused vote is dropped instead of retried forever', () async {
      votes.submitFailure = const VoteRejectedException('no');

      expect(await repository.flushPendingVotes(), 0);
      expect(await local.pendingVotes(), isEmpty);
    });
  });

  group('my votes', () {
    test('fills in votes cast on a previous install', () async {
      tmdb.movies = {7: movie(7, 'Dune')};
      await repository.refreshMovie(7);
      votes.serverVotes = [
        MyVote(tmdbId: 7, hasScene: true, worthIt: false, updatedAt: now),
      ];

      await repository.refreshMyVotes();
      final entries = await repository.watchMyVotes().first;

      expect(entries.single.movie.title, 'Dune');
      expect(entries.single.vote.hasScene, isTrue);
    });
  });

  group('search', () {
    test('caches by query and does not refetch inside the TTL', () async {
      tmdb.movies = {1: movie(1, 'Dune')};

      await repository.refreshSearch('Dune');
      await repository.refreshSearch(' dune ');

      expect(tmdb.searches, ['Dune']);
      expect((await repository.watchSearch('DUNE').first).single.movie.title, 'Dune');
    });

    test('an empty query never reaches the network', () async {
      await repository.refreshSearch('   ');
      expect(tmdb.searches, isEmpty);
    });
  });
}
