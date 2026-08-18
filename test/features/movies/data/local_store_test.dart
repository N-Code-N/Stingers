import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/db/app_database.dart';
import 'package:stingers/features/movies/data/local_store.dart';
import 'package:stingers/features/movies/data/movie_models.dart';

void main() {
  late AppDatabase db;
  late LocalStore store;

  final at = DateTime(2026, 8, 15, 14, 32);

  Movie movie(
    int id, {
    String title = 'Film',
    String overview = '',
    String originalTitle = '',
  }) => Movie(
    tmdbId: id,
    title: title,
    posterPath: null,
    releaseDate: null,
    overview: overview,
    originalTitle: originalTitle,
  );

  SceneStats stats({double total = 4, double scene = 3}) => SceneStats(
    rawVotes: total.round(),
    totalWeight: total,
    sceneWeight: scene,
    worthWeight: 0,
    worthTotal: 0,
  );

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = LocalStore(db);
  });

  tearDown(() => db.close());

  group('feed', () {
    test('reads back a saved page in the order it was saved', () async {
      await store.saveFeedPage(
        page: 1,
        movies: [
          movie(1, title: 'A'),
          movie(2, title: 'B'),
        ],
        stats: {1: stats()},
        fetchedAt: at,
      );

      final snapshot = await store.watchFeed().first;

      expect(snapshot.items.map((i) => i.movie.title), ['A', 'B']);
      expect(snapshot.fetchedAt, at);
      expect(snapshot.loadedPages, 1);
    });

    test('preserves originalTitle when a movie is saved and read back', () async {
      const original = 'Ice Cream Man';
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1, title: 'Мороженщик', originalTitle: original)],
        stats: const {},
        fetchedAt: at,
      );

      final snapshot = await store.watchFeed().first;

      expect(snapshot.items.single.movie.originalTitle, original);
    });

    test('a film with no stats gets the zero state, not a missing row', () async {
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)],
        stats: const {},
        fetchedAt: at,
      );

      final snapshot = await store.watchFeed().first;

      expect(snapshot.items, hasLength(1));
      expect(snapshot.items.single.stats.totalWeight, 0);
      expect(snapshot.items.single.stats.hasVerdict, isFalse);
    });

    test('keeps pages in order and reports how many are loaded', () async {
      await store.saveFeedPage(
        page: 2,
        movies: [movie(3, title: 'C')],
        stats: const {},
        fetchedAt: at,
      );
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1, title: 'A')],
        stats: const {},
        fetchedAt: at,
      );

      final snapshot = await store.watchFeed().first;

      expect(snapshot.items.map((i) => i.movie.title), ['A', 'C']);
      expect(snapshot.loadedPages, 2);
    });

    test('replaces a page rather than appending to it', () async {
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1), movie(2)],
        stats: const {},
        fetchedAt: at,
      );
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)],
        stats: const {},
        fetchedAt: at,
      );

      final snapshot = await store.watchFeed().first;

      expect(snapshot.items, hasLength(1));
    });

    test('exposes the page timestamp the TTL check reads', () async {
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)],
        stats: const {},
        fetchedAt: at,
      );

      expect(await store.feedPageFetchedAt(1), at);
      expect(await store.feedPageFetchedAt(2), isNull);
    });

    test('the stream repaints when a refresh writes behind it', () async {
      final emissions = <int>[];
      final subscription = store.watchFeed().listen((s) => emissions.add(s.items.length));

      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)],
        stats: const {},
        fetchedAt: at,
      );
      await pumpEventQueue();
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1), movie(2)],
        stats: const {},
        fetchedAt: at,
      );
      await pumpEventQueue();
      await subscription.cancel();

      // No reload was called; the database drove every repaint.
      expect(emissions.last, 2);
    });
  });

  group('details', () {
    test('a list read does not wipe an overview a details read fetched', () async {
      await store.saveMovieDetails(movie(1, overview: 'A long synopsis.'), at);
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)], // list payloads carry no overview
        stats: const {},
        fetchedAt: at.add(const Duration(hours: 1)),
      );

      final details = await store.watchMovie(1).first;

      expect(details!.movie.overview, 'A long synopsis.');
      expect(details.detailsFetchedAt, at);
    });

    test('a film only ever seen in a list has no details timestamp', () async {
      await store.saveFeedPage(
        page: 1,
        movies: [movie(1)],
        stats: const {},
        fetchedAt: at,
      );

      final details = await store.watchMovie(1).first;

      expect(details!.detailsFetchedAt, isNull);
    });

    test('an unknown film streams null rather than throwing', () async {
      expect(await store.watchMovie(999).first, isNull);
    });
  });

  group('search', () {
    test('normalises the query so casing and spacing share one cache entry', () async {
      await store.saveSearch(
        query: '  Dune  ',
        movies: [movie(1, title: 'Dune')],
        stats: const {},
        fetchedAt: at,
      );

      final results = await store.watchSearch('DUNE').first;

      expect(results.single.movie.title, 'Dune');
      expect(await store.searchFetchedAt('dune'), at);
    });

    test('an unsearched query is empty, not an error', () async {
      expect(await store.watchSearch('nothing here').first, isEmpty);
      expect(await store.searchFetchedAt('nothing here'), isNull);
    });
  });

  group('votes', () {
    Future<void> cacheFilm(int id) => store.saveMovieDetails(movie(id), at);

    test('a queued vote is readable and listed as pending', () async {
      await cacheFilm(1);
      await store.saveVote(
        MyVote(
          tmdbId: 1,
          hasScene: true,
          worthIt: false,
          updatedAt: at,
          pendingSync: true,
        ),
      );

      expect((await store.readVote(1))!.pendingSync, isTrue);
      expect((await store.pendingVotes()).map((v) => v.tmdbId), [1]);
    });

    test('marking a vote synced takes it out of the queue', () async {
      await cacheFilm(1);
      await store.saveVote(
        MyVote(
          tmdbId: 1,
          hasScene: true,
          worthIt: null,
          updatedAt: at,
          pendingSync: true,
        ),
      );

      await store.markSynced(1);

      expect(await store.pendingVotes(), isEmpty);
      expect((await store.readVote(1))!.hasScene, isTrue);
    });

    test('saving the same vote twice is safe — a vote is idempotent by key', () async {
      await cacheFilm(1);
      final vote = MyVote(
        tmdbId: 1,
        hasScene: true,
        worthIt: true,
        updatedAt: at,
        pendingSync: true,
      );

      await store.saveVote(vote);
      await store.saveVote(vote);

      expect(await store.pendingVotes(), hasLength(1));
    });

    test('my votes join to the film, newest first', () async {
      await cacheFilm(1);
      await cacheFilm(2);
      await store.saveVote(
        MyVote(tmdbId: 1, hasScene: true, worthIt: null, updatedAt: at),
      );
      await store.saveVote(
        MyVote(
          tmdbId: 2,
          hasScene: false,
          worthIt: null,
          updatedAt: at.add(const Duration(minutes: 5)),
        ),
      );

      final entries = await store.watchMyVotes().first;

      expect(entries.map((e) => e.movie.tmdbId), [2, 1]);
    });

    test('a server vote never overwrites one still waiting to be sent', () async {
      await cacheFilm(1);
      await store.saveVote(
        MyVote(
          tmdbId: 1,
          hasScene: true,
          worthIt: true,
          updatedAt: at,
          pendingSync: true,
        ),
      );

      await store.mergeServerVotes([
        MyVote(
          tmdbId: 1,
          hasScene: false,
          worthIt: null,
          updatedAt: at.subtract(const Duration(days: 1)),
        ),
      ]);

      final vote = (await store.readVote(1))!;
      expect(vote.hasScene, isTrue, reason: 'the local row is newer by definition');
      expect(vote.pendingSync, isTrue);
    });

    test('a server vote fills in one cast on a previous install', () async {
      await cacheFilm(1);

      await store.mergeServerVotes([
        MyVote(tmdbId: 1, hasScene: true, worthIt: false, updatedAt: at),
      ]);

      expect((await store.readVote(1))!.hasScene, isTrue);
      expect(await store.pendingVotes(), isEmpty);
    });
  });

  group('settings', () {
    test('round-trips a value', () async {
      expect(await db.readSetting(SettingKeys.cinemaMode), isNull);
      await db.writeSetting(SettingKeys.cinemaMode, 'true');
      expect(await db.readSetting(SettingKeys.cinemaMode), 'true');
      await db.writeSetting(SettingKeys.cinemaMode, 'false');
      expect(await db.readSetting(SettingKeys.cinemaMode), 'false');
    });
  });
}
