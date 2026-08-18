import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import 'movie_models.dart';

/// One external system: TMDb, reached only through the `tmdb` Edge Function.
///
/// The function passes TMDb's envelope through unchanged, so these methods parse TMDb's
/// shape directly. It also holds the API token, which is why the client never sees one.
class TmdbService {
  TmdbService({required ApiClient api, required LanguageProvider language})
    : _api = api,
      _language = language;

  final ApiClient _api;
  final LanguageProvider _language;

  Future<MoviesPage> nowPlaying({int page = 1}) async {
    final json = await _api.getJson(
      '/tmdb/movie/now_playing',
      query: {
        'page': '$page',
        // TMDb's `now_playing?region=RU` has been incomplete since 2022; the feed is
        // global so it is never empty.
        'region': AppConfig.feedRegion,
        'language': _language(),
      },
    );
    return MoviesPage.fromJson(json);
  }

  Future<Movie> details(int tmdbId) async {
    final json = await _api.getJson(
      '/tmdb/movie/$tmdbId',
      query: {'language': _language()},
    );
    return Movie.fromJson(json);
  }

  Future<MoviesPage> search(String query, {int page = 1}) async {
    final json = await _api.getJson(
      '/tmdb/search/movie',
      query: {
        'query': query,
        'page': '$page',
        'language': _language(),
        'include_adult': 'false',
      },
    );
    return MoviesPage.fromJson(json);
  }
}
