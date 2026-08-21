import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Film metadata as last seen from TMDb.
///
/// `fetchedAt` is set by a list read (feed or search, which carry no overview);
/// `detailsFetchedAt` is set only by a details read, so the two TTLs in §7 of the plan
/// can be applied independently and a details screen can tell "never loaded in full"
/// from "loaded a while ago".
// Without this, Drift's singulariser turns "CachedMovies" into "CachedMovy".
@DataClassName('CachedMovie')
class CachedMovies extends Table {
  IntColumn get tmdbId => integer()();
  TextColumn get title => text()();
  TextColumn get originalTitle => text().withDefault(const Constant(''))();
  TextColumn get posterPath => text().nullable()();
  DateTimeColumn get releaseDate => dateTime().nullable()();
  TextColumn get overview => text().withDefault(const Constant(''))();
  DateTimeColumn get fetchedAt => dateTime()();
  DateTimeColumn get detailsFetchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

/// The public aggregate, mirrored locally. Weights, never raw counts — the client
/// stores exactly what `movie_scene_stats` hands out.
class CachedStats extends Table {
  IntColumn get tmdbId => integer()();
  IntColumn get rawVotes => integer().withDefault(const Constant(0))();
  RealColumn get totalWeight => real().withDefault(const Constant(0))();
  RealColumn get sceneWeight => real().withDefault(const Constant(0))();
  RealColumn get worthWeight => real().withDefault(const Constant(0))();
  RealColumn get worthTotal => real().withDefault(const Constant(0))();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

/// Feed order, kept separately from the films themselves: TMDb's ranking is a property
/// of the page, not of the film, and the same film can also arrive via search.
class FeedEntries extends Table {
  IntColumn get page => integer()();
  IntColumn get position => integer()();
  IntColumn get tmdbId => integer()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {page, position};
}

/// Search results, cached per normalised query string. Offline, this is what makes an
/// already-searched query still answerable and a new one honestly empty.
class SearchEntries extends Table {
  TextColumn get query => text()();
  IntColumn get position => integer()();
  IntColumn get tmdbId => integer()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {query, position};
}

/// The user's own votes — local truth, always readable, and the offline queue.
///
/// A vote is naturally idempotent (the server upserts on film + device), so a row that
/// is sent twice is harmless and needs no idempotency key. There is exactly one writer
/// per row, so there is no conflict to resolve either.
class LocalVotes extends Table {
  IntColumn get tmdbId => integer()();
  BoolColumn get hasScene => boolean()();
  BoolColumn get worthIt => boolean().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {tmdbId};
}

/// Small key/value store for app-level preferences (cinema mode, the install id).
/// Cheaper than a second persistence dependency for the two things that need it.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    CachedMovies,
    CachedStats,
    FeedEntries,
    SearchEntries,
    LocalVotes,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'stingers'));

  /// For tests: an in-memory database, no platform channels involved.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  Future<String?> readSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> writeSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSetting(key: key, value: value));
}

abstract final class SettingKeys {
  static const String cinemaMode = 'cinema_mode';
  static const String installId = 'install_id';
  static const String languageOverride = 'language_override';
}
