import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'movie_models.dart';

/// One external system: the local Drift database.
///
/// This is the app's **read source of truth**. Screens subscribe to the streams here, so
/// a background refresh repaints the list without anyone calling reload, and losing the
/// network makes the screen quieter rather than broken.
class LocalStore {
  LocalStore(this._db);

  final AppDatabase _db;

  /// Normalising the key here means "Dune", " dune " and "DUNE" share one cache entry.
  static String normaliseQuery(String query) => query.trim().toLowerCase();

  // --- feed ----------------------------------------------------------------

  Stream<FeedSnapshot> watchFeed() {
    final query =
        _db.select(_db.feedEntries).join([
          innerJoin(
            _db.cachedMovies,
            _db.cachedMovies.tmdbId.equalsExp(_db.feedEntries.tmdbId),
          ),
          leftOuterJoin(
            _db.cachedStats,
            _db.cachedStats.tmdbId.equalsExp(_db.feedEntries.tmdbId),
          ),
        ])..orderBy([
          OrderingTerm.asc(_db.feedEntries.page),
          OrderingTerm.asc(_db.feedEntries.position),
        ]);

    return query.watch().map((rows) {
      if (rows.isEmpty) return FeedSnapshot.empty;

      final items = <MovieWithStats>[];
      DateTime? oldest;
      var pages = 0;

      for (final row in rows) {
        final entry = row.readTable(_db.feedEntries);
        items.add(
          MovieWithStats(
            movie: _movieFrom(row.readTable(_db.cachedMovies)),
            stats: _statsFrom(row.readTableOrNull(_db.cachedStats)),
          ),
        );
        if (oldest == null || entry.fetchedAt.isBefore(oldest)) oldest = entry.fetchedAt;
        if (entry.page > pages) pages = entry.page;
      }

      return FeedSnapshot(items: items, fetchedAt: oldest, loadedPages: pages);
    });
  }

  /// Replaces one page rather than appending, so a film that dropped out of the TMDb
  /// page disappears here too instead of lingering forever.
  Future<void> saveFeedPage({
    required int page,
    required List<Movie> movies,
    required Map<int, SceneStats> stats,
    required DateTime fetchedAt,
  }) => _db.transaction(() async {
    await _upsertMovies(movies, fetchedAt);
    await _upsertStats(stats, fetchedAt);
    await (_db.delete(_db.feedEntries)..where((t) => t.page.equals(page))).go();
    await _db.batch((batch) {
      batch.insertAll(_db.feedEntries, [
        for (var i = 0; i < movies.length; i++)
          FeedEntriesCompanion.insert(
            page: page,
            position: i,
            tmdbId: movies[i].tmdbId,
            fetchedAt: fetchedAt,
          ),
      ]);
    });
  });

  Future<DateTime?> feedPageFetchedAt(int page) async {
    final row =
        await (_db.select(_db.feedEntries)
              ..where((t) => t.page.equals(page))
              ..limit(1))
            .getSingleOrNull();
    return row?.fetchedAt;
  }

  // --- one film ------------------------------------------------------------

