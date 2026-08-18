import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/state/my_votes_controller.dart';

import '../../../support/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late MyVotesController controller;

  MyVoteEntry entry(int id, {bool pending = false}) => MyVoteEntry(
    movie: fakeMovie(id, 'Dune'),
    vote: MyVote(
      tmdbId: id,
      hasScene: true,
      worthIt: true,
      updatedAt: DateTime(2026, 8, 15),
      pendingSync: pending,
    ),
  );

  setUp(() {
    repository = FakeMovieRepository();
    controller = MyVotesController(repository: repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('shows the local votes and flushes anything queued', () async {
    await controller.load();
    repository.myVotes.add([entry(7)]);
    await pumpEventQueue();

    expect(controller.entries.single.movie.title, 'Dune');
    expect(controller.isLoading, isFalse);
    expect(repository.flushCalls, 1);
  });

  test('stops loading in the finally branch when reconciliation fails', () async {
    repository.refreshMyVotesFailure = const NetworkException();

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isA<NetworkException>());
  });

  test('a failed server read is invisible when local votes exist', () async {
    await controller.load();
    repository.myVotes.add([entry(7, pending: true)]);
    await pumpEventQueue();

    repository.refreshMyVotesFailure = const NetworkException();
    await controller.load();

    // These rows are the user's own and were written locally first; the server read
    // only fills in gaps, so failing it changes nothing on screen.
    expect(controller.error, isNull);
    expect(controller.entries.single.vote.pendingSync, isTrue);
  });
}
