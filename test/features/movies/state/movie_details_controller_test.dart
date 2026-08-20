import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/data/movie_repository.dart';
import 'package:stingers/features/movies/state/movie_details_controller.dart';

import '../../../support/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late MovieDetailsController controller;
  late List<Object> errors;
  late int queuedNotices;

  MovieDetails details({MyVote? vote, SceneStats? stats}) => MovieDetails(
    movie: fakeMovie(7, 'Dune'),
    stats: stats ?? SceneStats.empty,
    myVote: vote,
    detailsFetchedAt: DateTime(2026, 8, 15),
  );

  setUp(() {
    repository = FakeMovieRepository();
    errors = [];
    queuedNotices = 0;
    controller = MovieDetailsController(
      repository: repository,
      tmdbId: 7,
      showError: errors.add,
      showQueued: () => queuedNotices++,
    );
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('renders the film once the database emits it', () async {
    await controller.load();
    repository.movie.add(details());
    await pumpEventQueue();

    expect(controller.details!.movie.title, 'Dune');
    expect(controller.isLoading, isFalse);
    expect(controller.hasFullDetails, isTrue);
  });

  test('a failure with nothing cached blocks the screen', () async {
    repository.refreshMovieFailure = const NetworkException();

    await controller.load();

    expect(controller.error, isA<NetworkException>());
    expect(controller.isLoading, isFalse);
  });

  test('a failure with something cached does not block the screen', () async {
    await controller.load(); // subscribes to the database stream
    repository.movie.add(details());
    await pumpEventQueue();
    repository.refreshMovieFailure = const NetworkException();

    await controller.load();

    expect(controller.error, isNull);
    expect(controller.details, isNotNull);
  });

  test('voting yes sends the answer through', () async {
    await controller.load();

    await controller.setHasScene(true);

    expect(repository.castVotes.single.hasScene, isTrue);
    expect(repository.castVotes.single.worthIt, isNull);
    expect(errors, isEmpty);
  });

  test('answering the second question keeps the first', () async {
    await controller.load();
    repository.movie.add(
      details(
        vote: MyVote(tmdbId: 7, hasScene: true, worthIt: null, updatedAt: DateTime(2026)),
      ),
    );
    await pumpEventQueue();

    await controller.setWorthIt(true);

    expect(repository.castVotes.single.hasScene, isTrue);
    expect(repository.castVotes.single.worthIt, isTrue);
  });

  test('switching to "no scene" drops the previous worth-it answer', () async {
    await controller.load();
    repository.movie.add(
      details(
        vote: MyVote(tmdbId: 7, hasScene: true, worthIt: true, updatedAt: DateTime(2026)),
      ),
    );
    await pumpEventQueue();

    await controller.setHasScene(false);

    expect(repository.castVotes.single.worthIt, isNull);
  });

  test('a queued vote is reported as queued, not as a failure', () async {
    repository.castVoteOutcome = VoteOutcome.queued;
    await controller.load();

    await controller.setHasScene(true);

    expect(queuedNotices, 1);
    expect(errors, isEmpty);
  });

  test('the verdict moves on the tap and then stays put for this visit', () async {
    await controller.load();
    repository.movie.add(details(stats: fakeStats(total: 4, scene: 3)));
    await pumpEventQueue();
    expect(controller.displayStats.sceneWeight, 3);

    // The tap itself, before anything has reached the network.
    final pending = controller.setHasScene(true);
    expect(controller.displayStats.totalWeight, 5);
    expect(controller.displayStats.sceneWeight, 4);
    await pending;

    // The server's real, trust-weighted recount lands in the database. It is the right
    // number for the next visit to this film, and it must not move the verdict under the
    // reader who answered a moment ago.
    repository.movie.add(details(stats: fakeStats(total: 40, scene: 4)));
    await pumpEventQueue();
    expect(controller.displayStats.totalWeight, 5);
    expect(controller.displayStats.sceneWeight, 4);
  });

  test('a rejected vote goes to the snackbar, not the error field', () async {
    await controller.load();
    repository.castVoteFailure = const VoteRejectedException('rate limited');
    repository.movie.add(details());
    await pumpEventQueue();

    await controller.setHasScene(true);

    // The film must stay on screen; only one action failed.
    expect(errors.single, isA<VoteRejectedException>());
    expect(controller.error, isNull);
    expect(controller.details, isNotNull);
    expect(controller.isVoting, isFalse);
  });

  test('the voting flag clears in the finally branch', () async {
    repository.castVoteFailure = const NetworkException();
    await controller.load();

    await controller.setHasScene(true);

    expect(controller.isVoting, isFalse);
  });

  test('disposing while a vote is still in flight does not throw', () async {
    // Leaving the details screen right after a tap disposes this controller before the
    // repository's Future resolves; the pending `_send` must not call notifyListeners
    // on its way out.
    final scoped = MovieDetailsController(
      repository: repository,
      tmdbId: 7,
      showError: errors.add,
      showQueued: () => queuedNotices++,
    );
    await scoped.load();

    final vote = scoped.setHasScene(true);
    scoped.dispose();

    await expectLater(vote, completes);
  });

  test('queues a second tap behind the first instead of dropping it', () async {
    // Answering both questions in quick succession is the normal way to use this
    // screen, and the second tap lands while the first is still two round trips from
    // the server. Dropping it would silently lose the answer the user gave last.
    await controller.load();

    await Future.wait([controller.setHasScene(true), controller.setHasScene(false)]);

    expect(repository.castVotes, hasLength(2));
    expect(repository.castVotes.map((v) => v.hasScene), [true, false]);
  });
}