  Stream<MovieDetails?> watchMovie(int tmdbId) {
    final query = _db.select(_db.cachedMovies).join([
      leftOuterJoin(
        _db.cachedStats,
        _db.cachedStats.tmdbId.equalsExp(_db.cachedMovies.tmdbId),
      ),
      leftOuterJoin(
        _db.localVotes,
        _db.localVotes.tmdbId.equalsExp(_db.cachedMovies.tmdbId),
      ),
    ])..where(_db.cachedMovies.tmdbId.equals(tmdbId));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      final movie = row.readTable(_db.cachedMovies);
      return MovieDetails(
        movie: _movieFrom(movie),
        stats: _statsFrom(row.readTableOrNull(_db.cachedStats)),
        myVote: _voteFrom(row.readTableOrNull(_db.localVotes)),
        detailsFetchedAt: movie.detailsFetchedAt,
      );
    });
  }

  Future<void> saveMovieDetails(Movie movie, DateTime fetchedAt) => _db
      .into(_db.cachedMovies)
      .insertOnConflictUpdate(
        CachedMoviesCompanion.insert(
          tmdbId: Value(movie.tmdbId),
          title: movie.title,
          originalTitle: Value(movie.originalTitle),
          posterPath: Value(movie.posterPath),
          releaseDate: Value(movie.releaseDate),
          overview: Value(movie.overview),
          fetchedAt: fetchedAt,
          detailsFetchedAt: Value(fetchedAt),
        ),
      );

  Future<void> saveStats(Map<int, SceneStats> stats, DateTime fetchedAt) =>
      _upsertStats(stats, fetchedAt);

  Future<DateTime?> detailsFetchedAt(int tmdbId) async {
    final row = await (_db.select(
      _db.cachedMovies,
    )..where((t) => t.tmdbId.equals(tmdbId))).getSingleOrNull();
    return row?.detailsFetchedAt;
  }

  Future<SceneStats> readStats(int tmdbId) async {
    final row = await (_db.select(
      _db.cachedStats,
    )..where((t) => t.tmdbId.equals(tmdbId))).getSingleOrNull();
    return _statsFrom(row);
  }

  Future<DateTime?> statsFetchedAt(int tmdbId) async {
    final row = await (_db.select(
      _db.cachedStats,
    )..where((t) => t.tmdbId.equals(tmdbId))).getSingleOrNull();
    return row?.fetchedAt;
  }

  // --- search --------------------------------------------------------------

  Stream<List<MovieWithStats>> watchSearch(String query) {
    final key = normaliseQuery(query);
    final select =
        _db.select(_db.searchEntries).join([
            innerJoin(
              _db.cachedMovies,
              _db.cachedMovies.tmdbId.equalsExp(_db.searchEntries.tmdbId),
            ),
            leftOuterJoin(
              _db.cachedStats,
              _db.cachedStats.tmdbId.equalsExp(_db.searchEntries.tmdbId),
            ),
          ])
          ..where(_db.searchEntries.query.equals(key))
          ..orderBy([OrderingTerm.asc(_db.searchEntries.position)]);

    return select.watch().map(
      (rows) => rows
          .map(
            (row) => MovieWithStats(
              movie: _movieFrom(row.readTable(_db.cachedMovies)),
              stats: _statsFrom(row.readTableOrNull(_db.cachedStats)),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> saveSearch({
    required String query,
    required List<Movie> movies,
    required Map<int, SceneStats> stats,
    required DateTime fetchedAt,
  }) {
    final key = normaliseQuery(query);
    return _db.transaction(() async {
      await _upsertMovies(movies, fetchedAt);
      await _upsertStats(stats, fetchedAt);
      await (_db.delete(_db.searchEntries)..where((t) => t.query.equals(key))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.searchEntries, [
          for (var i = 0; i < movies.length; i++)
            SearchEntriesCompanion.insert(
              query: key,
              position: i,
              tmdbId: movies[i].tmdbId,
              fetchedAt: fetchedAt,
            ),
        ]);
      });
    });
  }

  Future<DateTime?> searchFetchedAt(String query) async {
    final row =
        await (_db.select(_db.searchEntries)
              ..where((t) => t.query.equals(normaliseQuery(query)))
              ..limit(1))
            .getSingleOrNull();
    return row?.fetchedAt;
  }

  // --- votes ---------------------------------------------------------------

  Stream<List<MyVoteEntry>> watchMyVotes() {
    final query = _db.select(_db.localVotes).join([
      innerJoin(
        _db.cachedMovies,
        _db.cachedMovies.tmdbId.equalsExp(_db.localVotes.tmdbId),
      ),
    ])..orderBy([OrderingTerm.desc(_db.localVotes.updatedAt)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => MyVoteEntry(
              movie: _movieFrom(row.readTable(_db.cachedMovies)),
              vote: _voteFrom(row.readTable(_db.localVotes))!,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<MyVote?> readVote(int tmdbId) async {
    final row = await (_db.select(
      _db.localVotes,
    )..where((t) => t.tmdbId.equals(tmdbId))).getSingleOrNull();
    return _voteFrom(row);
  }

  Future<void> saveVote(MyVote vote) => _db
      .into(_db.localVotes)
      .insertOnConflictUpdate(
        LocalVotesCompanion.insert(
          tmdbId: Value(vote.tmdbId),
          hasScene: vote.hasScene,
          worthIt: Value(vote.worthIt),
          updatedAt: vote.updatedAt,
          pendingSync: Value(vote.pendingSync),
        ),
      );

  Future<void> deleteVote(int tmdbId) =>
      (_db.delete(_db.localVotes)..where((t) => t.tmdbId.equals(tmdbId))).go();

  Future<List<MyVote>> pendingVotes() async {
    final rows = await (_db.select(
      _db.localVotes,
    )..where((t) => t.pendingSync.equals(true))).get();
    return rows.map((row) => _voteFrom(row)!).toList(growable: false);
  }

  Future<void> markSynced(int tmdbId) =>
      (_db.update(_db.localVotes)..where((t) => t.tmdbId.equals(tmdbId))).write(
        const LocalVotesCompanion(pendingSync: Value(false)),
      );

  /// Reconciles with the server's copy of the user's votes, leaving anything still
  /// queued alone — the local row is newer than what the server has by definition.
  Future<void> mergeServerVotes(List<MyVote> votes) => _db.transaction(() async {
    final pending = (await pendingVotes()).map((v) => v.tmdbId).toSet();
    for (final vote in votes) {
      if (pending.contains(vote.tmdbId)) continue;
      await saveVote(vote);
    }
  });

  // --- shared --------------------------------------------------------------

  /// Deliberately does not carry `overview` or `detailsFetchedAt`: a list read has
  /// neither, and an absent companion field is left untouched by the upsert, so
  /// scrolling the feed cannot wipe a description the details screen already fetched.
  Future<void> _upsertMovies(List<Movie> movies, DateTime fetchedAt) =>
      _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.cachedMovies, [
          for (final movie in movies)
            CachedMoviesCompanion.insert(
              tmdbId: Value(movie.tmdbId),
              title: movie.title,
              originalTitle: Value(movie.originalTitle),
              posterPath: Value(movie.posterPath),
              releaseDate: Value(movie.releaseDate),
              fetchedAt: fetchedAt,
            ),
        ]);
      });

  Future<void> _upsertStats(Map<int, SceneStats> stats, DateTime fetchedAt) =>
      _db.batch((batch) {
        batch.insertAllOnConflictUpdate(_db.cachedStats, [
          for (final entry in stats.entries)
            CachedStatsCompanion.insert(
              tmdbId: Value(entry.key),
              rawVotes: Value(entry.value.rawVotes),
              totalWeight: Value(entry.value.totalWeight),
              sceneWeight: Value(entry.value.sceneWeight),
              worthWeight: Value(entry.value.worthWeight),
              worthTotal: Value(entry.value.worthTotal),
              fetchedAt: fetchedAt,
            ),
        ]);
      });

  static Movie _movieFrom(CachedMovie row) => Movie(
    tmdbId: row.tmdbId,
    title: row.title,
    originalTitle: row.originalTitle,
    posterPath: row.posterPath,
    releaseDate: row.releaseDate,
    overview: row.overview,
  );

  static SceneStats _statsFrom(CachedStat? row) => row == null
      ? SceneStats.empty
      : SceneStats(
          rawVotes: row.rawVotes,
          totalWeight: row.totalWeight,
          sceneWeight: row.sceneWeight,
          worthWeight: row.worthWeight,
          worthTotal: row.worthTotal,
        );

  static MyVote? _voteFrom(LocalVote? row) => row == null
      ? null
      : MyVote(
          tmdbId: row.tmdbId,
          hasScene: row.hasScene,
          worthIt: row.worthIt,
          updatedAt: row.updatedAt,
          pendingSync: row.pendingSync,
        );
}
