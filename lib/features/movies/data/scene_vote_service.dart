import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/transport_error.dart';
import 'movie_models.dart';

/// One external system: our own Supabase project.
///
/// Reads go through PostgREST (the aggregate view, and the caller's own vote rows, which
/// RLS narrows to `auth.uid() = user_id`). The write goes through the `vote` Edge
/// Function, because there is no INSERT policy on `votes` and there is not going to be
/// one — see PROJECT_PLAN.md §6.
class SceneVoteService {
  SceneVoteService({
    required SupabaseClient supabase,
    required ApiClient api,
    Duration? timeout,
  }) : _supabase = supabase,
       _api = api,
       timeout = timeout ?? api.timeout;

  final SupabaseClient _supabase;
  final ApiClient _api;

  /// Taken from the [ApiClient] this service is given, so the two transports cannot
  /// drift apart. PostgREST goes out through the Supabase SDK rather than that client,
  /// so it inherits nothing from it — and the SDK imposes no deadline of its own. Left
  /// open, a read waits forever: in airplane mode after an online visit the DNS answer
  /// is still cached, so the connect waits for a SYN-ACK that never comes instead of
  /// being refused.
  final Duration timeout;

  /// One request for a whole page of films. The feed asks for the 20 ids it is about to
  /// render, never one request per row.
  Future<Map<int, SceneStats>> statsFor(List<int> tmdbIds) async {
    if (tmdbIds.isEmpty) return const {};
    final rows = await _guard(
      () => _supabase.from('movie_scene_stats').select().inFilter('tmdb_id', tmdbIds),
    );
    return {
      for (final row in rows) (row['tmdb_id'] as num).toInt(): SceneStats.fromJson(row),
    };
  }

  /// The caller's own votes. RLS does the filtering; there is no user id in the query,
  /// because a client-supplied one would be worth nothing anyway.
  Future<List<MyVote>> myVotes() async {
    final rows = await _guard(
      () => _supabase.from('votes').select('tmdb_id, has_scene, worth_it, updated_at'),
    );
    return rows
        .map(
          (row) => MyVote(
            tmdbId: (row['tmdb_id'] as num).toInt(),
            hasScene: row['has_scene'] as bool,
            worthIt: row['worth_it'] as bool?,
            updatedAt: DateTime.parse(row['updated_at'] as String).toLocal(),
          ),
        )
        .toList(growable: false);
  }

  /// Asks for a single-use nonce bound to this device and this film.
  ///
  /// Requested at submit time rather than when the screen opens, which also happens to
  /// be the only thing that works for a vote queued offline and flushed hours later:
  /// the nonce it needs must be minted when it is finally sent, not when it was cast.
  Future<String> requestChallenge({
    required int tmdbId,
    required String installId,
    required String platform,
  }) async {
    final json = await _api.postJson(
      '/vote/challenge',
      body: {'tmdb_id': tmdbId, 'install_id': installId, 'platform': platform},
    );
    final nonce = json['nonce'] as String?;
    if (nonce == null) throw const UnknownApiException('Challenge had no nonce');
    return nonce;
  }

  /// Casts a vote and returns the film's recomputed aggregate.
  ///
  /// `installId` and `platform` are what the server uses to resolve the device; the user
  /// id is taken from the verified JWT, never from here. The attestation verdict is sent
  /// for logging only — the server re-derives it from the token.
  Future<SceneStats> submit({
    required int tmdbId,
    required String installId,
    required String platform,
    required bool hasScene,
    required bool? worthIt,
    required String nonce,
    required String? attestationToken,
    required String? attestationVerdict,
  }) async {
    final json = await _api.postJson(
      '/vote',
      body: {
        'tmdb_id': tmdbId,
        'install_id': installId,
        'platform': platform,
        'has_scene': hasScene,
        'worth_it': worthIt,
        'nonce': nonce,
        'attestation_token': attestationToken,
        'attestation_verdict': attestationVerdict,
      },
    );
    return SceneStats.fromJson(json);
  }

  /// PostgREST speaks its own exception type and lets transport errors through raw.
  /// Nothing above this layer is allowed to know either of those exist.
  Future<List<Map<String, dynamic>>> _guard(
    Future<List<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request().timeout(timeout);
    } on PostgrestException catch (e) {
      throw switch (e.code) {
        'PGRST301' || '401' || '403' => UnauthenticatedException(e.message),
        _ => UnknownApiException(e.message),
      };
    } on TimeoutException catch (e) {
      throw NetworkException(e);
    } on http.ClientException catch (e) {
      throw NetworkException(e);
    } on Object catch (e) {
      if (isTransportFailure(e)) throw NetworkException(e);
      rethrow;
    }
  }
}
