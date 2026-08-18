import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/network/api_client.dart';

void main() {
  ApiClient clientReturning(
    http.Response Function(http.Request request) respond, {
    String? token,
    String language = 'en',
  }) => ApiClient(
    httpClient: MockClient((request) async => respond(request)),
    baseUrl: 'https://project.supabase.co/functions/v1',
    anonKey: 'anon-key',
    accessToken: () => token,
    language: () => language,
  );

  group('headers', () {
    test('sends the publishable key and the session bearer', () async {
      late http.Request seen;
      final client = clientReturning((request) {
        seen = request;
        return http.Response('{}', 200);
      }, token: 'session-token');

      await client.getJson('/tmdb/movie/now_playing');

      expect(seen.headers['apikey'], 'anon-key');
      expect(seen.headers['Authorization'], 'Bearer session-token');
      expect(seen.headers['Accept-Language'], 'en');
    });

    test('falls back to the publishable key before the session exists', () async {
      late http.Request seen;
      final client = clientReturning((request) {
        seen = request;
        return http.Response('{}', 200);
      });

      await client.getJson('/tmdb/movie/now_playing');

      // The feed has to render on a cold start with no session yet.
      expect(seen.headers['Authorization'], 'Bearer anon-key');
    });

    test('resolves the language per request, not once at construction', () async {
      var language = 'en';
      final seen = <String>[];
      final client = ApiClient(
        httpClient: MockClient((request) async {
          seen.add(request.headers['Accept-Language']!);
          return http.Response('{}', 200);
        }),
        baseUrl: 'https://project.supabase.co/functions/v1',
        anonKey: 'anon-key',
        accessToken: () => null,
        language: () => language,
      );

      await client.getJson('/tmdb/movie/now_playing');
      language = 'ru';
      await client.getJson('/tmdb/movie/now_playing');

      expect(seen, ['en', 'ru']);
    });

    test('appends query parameters', () async {
      late http.Request seen;
      final client = clientReturning((request) {
        seen = request;
        return http.Response('{}', 200);
      });

      await client.getJson('/tmdb/search/movie', query: {'query': 'дюна', 'page': '2'});

      expect(seen.url.queryParameters['query'], 'дюна');
      expect(seen.url.queryParameters['page'], '2');
    });
  });

  group('decoding', () {
    test('decodes UTF-8 even when the response omits a charset', () async {
      // `package:http` falls back to latin-1 without a charset, which silently mangles
      // every Cyrillic title. The client must decode the bytes itself.
      final client = clientReturning(
        (_) => http.Response.bytes(
          utf8.encode('{"title":"Приключения Электроника"}'),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );

      final json = await client.getJson('/tmdb/movie/1');

      expect(json['title'], 'Приключения Электроника');
    });

    test('a 200 that is not a JSON object is an error, not a crash', () async {
      final client = clientReturning((_) => http.Response('[]', 200));

      expect(() => client.getJson('/tmdb/movie/1'), throwsA(isA<UnknownApiException>()));
    });
  });

  group('error mapping', () {
    test('maps rate_limited to a vote rejection', () async {
      final client = clientReturning(
        (_) => http.Response('{"error_type":"rate_limited","error":"Too many"}', 429),
      );

      expect(() => client.postJson('/vote'), throwsA(isA<VoteRejectedException>()));
    });

    test('maps unauthenticated', () async {
      final client = clientReturning(
        (_) => http.Response('{"error_type":"unauthenticated","error":"no"}', 401),
      );

      expect(() => client.postJson('/vote'), throwsA(isA<UnauthenticatedException>()));
    });

    test('maps upstream_unavailable', () async {
      final client = clientReturning(
        (_) => http.Response('{"error_type":"upstream_unavailable","error":"tmdb"}', 502),
      );

      expect(
        () => client.getJson('/tmdb/movie/1'),
        throwsA(isA<UpstreamUnavailableException>()),
      );
    });

    test('an unknown error_type falls through instead of throwing while parsing', () {
      final ex = parseApiError(
        statusCode: 400,
        errorType: 'brand_new_type',
        message: 'something',
      );
      expect(ex, isA<UnknownApiException>());
    });

    test('a body that is not our envelope still maps by status code', () async {
      // A gateway, a proxy or an outage can answer with HTML.
      final client = clientReturning(
        (_) => http.Response('<html>504 Gateway Timeout</html>', 504),
      );

      expect(
        () => client.getJson('/tmdb/movie/1'),
        throwsA(isA<UpstreamUnavailableException>()),
      );
    });

    test('a transport failure becomes a NetworkException, never a raw one', () async {
      final client = ApiClient(
        httpClient: MockClient((_) async => throw http.ClientException('no route')),
        baseUrl: 'https://project.supabase.co/functions/v1',
        anonKey: 'anon-key',
        accessToken: () => null,
        language: () => 'en',
      );

      expect(
        () => client.getJson('/tmdb/movie/now_playing'),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
