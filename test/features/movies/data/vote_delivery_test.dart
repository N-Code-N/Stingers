import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/db/app_database.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/integrity/attestation_service.dart';
import 'package:stingers/core/integrity/install_identity.dart';
import 'package:stingers/features/movies/data/local_store.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/data/movie_repository.dart';
import 'package:stingers/features/movies/data/scene_vote_service.dart';
import 'package:stingers/features/movies/data/tmdb_service.dart';

/// A vote service whose delivery can be held open, so a test can observe what the
/// screen sees *while* a vote is still in the air.
class _SlowVotes implements SceneVoteService {
  final List<Completer<void>> gates = [];
  final List<bool> delivered = [];

  @override
  Future<String> requestChallenge({
    required int tmdbId,
    required String installId,
    required String platform,
  }) async => 'nonce-${gates.length}';

  @override
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
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    delivered.add(hasScene);
    return SceneStats.empty;
  }

  @override
  Future<Map<int, SceneStats>> statsFor(List<int> tmdbIds) async => const {};

  @override
  Future<List<MyVote>> myVotes() async => const [];
}

/// Pumps the event queue until [condition] holds, instead of pumping a fixed number of
/// times and hoping that was enough.
///
/// Between `castVote` being called and its vote actually reaching `_SlowVotes.submit`
/// sit several real awaits — two Drift reads, two Drift writes, a platform-channel round
/// trip for the install id, then the challenge and attestation calls — and none of them
/// are bounded to a fixed number of event-loop turns. A fixed `pumpEventQueue()` count
/// is exactly the kind of thing that happens to be enough on a fast machine and flakes
/// on a slower or more loaded one: this failed in CI while passing locally every time.
Future<void> _pumpUntil(FutureOr<bool> Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (await condition()) return;
    await pumpEventQueue();
  }
  fail('condition never became true');
}

class _NoTmdb implements TmdbService {
  @override
  Future<Movie> details(int tmdbId) => throw const NetworkException();
  @override
  Future<MoviesPage> nowPlaying({int page = 1}) => throw const NetworkException();
  @override
  Future<MoviesPage> search(String query, {int page = 1}) =>
      throw const NetworkException();
}

void main() {
  // `InstallIdentity` and `AttestationService` talk to a platform channel. Without a
  // binding those calls throw instead of failing over to the "no native side" path.
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalStore local;
  late _SlowVotes votes;
  late ApiMovieRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    local = LocalStore(db);
    votes = _SlowVotes();
    repository = ApiMovieRepository(
      local: local,
      tmdb: _NoTmdb(),
      votes: votes,
      identity: InstallIdentity(db: db),
      attestation: AttestationService(),
    );
    // The vote's foreign key is local only, but the details stream joins on the film.
    await local.saveMovieDetails(
      const Movie(
        tmdbId: 7,
        title: 'A film',
        posterPath: null,
        releaseDate: null,
        originalTitle: '',
      ),
      DateTime(2026, 8, 16),
    );
  });

  tearDown(() => db.close());

  test(
    'the second answer is written locally without waiting for the first to land',
    () async {
      // This is the lag that made the screen look frozen: the first vote holds the
      // network for as long as the server takes, and the second tap must not queue
      // behind it before it reaches the database the screen reads from.
      final first = repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);
      // Wait until the first vote has actually reached the network and is blocked on
      // its gate, rather than guessing how many turns its own local writes need.
      await _pumpUntil(() => votes.gates.length == 1);

      final second = repository.castVote(tmdbId: 7, hasScene: true, worthIt: true);
      // The second vote's local write must not wait on the first vote's delivery, so
      // it settles on its own while the network is still blocked on the first gate.
      await _pumpUntil(() async => (await local.readVote(7))?.worthIt == true);

      // Nothing has been delivered — both are still blocked on the gate.
      expect(votes.delivered, isEmpty);
      // But the answer is already local, so the screen has already repainted with it.
      final stored = await local.readVote(7);
      expect(stored?.worthIt, isTrue);

      votes.gates[0].complete();
      await _pumpUntil(() => votes.gates.length == 2);
      votes.gates[1].complete();
      await Future.wait([first, second]);

      expect(votes.delivered, hasLength(2));
    },
  );

  test('deliveries go out one at a time, in the order they were cast', () async {
    final first = repository.castVote(tmdbId: 7, hasScene: true, worthIt: null);
    await _pumpUntil(() => votes.gates.length == 1);
    final second = repository.castVote(tmdbId: 7, hasScene: false, worthIt: null);

    // Only the first has reached the service: the second is queued behind it, so the
    // two cannot interleave and restore each other's rollback snapshots. A fixed pump
    // here is deliberate — this assertion is itself the check that the second has
    // *not* reached the service, so waiting for a condition would defeat the point.
    await pumpEventQueue();
    expect(votes.gates, hasLength(1));

    votes.gates[0].complete();
    await _pumpUntil(() => votes.gates.length == 2);

    votes.gates[1].complete();
    await Future.wait([first, second]);

    expect(votes.delivered, [true, false]);
  });
}
