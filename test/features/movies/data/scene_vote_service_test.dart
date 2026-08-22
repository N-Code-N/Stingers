import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/network/api_client.dart';
import 'package:stingers/features/movies/data/scene_vote_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A transport that accepts the request and then says nothing, ever.
///
/// This is airplane mode *after* an online visit: the DNS answer is still cached, so
/// there is a route to try and the connect waits for a SYN-ACK that no longer comes,
/// rather than being refused outright the way an unresolvable host is.
class _SilentClient extends http.BaseClient {
  final _never = Completer<http.StreamedResponse>();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => _never.future;
}

void main() {
  SceneVoteService service({required http.Client transport}) => SceneVoteService(
    supabase: SupabaseClient('http://localhost:54321', 'anon-key', httpClient: transport),
    api: ApiClient(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      baseUrl: 'https://project.supabase.co/functions/v1',
      anonKey: 'anon-key',
      accessToken: () => null,
      language: () => 'en',
    ),
    timeout: const Duration(milliseconds: 50),
  );

  test('an aggregate read that never answers gives up instead of hanging', () async {
    // PostgREST reads bypass ApiClient, so they never inherited its 15s ceiling. Without
    // one of their own the read waits forever, and every caller waiting on it — the
    // details refresh joins this with the TMDb request under `Future.wait` — waits too.
    await expectLater(
      service(transport: _SilentClient()).statsFor([7]),
      throwsA(isA<NetworkException>()),
    );
  });

  test('the caller-s own votes read gives up too', () async {
    await expectLater(
      service(transport: _SilentClient()).myVotes(),
      throwsA(isA<NetworkException>()),
    );
  });
}
