import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/features/movies/state/now_playing_controller.dart';

import '../../../support/fake_movie_repository.dart';

void main() {
  late FakeMovieRepository repository;
  late NowPlayingController controller;

  setUp(() {
    repository = FakeMovieRepository();
    controller = NowPlayingController(repository: repository);
  });

  tearDown(() async {
    controller.dispose();
    await repository.close();
  });

  test('starts loading and stops once the refresh returns', () async {
    expect(controller.isLoading, isTrue);

    await controller.load();

    expect(controller.isLoading, isFalse);
    expect(controller.error, isNull);
  });

  test('stops loading in the finally branch even when the refresh throws', () async {
    repository.refreshFeedFailure = const NetworkException();

    await controller.load();

    // A spinner that never turns off is the classic version of this bug.
    expect(controller.isLoading, isFalse);
    expect(controller.error, isA<NetworkException>());
  });

  test('offline with a cache is a staleness banner, not an error screen', () async {
    repository.refreshFeedFailure = const NetworkException();
    await controller.load();

    repository.feed.add(fakeFeed([fakeMovie(1)], fetchedAt: DateTime(2026, 8, 15, 14)));
    await pumpEventQueue();
    await controller.refresh();

    expect(controller.error, isNull);
    expect(controller.isStale, isTrue);
    expect(controller.items, hasLength(1));
  });

  test('a later database write repaints without another load call', () async {
    await controller.load();

    repository.feed.add(fakeFeed([fakeMovie(1), fakeMovie(2)]));
    await pumpEventQueue();

    expect(controller.items, hasLength(2));
    expect(controller.isLoading, isFalse);
  });

  test('a successful refresh clears a previous error', () async {
    repository.refreshFeedFailure = const NetworkException();
    await controller.load();
    expect(controller.error, isNotNull);

    repository.refreshFeedFailure = null;
    await controller.refresh();

    expect(controller.error, isNull);
  });

  test('loading more asks for the next page', () async {
    await controller.load();
    repository.feed.add(fakeFeed([fakeMovie(1)]));
    await pumpEventQueue();

    await controller.loadMore();

    expect(repository.refreshFeedCalls, 2);
  });

  test('does not load more before the first page has arrived', () async {
    await controller.load();

    await controller.loadMore();

    expect(repository.refreshFeedCalls, 1);
  });

  test('stops paging once TMDb says there is no next page', () async {
    repository.feedHasMore = false;
    await controller.load();
    repository.feed.add(fakeFeed([fakeMovie(1)]));
    await pumpEventQueue();

    await controller.loadMore();

    expect(controller.hasMore, isFalse);
    expect(repository.refreshFeedCalls, 1);
  });

  test('a failed page load leaves the list alone', () async {
    await controller.load();
    repository.feed.add(fakeFeed([fakeMovie(1)]));
    await pumpEventQueue();
    repository.refreshFeedFailure = const NetworkException();

    await controller.loadMore();

    expect(controller.items, hasLength(1));
    expect(controller.error, isNull);
    expect(controller.isLoadingMore, isFalse);
  });
}
