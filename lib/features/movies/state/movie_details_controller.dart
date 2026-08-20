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
  int _inFlight = 0;
  SceneStats? _statsWhileVoting;
  Object? _error;
  bool _disposed = false;

  MovieDetails? get details => _details;
  bool get isLoading => _isLoading;

  /// True while at least one vote is still on its way. Nothing on this screen is
  /// disabled by it — the local write already moved the UI — but a caller may show a
  /// quiet indicator.
  bool get isVoting => _inFlight > 0;

  /// The stats to show while a vote is in flight: the previous values, not the
  /// optimistically-updated ones that will change as soon as the local write completes.
  SceneStats? get statsWhileVoting => _statsWhileVoting;

  Object? get error => _error;

  MyVote? get myVote => _details?.myVote;

  /// True once the film has been loaded in full, so the screen can tell an empty
  /// description from one that simply has not been fetched yet.
  bool get hasFullDetails => _details?.detailsFetchedAt != null;

  Future<void> load({bool force = false}) async {
    _subscription ??= _repository.watchMovie(tmdbId).listen(_onDetails);
    if (force) {
      _suppressIncomingDetails = true;
      _details = null;
      _isLoading = true;
    }
    _error = null;
    _notify();
    try {
      await _repository.refreshMovie(tmdbId, force: force);
    } on AppException catch (e) {
      // Only fatal with nothing cached. Otherwise the stream is already showing the
      // film and a failed refresh is not worth a screen.
      if (_details == null) _error = e;
    } finally {
      _suppressIncomingDetails = false;
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

  /// Fires immediately. The repository writes the vote locally before it queues the
  /// delivery, so the screen repaints on this tap rather than after the previous tap's
  /// round trip.
  Future<void> _vote({required bool hasScene, required bool? worthIt}) {
    // Remember the current stats so we can show them while the vote is in flight,
    // rather than showing the optimistically-updated ones.
    _statsWhileVoting ??= _details?.stats;
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
      if (_inFlight == 0) {
        _statsWhileVoting = null;
      }
      _notify();
    }
  }

  void _onDetails(MovieDetails? details) {
    if (_suppressIncomingDetails) return;
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
