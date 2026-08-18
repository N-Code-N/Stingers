import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../errors/app_exceptions.dart';
import 'transport_error.dart';

/// The current session's access token, or null before the anonymous session lands.
typedef AccessTokenProvider = String? Function();

/// The UI language, resolved per request so changing it in Settings changes
/// server-resolved content too, with no restart.
typedef LanguageProvider = String Function();

/// The one place that talks HTTP. Everything above it deals in typed exceptions.
///
/// Both Edge Functions sit behind the same base URL and speak the same error envelope,
/// so there is one client, injected, and no layer above ever constructs a request.
class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required String baseUrl,
    required String anonKey,
    required AccessTokenProvider accessToken,
    required LanguageProvider language,
    this.timeout = const Duration(seconds: 15),
  }) : _http = httpClient,
       _baseUrl = baseUrl,
       _anonKey = anonKey,
       _accessToken = accessToken,
       _language = language;

  final http.Client _http;
  final String _baseUrl;
  final String _anonKey;
  final AccessTokenProvider _accessToken;
  final LanguageProvider _language;
  final Duration timeout;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
  }) => _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) => _send(
    () => _http.post(
      _uri(path, const {}),
      headers: {..._headers(), 'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    ),
  );

  Uri _uri(String path, Map<String, String> query) {
    final uri = Uri.parse('$_baseUrl$path');
    return query.isEmpty ? uri : uri.replace(queryParameters: query);
  }

  Map<String, String> _headers() => {
    // Supabase wants the publishable key on every call regardless of the session; the
    // bearer is the user's token once the anonymous session exists.
    'apikey': _anonKey,
    'Authorization': 'Bearer ${_accessToken() ?? _anonKey}',
    'Accept': 'application/json',
    'Accept-Language': _language(),
  };

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(timeout);
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    } on Object catch (e) {
      // Anything the platform recognises as a transport failure; everything else is a
      // bug and must keep its own type rather than be disguised as "no connection".
      if (isTransportFailure(e)) throw NetworkException(e);
      rethrow;
    }

    // `package:http` falls back to latin-1 when a response omits its charset, which
    // silently mangles every non-ASCII title. Decode the bytes ourselves.
    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    final decoded = _decodeObject(text);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded == null) {
        throw UnknownApiException('Expected a JSON object, got: ${_clip(text)}');
      }
      return decoded;
    }

    throw parseApiError(
      statusCode: response.statusCode,
      errorType: decoded?['error_type'] as String?,
      message: decoded?['error'] as String? ?? _clip(text),
    );
  }

  /// Returns null rather than throwing: an unparseable body is a failure to report,
  /// not a crash while reporting one.
  Map<String, dynamic>? _decodeObject(String text) {
    if (text.isEmpty) return null;
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static String _clip(String text) =>
      text.length <= 200 ? text : '${text.substring(0, 200)}…';
}
