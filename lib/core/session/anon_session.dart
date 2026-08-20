import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_exceptions.dart';

/// The app's identity, such as it is.
///
/// There is no login screen: an account between a person and their vote costs more
/// votes than it saves. The anonymous session exists only to give the `vote` function a
/// verified `auth.uid()` and to let someone see their own votes back. It is emphatically
/// *not* an anti-abuse control — anonymous sign-up is a public endpoint, which is why
/// votes are counted per device and weighted (see PROJECT_PLAN.md §6).
///
/// One of the two composition-root singletons: the API client reads the access token
/// from it on every request, and the vote path needs the same user id.
class AnonSession extends ChangeNotifier {
  AnonSession({required GoTrueClient auth}) : _auth = auth {
    _subscription = _auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  final GoTrueClient _auth;
  late final StreamSubscription<AuthState> _subscription;

  String? get accessToken => _auth.currentSession?.accessToken;
  bool get hasSession => _auth.currentSession != null;

  /// Signs in anonymously unless a session was restored from storage. Safe to call more
  /// than once — a restored session is left alone, so a restart does not mint a second
  /// user and orphan the first one's votes.
  Future<void> ensure() async {
    if (hasSession) return;
    try {
      await _auth.signInAnonymously();
    } on AuthRetryableFetchException catch (e) {
      throw NetworkException(e);
    } on AuthException catch (e) {
      throw UnauthenticatedException(e.message);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
