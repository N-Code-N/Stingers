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
/// Only three things live at this level, and each because more than one consumer needs
/// the *same* instance: the session (read by the API client on every request), the
/// locale controller (read by `MaterialApp` and by every outgoing request), and cinema
/// mode (read by `MaterialApp` for the theme, written by the movie screen). Screen state
/// stays owned by its screen.
class AppDependencies {
  AppDependencies._({
    required this.database,
    required this.apiClient,
    required this.session,
    required this.locale,
    required this.cinemaMode,
    required this.movieRepository,
    required this.voteSync,
  });

  final AppDatabase database;
  final ApiClient apiClient;
  final AnonSession session;
  final AppLocaleController locale;
  final CinemaMode cinemaMode;
  final MovieRepository movieRepository;
  final PendingVoteSync voteSync;

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

    final voteSync = PendingVoteSync(repository: repository, session: session)..start();

    return AppDependencies._(
      database: database,
      apiClient: apiClient,
      session: session,
      locale: locale,
      cinemaMode: cinemaMode,
      movieRepository: repository,
      voteSync: voteSync,
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
