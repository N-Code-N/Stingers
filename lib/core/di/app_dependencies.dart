import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/movies/data/local_store.dart';
import '../../features/movies/data/movie_repository.dart';
import '../../features/movies/data/pending_vote_sync.dart';
import '../../features/movies/data/scene_vote_service.dart';
import '../../features/movies/data/tmdb_service.dart';
import '../config/app_config.dart';
import '../db/app_database.dart';
import '../integrity/attestation_service.dart';
import '../integrity/install_identity.dart';
import '../l10n/app_locale_controller.dart';
import '../network/api_client.dart';
import '../session/anon_session.dart';
import '../theme/cinema_mode.dart';

/// The composition root. Everything is constructed once, here, and injected downwards —
/// there is no service locator and nothing reaches for a global.
///
/// A field earns its place here only by being *read* after `bootstrap` returns: the
/// session (by [startSession]), the locale controller and cinema mode (by `MaterialApp`,
/// and the locale by every outgoing request), and the repository (by every screen).
/// Screen state stays owned by its screen.
///
/// Everything else the graph needs is reachable from the object that uses it and is not
/// mirrored here. Holding a second reference for its own sake buys nothing: nothing in
/// the graph is kept alive by this object — `PendingVoteSync` by the observer list it
/// registers itself in, the database and API client by the repository chain that closes
/// over them — and there is no shutdown path to hand them to. When one appears it can
/// bring the handles it needs back with it.
class AppDependencies {
  AppDependencies._({
    required this.session,
    required this.locale,
    required this.cinemaMode,
    required this.movieRepository,
  });

  final AnonSession session;
  final AppLocaleController locale;
  final CinemaMode cinemaMode;
  final MovieRepository movieRepository;

  /// Builds the graph. `supabase` and `httpClient` are parameters rather than globals so
  /// an integration test can hand in fakes without touching platform channels.
  static Future<AppDependencies> bootstrap({
    required SupabaseClient supabase,
    required AppDatabase database,
    http.Client? httpClient,
  }) async {
    final client = httpClient ?? http.Client();
    final locale = AppLocaleController();
    final session = AnonSession(auth: supabase.auth);

    final apiClient = ApiClient(
      httpClient: client,
      baseUrl: AppConfig.functionsBaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      accessToken: () => session.accessToken,
      language: () => locale.languageCode,
    );

    final localStore = LocalStore(database);
    final identity = InstallIdentity(db: database);
    final repository = ApiMovieRepository(
      local: localStore,
      tmdb: TmdbService(api: apiClient, language: () => locale.tmdbLanguage),
      votes: SceneVoteService(supabase: supabase, api: apiClient),
      identity: identity,
      attestation: AttestationService(),
    );

    // Resolved up front rather than on the vote path, where it would add a
    // platform-channel round trip plus a database read to the first tap. Not awaited —
    // nothing before that first vote needs it.
    unawaited(identity.installId());

    final cinemaMode = CinemaMode(
      initialEnabled: await database.readSetting(SettingKeys.cinemaMode) == 'true',
      persist: (enabled) => database.writeSetting(SettingKeys.cinemaMode, '$enabled'),
    );

    // Not held onto: `start()` registers it with `WidgetsBinding`, which is what keeps it
    // alive and what would have to hand it back for a `stop()` this app never calls.
    PendingVoteSync(repository: repository, session: session).start();

    return AppDependencies._(
      session: session,
      locale: locale,
      cinemaMode: cinemaMode,
      movieRepository: repository,
    );
  }

  /// Signing in cannot be allowed to block startup. With no session the app still opens
  /// and still shows everything already in the local database — it just cannot vote
  /// until the next attempt succeeds.
  Future<void> startSession() async {
    try {
      await session.ensure();
    } catch (e) {
      debugPrint('anonymous session unavailable at startup: $e');
    }
  }
}
