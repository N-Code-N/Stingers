import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/state/search_controller.dart';

import '../../../support/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late MovieSearchController controller;

  const debounce = Duration(milliseconds: 20);

  setUp(() {
    repository = FakeMovieRepository();
    controller = MovieSearchController(repository: repository, debounce: debounce);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  Future<void> settle() => Future.delayed(debounce * 3);

  test('collapses a burst of keystrokes into one request', () async {
    controller.input.text = 'd';
    controller.input.text = 'du';
    controller.input.text = 'dun';
    controller.input.text = 'dune';
    await settle();

    expect(repository.searches, ['dune']);
  });

  test('does not search before the pause', () async {
    controller.input.text = 'dune';

    expect(repository.searches, isEmpty);
  });

  test('submitting bypasses the debounce', () async {
    await controller.search('dune');

    expect(repository.searches, ['dune']);
  });

  test('renders results the database streams back', () async {
    await controller.search('dune');
    repository.search.add([
      MovieWithStats(movie: fakeMovie(1, 'Dune'), stats: fakeStats()),
    ]);
    await pumpEventQueue();

    expect(controller.results.single.movie.title, 'Dune');
    expect(controller.isSearching, isFalse);
  });

  test('clearing the field resets the query and the results', () async {
    await controller.search('dune');
    repository.search.add([
      MovieWithStats(movie: fakeMovie(1, 'Dune'), stats: fakeStats()),
    ]);
    await pumpEventQueue();

    controller.clear();
    await settle();

    expect(controller.hasQuery, isFalse);
    expect(controller.results, isEmpty);
    expect(controller.error, isNull);
  });

  test('an empty query never reaches the repository', () async {
    controller.input.text = '   ';
    await settle();

    expect(repository.searches, isEmpty);
  });

  test('stops searching in the finally branch when the request throws', () async {
    repository.refreshSearchFailure = const NetworkException();

    await controller.search('dune');

    expect(controller.isSearching, isFalse);
    expect(controller.error, isA<NetworkException>());
  });

  test('offline with cached results is not an error', () async {
    await controller.search('dune');
    repository.search.add([
      MovieWithStats(movie: fakeMovie(1, 'Dune'), stats: fakeStats()),
    ]);
    await pumpEventQueue();

    repository.refreshSearchFailure = const NetworkException();
    await controller.search('dune');

    expect(controller.error, isNull);
    expect(controller.results, hasLength(1));
  });

  test('a new query drops the previous results before the new ones arrive', () async {
    await controller.search('dune');
    repository.search.add([
      MovieWithStats(movie: fakeMovie(1, 'Dune'), stats: fakeStats()),
    ]);
    await pumpEventQueue();

    await controller.search('arrival');

    expect(controller.query, 'arrival');
    expect(controller.results, isEmpty);
  });
}
