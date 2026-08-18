import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/session/anon_session.dart';
import 'movie_repository.dart';

/// Re-establishes the session and flushes queued votes when the app comes back to the
/// foreground.
///
/// Together with the flush at the end of a successful feed refresh, this is the whole
/// "it sends itself" story: the user turns their connection back on, returns to the app,
/// and the vote leaves without them touching anything.
///
/// The session comes first, and it is the reason this is not just a flush: signing in
/// happens once at startup, and if there was no network then there was no session. Only
/// retrying the votes would retry them forever against a request that cannot be
/// authenticated.
///
/// Deliberately not driven by `connectivity_plus`: that reports a link, not the
/// internet. Attempting the request and falling back is more honest than asking.
class PendingVoteSync with WidgetsBindingObserver {
  PendingVoteSync({required MovieRepository repository, required AnonSession session})
    : _repository = repository,
      _session = session;

  final MovieRepository _repository;
  final AnonSession _session;

  void start() => WidgetsBinding.instance.addObserver(this);

  void stop() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Fire and forget: nothing on screen is waiting for this, and a failure just means
    // the votes stay queued for the next attempt.
    unawaited(_resume());
  }

  Future<void> _resume() async {
    try {
      // A no-op when a session already exists, which is the usual case.
      await _session.ensure();
      await _repository.flushPendingVotes();
    } catch (e) {
      debugPrint('resume sync failed: $e');
    }
  }
}
