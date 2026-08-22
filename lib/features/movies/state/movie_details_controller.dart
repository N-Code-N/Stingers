import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/errors/error_handlers.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';

/// State for one film's screen, including casting a vote.
///
/// Two error channels, split by blast radius: [error] blocks the screen when there is
/// nothing to render at all, while a failed vote goes to [showError] as a snackbar so
/// the film stays on screen. A queued vote is not a failure and gets its own callback.
class MovieDetailsController extends ChangeNotifier {
  MovieDetailsController({
    required MovieRepository repository,
    required this.tmdbId,
    required void Function(Object error) showError,
    required void Function() showQueued,
  }) : _repository = repository,
       _showError = showError,
       _showQueued = showQueued;

  final MovieRepository _repository;
  final int tmdbId;
  final void Function(Object error) _showError;
  final void Function() _showQueued;

  StreamSubscription<MovieDetails?>? _subscription;

  MovieDetails? _details;
  bool _isLoading = true;
  bool _suppressIncomingDetails = false;

  /// The row a forced reload took off the screen, and the row the database offered while
  /// it was off. A drift stream never replays, so anything not kept here is gone: a
  /// refresh that fails writes nothing that would make it emit again.
  MovieDetails? _blankedDetails;
  MovieDetails? _offeredDetails;
  int _inFlight = 0;

  // Captured on the first tap of this visit: the aggregate and the vote as they stood
  // before this screen touched them. Every later tap is folded onto this same base, so
  // answering "yes there was" and then "worth it" cannot count the user twice.
  SceneStats? _statsBeforeVoting;
  MyVote? _voteBeforeVoting;
  ({bool hasScene, bool? worthIt})? _myAnswer;
  Object? _error;
  bool _disposed = false;

  MovieDetails? get details => _details;
  bool get isLoading => _isLoading;

  /// True while at least one vote is still on its way. Nothing on this screen is
  /// disabled by it — the local write already moved the UI — but a caller may show a
  /// quiet indicator.
  bool get isVoting => _inFlight > 0;

  /// The aggregate the verdict panel renders.
  ///
  /// Before the user answers, whatever the database holds. From their first tap until
  /// they leave, the answer their own tap produced — folded in here, at an assumed
  /// weight of 1, because the client is never told its own trust score.
  ///
  /// The server's real recount is deliberately *not* shown on this visit. It arrives two
  /// Edge Function round trips after the tap and the repository writes it to the database
  /// where it belongs — but painting it here would move the verdict under a reader who
  /// answered seconds ago, which is the one moment they are actually looking at it. They
  /// see the real weight the next time they open the film.
  SceneStats get displayStats {
    final answer = _myAnswer;
    final base = _statsBeforeVoting;
    if (answer == null || base == null) return _details?.stats ?? SceneStats.empty;
    return base.withOwnVote(
      previous: _voteBeforeVoting,
      hasScene: answer.hasScene,
      worthIt: answer.worthIt,
    );
  }

  Object? get error => _error;

  MyVote? get myVote => _details?.myVote;

  /// True once the film has been loaded in full, so the screen can tell an empty
  /// description from one that simply has not been fetched yet.
  bool get hasFullDetails => _details?.detailsFetchedAt != null;

  Future<void> load({bool force = false}) async {
    _subscription ??= _repository.watchMovie(tmdbId).listen(_onDetails);
    // Blanking exists for one reason: a forced reload must not leave the outgoing copy
    // on screen while it fetches a new one, or switching language flashes the previous
    // language. So it applies only when there is an outgoing copy to hide. Opening the
    // film fresh has nothing on screen, and blanking there hides the cache from the
    // reader instead — which with no connection means hiding the film itself, behind a
    // network call that may never answer.
    if (force && _details != null) {
      _suppressIncomingDetails = true;
      _blankedDetails = _details;
      _offeredDetails = null;
      _details = null;
    }
    if (force) _isLoading = true;
    _error = null;
    _notify();
    try {
      await _repository.refreshMovie(tmdbId, force: force);
    } on AppException catch (e) {
      // Nothing was written, so the database has no reason to emit again — take back
      // whatever the blanking hid, rather than reporting a film we are holding.
      _details ??= _offeredDetails ?? _blankedDetails;
      // Only fatal with nothing cached. Otherwise the stream is already showing the
      // film and a failed refresh is not worth a screen.
      if (_details == null) _error = e;
    } finally {
      _suppressIncomingDetails = false;
      // Held back above rather than dropped, because a refresh that succeeded may
      // already have spent its one emission inside this window.
      _details ??= _offeredDetails;
      _blankedDetails = null;
      _offeredDetails = null;
      _isLoading = false;
      _notify();
    }
  }

  /// Answers the first question. Changing it to "no scene" clears any previous
  /// worth-it answer, mirroring the database's `worth_it_only_with_scene` constraint.
  Future<void> setHasScene(bool hasScene) =>
      _vote(hasScene: hasScene, worthIt: hasScene ? myVote?.worthIt : null);

  /// Answers the second question. Only reachable once the first is "yes".
  Future<void> setWorthIt(bool worthIt) => _vote(hasScene: true, worthIt: worthIt);

  /// Fires immediately. Nothing here awaits the network: the answer is folded into
  /// [displayStats] on this line, so the verdict has already moved by the time the
  /// delivery starts.
  Future<void> _vote({required bool hasScene, required bool? worthIt}) {
    if (_myAnswer == null) {
      _statsBeforeVoting = _details?.stats ?? SceneStats.empty;
      _voteBeforeVoting = myVote;
    }
    _myAnswer = (hasScene: hasScene, worthIt: worthIt);
    _inFlight++;
    _notify();
    return _send(hasScene: hasScene, worthIt: worthIt);
  }

  Future<void> _send({required bool hasScene, required bool? worthIt}) async {
    try {
      final outcome = await _repository.castVote(
        tmdbId: tmdbId,
        hasScene: hasScene,
        worthIt: worthIt,
      );
      // The screen that owns this controller may already be gone: the repository write
      // is not cancelled just because the user backed out of the details page.
      if (_disposed) return;
      if (outcome == VoteOutcome.queued) _showQueued();
    } on AppException catch (e) {
      // On a rejection the repository has already restored the previous vote and
      // aggregate and the stream has repainted; all that is left is telling the user it
      // did not land. A transport failure normally comes back as `queued` instead, so
      // reaching here with one means the vote was not even written.
      if (!_disposed) _showError(e);
    } on Object catch (e, stack) {
      // Anything unexpected is reported rather than thrown at a tap handler nobody
      // awaits, where it would surface as an unhandled async error.
      reportError(e, stack);
    } finally {
      _inFlight--;
      _notify();
    }
  }

  void _onDetails(MovieDetails? details) {
    if (_suppressIncomingDetails) {
      // Held back rather than dropped: a forced reload must not paint the copy it is
      // replacing, but [load] still needs this if the refresh brings nothing.
      _offeredDetails = details;
      return;
    }
    _details = details;
    if (details != null) _isLoading = false;
    _notify();
  }

  /// Guards every call: the repository write and its stream keep running after the
  /// screen backs out and disposes this controller, and `ChangeNotifier` throws if
  /// `notifyListeners` is called once `dispose()` has run.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
