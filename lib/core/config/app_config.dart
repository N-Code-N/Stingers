/// Build-time configuration. Everything here arrives through `--dart-define`; nothing
/// is hardcoded per machine and nothing secret is present.
///
/// The Supabase anon key is publishable by design — it is the only key the binary
/// carries. The TMDb token lives in the `tmdb` Edge Function's secrets, because Dart
/// string constants survive AOT compilation and fall straight out of `libapp.so`.
abstract final class AppConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// False when the app was launched without the two defines. Startup degrades to an
  /// honest "not configured" state instead of crashing inside the Supabase SDK.
  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get functionsBaseUrl => '$supabaseUrl/functions/v1';

  /// TMDb's `now_playing?region=RU` has been incomplete since 2022, so the feed is
  /// global/US. Changing this changes which films the feed shows, nothing else.
  static const String feedRegion = 'US';

  static const String posterBaseUrl = 'https://image.tmdb.org/t/p';

  /// Poster width for feed rows. TMDb serves fixed buckets; `w342` is the smallest one
  /// that still looks right at list size on a 3x screen.
  static const String posterListSize = 'w342';
  static const String posterDetailSize = 'w500';

  static String? posterUrl(String? path, {String size = posterListSize}) =>
      path == null || path.isEmpty ? null : '$posterBaseUrl/$size$path';
}
