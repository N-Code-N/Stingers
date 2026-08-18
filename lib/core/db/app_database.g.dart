// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedMoviesTable extends CachedMovies
    with TableInfo<$CachedMoviesTable, CachedMovie> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta('posterPath');
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta('releaseDate');
  @override
  late final GeneratedColumn<DateTime> releaseDate = GeneratedColumn<DateTime>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overviewMeta = const VerificationMeta('overview');
  @override
  late final GeneratedColumn<String> overview = GeneratedColumn<String>(
    'overview',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsFetchedAtMeta = const VerificationMeta(
    'detailsFetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> detailsFetchedAt = GeneratedColumn<DateTime>(
    'details_fetched_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    title,
    originalTitle,
    posterPath,
    releaseDate,
    overview,
    fetchedAt,
    detailsFetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMovie> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(data['original_title']!, _originalTitleMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(data['release_date']!, _releaseDateMeta),
      );
    }
    if (data.containsKey('overview')) {
      context.handle(
        _overviewMeta,
        overview.isAcceptableOrUnknown(data['overview']!, _overviewMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('details_fetched_at')) {
      context.handle(
        _detailsFetchedAtMeta,
        detailsFetchedAt.isAcceptableOrUnknown(
          data['details_fetched_at']!,
          _detailsFetchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  CachedMovie map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMovie(
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      )!,
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}release_date'],
      ),
      overview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overview'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      detailsFetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}details_fetched_at'],
      ),
    );
  }

  @override
  $CachedMoviesTable createAlias(String alias) {
    return $CachedMoviesTable(attachedDatabase, alias);
  }
}

class CachedMovie extends DataClass implements Insertable<CachedMovie> {
  final int tmdbId;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final DateTime? releaseDate;
  final String overview;
  final DateTime fetchedAt;
  final DateTime? detailsFetchedAt;
  const CachedMovie({
    required this.tmdbId,
    required this.title,
    required this.originalTitle,
    this.posterPath,
    this.releaseDate,
    required this.overview,
    required this.fetchedAt,
    this.detailsFetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['title'] = Variable<String>(title);
    map['original_title'] = Variable<String>(originalTitle);
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<DateTime>(releaseDate);
    }
    map['overview'] = Variable<String>(overview);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    if (!nullToAbsent || detailsFetchedAt != null) {
      map['details_fetched_at'] = Variable<DateTime>(detailsFetchedAt);
    }
    return map;
  }

  CachedMoviesCompanion toCompanion(bool nullToAbsent) {
    return CachedMoviesCompanion(
      tmdbId: Value(tmdbId),
      title: Value(title),
      originalTitle: Value(originalTitle),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      overview: Value(overview),
      fetchedAt: Value(fetchedAt),
      detailsFetchedAt: detailsFetchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(detailsFetchedAt),
    );
  }

  factory CachedMovie.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMovie(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String>(json['originalTitle']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      releaseDate: serializer.fromJson<DateTime?>(json['releaseDate']),
      overview: serializer.fromJson<String>(json['overview']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      detailsFetchedAt: serializer.fromJson<DateTime?>(json['detailsFetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String>(originalTitle),
      'posterPath': serializer.toJson<String?>(posterPath),
      'releaseDate': serializer.toJson<DateTime?>(releaseDate),
      'overview': serializer.toJson<String>(overview),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'detailsFetchedAt': serializer.toJson<DateTime?>(detailsFetchedAt),
    };
  }

  CachedMovie copyWith({
    int? tmdbId,
    String? title,
    String? originalTitle,
    Value<String?> posterPath = const Value.absent(),
    Value<DateTime?> releaseDate = const Value.absent(),
    String? overview,
    DateTime? fetchedAt,
    Value<DateTime?> detailsFetchedAt = const Value.absent(),
  }) => CachedMovie(
    tmdbId: tmdbId ?? this.tmdbId,
    title: title ?? this.title,
    originalTitle: originalTitle ?? this.originalTitle,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    overview: overview ?? this.overview,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    detailsFetchedAt: detailsFetchedAt.present
        ? detailsFetchedAt.value
        : this.detailsFetchedAt,
  );
  CachedMovie copyWithCompanion(CachedMoviesCompanion data) {
    return CachedMovie(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      posterPath: data.posterPath.present ? data.posterPath.value : this.posterPath,
      releaseDate: data.releaseDate.present ? data.releaseDate.value : this.releaseDate,
      overview: data.overview.present ? data.overview.value : this.overview,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      detailsFetchedAt: data.detailsFetchedAt.present
          ? data.detailsFetchedAt.value
          : this.detailsFetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMovie(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('posterPath: $posterPath, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('overview: $overview, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailsFetchedAt: $detailsFetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tmdbId,
    title,
    originalTitle,
    posterPath,
    releaseDate,
    overview,
    fetchedAt,
    detailsFetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMovie &&
          other.tmdbId == this.tmdbId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.posterPath == this.posterPath &&
          other.releaseDate == this.releaseDate &&
          other.overview == this.overview &&
          other.fetchedAt == this.fetchedAt &&
          other.detailsFetchedAt == this.detailsFetchedAt);
}

class CachedMoviesCompanion extends UpdateCompanion<CachedMovie> {
  final Value<int> tmdbId;
  final Value<String> title;
  final Value<String> originalTitle;
  final Value<String?> posterPath;
  final Value<DateTime?> releaseDate;
  final Value<String> overview;
  final Value<DateTime> fetchedAt;
  final Value<DateTime?> detailsFetchedAt;
  const CachedMoviesCompanion({
    this.tmdbId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.overview = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.detailsFetchedAt = const Value.absent(),
  });
  CachedMoviesCompanion.insert({
    this.tmdbId = const Value.absent(),
    required String title,
    this.originalTitle = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.overview = const Value.absent(),
    required DateTime fetchedAt,
    this.detailsFetchedAt = const Value.absent(),
  }) : title = Value(title),
       fetchedAt = Value(fetchedAt);
  static Insertable<CachedMovie> custom({
    Expression<int>? tmdbId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? posterPath,
    Expression<DateTime>? releaseDate,
    Expression<String>? overview,
    Expression<DateTime>? fetchedAt,
    Expression<DateTime>? detailsFetchedAt,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (posterPath != null) 'poster_path': posterPath,
      if (releaseDate != null) 'release_date': releaseDate,
      if (overview != null) 'overview': overview,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (detailsFetchedAt != null) 'details_fetched_at': detailsFetchedAt,
    });
  }

  CachedMoviesCompanion copyWith({
    Value<int>? tmdbId,
    Value<String>? title,
    Value<String>? originalTitle,
    Value<String?>? posterPath,
    Value<DateTime?>? releaseDate,
    Value<String>? overview,
    Value<DateTime>? fetchedAt,
    Value<DateTime?>? detailsFetchedAt,
  }) {
    return CachedMoviesCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      posterPath: posterPath ?? this.posterPath,
      releaseDate: releaseDate ?? this.releaseDate,
      overview: overview ?? this.overview,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      detailsFetchedAt: detailsFetchedAt ?? this.detailsFetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<DateTime>(releaseDate.value);
    }
    if (overview.present) {
      map['overview'] = Variable<String>(overview.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (detailsFetchedAt.present) {
      map['details_fetched_at'] = Variable<DateTime>(detailsFetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMoviesCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('posterPath: $posterPath, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('overview: $overview, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('detailsFetchedAt: $detailsFetchedAt')
          ..write(')'))
        .toString();
  }
}

class $CachedStatsTable extends CachedStats
    with TableInfo<$CachedStatsTable, CachedStat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedStatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawVotesMeta = const VerificationMeta('rawVotes');
  @override
  late final GeneratedColumn<int> rawVotes = GeneratedColumn<int>(
    'raw_votes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalWeightMeta = const VerificationMeta('totalWeight');
  @override
  late final GeneratedColumn<double> totalWeight = GeneratedColumn<double>(
    'total_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sceneWeightMeta = const VerificationMeta('sceneWeight');
  @override
  late final GeneratedColumn<double> sceneWeight = GeneratedColumn<double>(
    'scene_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _worthWeightMeta = const VerificationMeta('worthWeight');
  @override
  late final GeneratedColumn<double> worthWeight = GeneratedColumn<double>(
    'worth_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _worthTotalMeta = const VerificationMeta('worthTotal');
  @override
  late final GeneratedColumn<double> worthTotal = GeneratedColumn<double>(
    'worth_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    rawVotes,
    totalWeight,
    sceneWeight,
    worthWeight,
    worthTotal,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_stats';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedStat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('raw_votes')) {
      context.handle(
        _rawVotesMeta,
        rawVotes.isAcceptableOrUnknown(data['raw_votes']!, _rawVotesMeta),
      );
    }
    if (data.containsKey('total_weight')) {
      context.handle(
        _totalWeightMeta,
        totalWeight.isAcceptableOrUnknown(data['total_weight']!, _totalWeightMeta),
      );
    }
    if (data.containsKey('scene_weight')) {
      context.handle(
        _sceneWeightMeta,
        sceneWeight.isAcceptableOrUnknown(data['scene_weight']!, _sceneWeightMeta),
      );
    }
    if (data.containsKey('worth_weight')) {
      context.handle(
        _worthWeightMeta,
        worthWeight.isAcceptableOrUnknown(data['worth_weight']!, _worthWeightMeta),
      );
    }
    if (data.containsKey('worth_total')) {
      context.handle(
        _worthTotalMeta,
        worthTotal.isAcceptableOrUnknown(data['worth_total']!, _worthTotalMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  CachedStat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedStat(
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      rawVotes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raw_votes'],
      )!,
      totalWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_weight'],
      )!,
      sceneWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}scene_weight'],
      )!,
      worthWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}worth_weight'],
      )!,
      worthTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}worth_total'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $CachedStatsTable createAlias(String alias) {
    return $CachedStatsTable(attachedDatabase, alias);
  }
}

class CachedStat extends DataClass implements Insertable<CachedStat> {
  final int tmdbId;
  final int rawVotes;
  final double totalWeight;
  final double sceneWeight;
  final double worthWeight;
  final double worthTotal;
  final DateTime fetchedAt;
  const CachedStat({
    required this.tmdbId,
    required this.rawVotes,
    required this.totalWeight,
    required this.sceneWeight,
    required this.worthWeight,
    required this.worthTotal,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['raw_votes'] = Variable<int>(rawVotes);
    map['total_weight'] = Variable<double>(totalWeight);
    map['scene_weight'] = Variable<double>(sceneWeight);
    map['worth_weight'] = Variable<double>(worthWeight);
    map['worth_total'] = Variable<double>(worthTotal);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  CachedStatsCompanion toCompanion(bool nullToAbsent) {
    return CachedStatsCompanion(
      tmdbId: Value(tmdbId),
      rawVotes: Value(rawVotes),
      totalWeight: Value(totalWeight),
      sceneWeight: Value(sceneWeight),
      worthWeight: Value(worthWeight),
      worthTotal: Value(worthTotal),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory CachedStat.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedStat(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      rawVotes: serializer.fromJson<int>(json['rawVotes']),
      totalWeight: serializer.fromJson<double>(json['totalWeight']),
      sceneWeight: serializer.fromJson<double>(json['sceneWeight']),
      worthWeight: serializer.fromJson<double>(json['worthWeight']),
      worthTotal: serializer.fromJson<double>(json['worthTotal']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'rawVotes': serializer.toJson<int>(rawVotes),
      'totalWeight': serializer.toJson<double>(totalWeight),
      'sceneWeight': serializer.toJson<double>(sceneWeight),
      'worthWeight': serializer.toJson<double>(worthWeight),
      'worthTotal': serializer.toJson<double>(worthTotal),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  CachedStat copyWith({
    int? tmdbId,
    int? rawVotes,
    double? totalWeight,
    double? sceneWeight,
    double? worthWeight,
    double? worthTotal,
    DateTime? fetchedAt,
  }) => CachedStat(
    tmdbId: tmdbId ?? this.tmdbId,
    rawVotes: rawVotes ?? this.rawVotes,
    totalWeight: totalWeight ?? this.totalWeight,
    sceneWeight: sceneWeight ?? this.sceneWeight,
    worthWeight: worthWeight ?? this.worthWeight,
    worthTotal: worthTotal ?? this.worthTotal,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  CachedStat copyWithCompanion(CachedStatsCompanion data) {
    return CachedStat(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      rawVotes: data.rawVotes.present ? data.rawVotes.value : this.rawVotes,
      totalWeight: data.totalWeight.present ? data.totalWeight.value : this.totalWeight,
      sceneWeight: data.sceneWeight.present ? data.sceneWeight.value : this.sceneWeight,
      worthWeight: data.worthWeight.present ? data.worthWeight.value : this.worthWeight,
      worthTotal: data.worthTotal.present ? data.worthTotal.value : this.worthTotal,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedStat(')
          ..write('tmdbId: $tmdbId, ')
          ..write('rawVotes: $rawVotes, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('sceneWeight: $sceneWeight, ')
          ..write('worthWeight: $worthWeight, ')
          ..write('worthTotal: $worthTotal, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    tmdbId,
    rawVotes,
    totalWeight,
    sceneWeight,
    worthWeight,
    worthTotal,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedStat &&
          other.tmdbId == this.tmdbId &&
          other.rawVotes == this.rawVotes &&
          other.totalWeight == this.totalWeight &&
          other.sceneWeight == this.sceneWeight &&
          other.worthWeight == this.worthWeight &&
          other.worthTotal == this.worthTotal &&
          other.fetchedAt == this.fetchedAt);
}

class CachedStatsCompanion extends UpdateCompanion<CachedStat> {
  final Value<int> tmdbId;
  final Value<int> rawVotes;
  final Value<double> totalWeight;
  final Value<double> sceneWeight;
  final Value<double> worthWeight;
  final Value<double> worthTotal;
  final Value<DateTime> fetchedAt;
  const CachedStatsCompanion({
    this.tmdbId = const Value.absent(),
    this.rawVotes = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.sceneWeight = const Value.absent(),
    this.worthWeight = const Value.absent(),
    this.worthTotal = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  CachedStatsCompanion.insert({
    this.tmdbId = const Value.absent(),
    this.rawVotes = const Value.absent(),
    this.totalWeight = const Value.absent(),
    this.sceneWeight = const Value.absent(),
    this.worthWeight = const Value.absent(),
    this.worthTotal = const Value.absent(),
    required DateTime fetchedAt,
  }) : fetchedAt = Value(fetchedAt);
  static Insertable<CachedStat> custom({
    Expression<int>? tmdbId,
    Expression<int>? rawVotes,
    Expression<double>? totalWeight,
    Expression<double>? sceneWeight,
    Expression<double>? worthWeight,
    Expression<double>? worthTotal,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (rawVotes != null) 'raw_votes': rawVotes,
      if (totalWeight != null) 'total_weight': totalWeight,
      if (sceneWeight != null) 'scene_weight': sceneWeight,
      if (worthWeight != null) 'worth_weight': worthWeight,
      if (worthTotal != null) 'worth_total': worthTotal,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  CachedStatsCompanion copyWith({
    Value<int>? tmdbId,
    Value<int>? rawVotes,
    Value<double>? totalWeight,
    Value<double>? sceneWeight,
    Value<double>? worthWeight,
    Value<double>? worthTotal,
    Value<DateTime>? fetchedAt,
  }) {
    return CachedStatsCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      rawVotes: rawVotes ?? this.rawVotes,
      totalWeight: totalWeight ?? this.totalWeight,
      sceneWeight: sceneWeight ?? this.sceneWeight,
      worthWeight: worthWeight ?? this.worthWeight,
      worthTotal: worthTotal ?? this.worthTotal,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (rawVotes.present) {
      map['raw_votes'] = Variable<int>(rawVotes.value);
    }
    if (totalWeight.present) {
      map['total_weight'] = Variable<double>(totalWeight.value);
    }
    if (sceneWeight.present) {
      map['scene_weight'] = Variable<double>(sceneWeight.value);
    }
    if (worthWeight.present) {
      map['worth_weight'] = Variable<double>(worthWeight.value);
    }
    if (worthTotal.present) {
      map['worth_total'] = Variable<double>(worthTotal.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedStatsCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('rawVotes: $rawVotes, ')
          ..write('totalWeight: $totalWeight, ')
          ..write('sceneWeight: $sceneWeight, ')
          ..write('worthWeight: $worthWeight, ')
          ..write('worthTotal: $worthTotal, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

class $FeedEntriesTable extends FeedEntries with TableInfo<$FeedEntriesTable, FeedEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _pageMeta = const VerificationMeta('page');
  @override
  late final GeneratedColumn<int> page = GeneratedColumn<int>(
    'page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [page, position, tmdbId, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('page')) {
      context.handle(_pageMeta, page.isAcceptableOrUnknown(data['page']!, _pageMeta));
    } else if (isInserting) {
      context.missing(_pageMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {page, position};
  @override
  FeedEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedEntry(
      page: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $FeedEntriesTable createAlias(String alias) {
    return $FeedEntriesTable(attachedDatabase, alias);
  }
}

class FeedEntry extends DataClass implements Insertable<FeedEntry> {
  final int page;
  final int position;
  final int tmdbId;
  final DateTime fetchedAt;
  const FeedEntry({
    required this.page,
    required this.position,
    required this.tmdbId,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['page'] = Variable<int>(page);
    map['position'] = Variable<int>(position);
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  FeedEntriesCompanion toCompanion(bool nullToAbsent) {
    return FeedEntriesCompanion(
      page: Value(page),
      position: Value(position),
      tmdbId: Value(tmdbId),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory FeedEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedEntry(
      page: serializer.fromJson<int>(json['page']),
      position: serializer.fromJson<int>(json['position']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'page': serializer.toJson<int>(page),
      'position': serializer.toJson<int>(position),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  FeedEntry copyWith({int? page, int? position, int? tmdbId, DateTime? fetchedAt}) =>
      FeedEntry(
        page: page ?? this.page,
        position: position ?? this.position,
        tmdbId: tmdbId ?? this.tmdbId,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  FeedEntry copyWithCompanion(FeedEntriesCompanion data) {
    return FeedEntry(
      page: data.page.present ? data.page.value : this.page,
      position: data.position.present ? data.position.value : this.position,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedEntry(')
          ..write('page: $page, ')
          ..write('position: $position, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(page, position, tmdbId, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedEntry &&
          other.page == this.page &&
          other.position == this.position &&
          other.tmdbId == this.tmdbId &&
          other.fetchedAt == this.fetchedAt);
}

class FeedEntriesCompanion extends UpdateCompanion<FeedEntry> {
  final Value<int> page;
  final Value<int> position;
  final Value<int> tmdbId;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const FeedEntriesCompanion({
    this.page = const Value.absent(),
    this.position = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedEntriesCompanion.insert({
    required int page,
    required int position,
    required int tmdbId,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : page = Value(page),
       position = Value(position),
       tmdbId = Value(tmdbId),
       fetchedAt = Value(fetchedAt);
  static Insertable<FeedEntry> custom({
    Expression<int>? page,
    Expression<int>? position,
    Expression<int>? tmdbId,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (page != null) 'page': page,
      if (position != null) 'position': position,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedEntriesCompanion copyWith({
    Value<int>? page,
    Value<int>? position,
    Value<int>? tmdbId,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return FeedEntriesCompanion(
      page: page ?? this.page,
      position: position ?? this.position,
      tmdbId: tmdbId ?? this.tmdbId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (page.present) {
      map['page'] = Variable<int>(page.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedEntriesCompanion(')
          ..write('page: $page, ')
          ..write('position: $position, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SearchEntriesTable extends SearchEntries
    with TableInfo<$SearchEntriesTable, SearchEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SearchEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _queryMeta = const VerificationMeta('query');
  @override
  late final GeneratedColumn<String> query = GeneratedColumn<String>(
    'query',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [query, position, tmdbId, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'search_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SearchEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('query')) {
      context.handle(_queryMeta, query.isAcceptableOrUnknown(data['query']!, _queryMeta));
    } else if (isInserting) {
      context.missing(_queryMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {query, position};
  @override
  SearchEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SearchEntry(
      query: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}query'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $SearchEntriesTable createAlias(String alias) {
    return $SearchEntriesTable(attachedDatabase, alias);
  }
}

class SearchEntry extends DataClass implements Insertable<SearchEntry> {
  final String query;
  final int position;
  final int tmdbId;
  final DateTime fetchedAt;
  const SearchEntry({
    required this.query,
    required this.position,
    required this.tmdbId,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['query'] = Variable<String>(query);
    map['position'] = Variable<int>(position);
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  SearchEntriesCompanion toCompanion(bool nullToAbsent) {
    return SearchEntriesCompanion(
      query: Value(query),
      position: Value(position),
      tmdbId: Value(tmdbId),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory SearchEntry.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SearchEntry(
      query: serializer.fromJson<String>(json['query']),
      position: serializer.fromJson<int>(json['position']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'query': serializer.toJson<String>(query),
      'position': serializer.toJson<int>(position),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  SearchEntry copyWith({
    String? query,
    int? position,
    int? tmdbId,
    DateTime? fetchedAt,
  }) => SearchEntry(
    query: query ?? this.query,
    position: position ?? this.position,
    tmdbId: tmdbId ?? this.tmdbId,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  SearchEntry copyWithCompanion(SearchEntriesCompanion data) {
    return SearchEntry(
      query: data.query.present ? data.query.value : this.query,
      position: data.position.present ? data.position.value : this.position,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SearchEntry(')
          ..write('query: $query, ')
          ..write('position: $position, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(query, position, tmdbId, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SearchEntry &&
          other.query == this.query &&
          other.position == this.position &&
          other.tmdbId == this.tmdbId &&
          other.fetchedAt == this.fetchedAt);
}

class SearchEntriesCompanion extends UpdateCompanion<SearchEntry> {
  final Value<String> query;
  final Value<int> position;
  final Value<int> tmdbId;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const SearchEntriesCompanion({
    this.query = const Value.absent(),
    this.position = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SearchEntriesCompanion.insert({
    required String query,
    required int position,
    required int tmdbId,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : query = Value(query),
       position = Value(position),
       tmdbId = Value(tmdbId),
       fetchedAt = Value(fetchedAt);
  static Insertable<SearchEntry> custom({
    Expression<String>? query,
    Expression<int>? position,
    Expression<int>? tmdbId,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (query != null) 'query': query,
      if (position != null) 'position': position,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SearchEntriesCompanion copyWith({
    Value<String>? query,
    Value<int>? position,
    Value<int>? tmdbId,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return SearchEntriesCompanion(
      query: query ?? this.query,
      position: position ?? this.position,
      tmdbId: tmdbId ?? this.tmdbId,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (query.present) {
      map['query'] = Variable<String>(query.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SearchEntriesCompanion(')
          ..write('query: $query, ')
          ..write('position: $position, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalVotesTable extends LocalVotes with TableInfo<$LocalVotesTable, LocalVote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalVotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasSceneMeta = const VerificationMeta('hasScene');
  @override
  late final GeneratedColumn<bool> hasScene = GeneratedColumn<bool>(
    'has_scene',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_scene" IN (0, 1))',
    ),
  );
  static const VerificationMeta _worthItMeta = const VerificationMeta('worthIt');
  @override
  late final GeneratedColumn<bool> worthIt = GeneratedColumn<bool>(
    'worth_it',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("worth_it" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pendingSyncMeta = const VerificationMeta('pendingSync');
  @override
  late final GeneratedColumn<bool> pendingSync = GeneratedColumn<bool>(
    'pending_sync',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_sync" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    tmdbId,
    hasScene,
    worthIt,
    updatedAt,
    pendingSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_votes';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalVote> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    }
    if (data.containsKey('has_scene')) {
      context.handle(
        _hasSceneMeta,
        hasScene.isAcceptableOrUnknown(data['has_scene']!, _hasSceneMeta),
      );
    } else if (isInserting) {
      context.missing(_hasSceneMeta);
    }
    if (data.containsKey('worth_it')) {
      context.handle(
        _worthItMeta,
        worthIt.isAcceptableOrUnknown(data['worth_it']!, _worthItMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('pending_sync')) {
      context.handle(
        _pendingSyncMeta,
        pendingSync.isAcceptableOrUnknown(data['pending_sync']!, _pendingSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tmdbId};
  @override
  LocalVote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalVote(
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      hasScene: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_scene'],
      )!,
      worthIt: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}worth_it'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      pendingSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_sync'],
      )!,
    );
  }

  @override
  $LocalVotesTable createAlias(String alias) {
    return $LocalVotesTable(attachedDatabase, alias);
  }
}

class LocalVote extends DataClass implements Insertable<LocalVote> {
  final int tmdbId;
  final bool hasScene;
  final bool? worthIt;
  final DateTime updatedAt;
  final bool pendingSync;
  const LocalVote({
    required this.tmdbId,
    required this.hasScene,
    this.worthIt,
    required this.updatedAt,
    required this.pendingSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tmdb_id'] = Variable<int>(tmdbId);
    map['has_scene'] = Variable<bool>(hasScene);
    if (!nullToAbsent || worthIt != null) {
      map['worth_it'] = Variable<bool>(worthIt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['pending_sync'] = Variable<bool>(pendingSync);
    return map;
  }

  LocalVotesCompanion toCompanion(bool nullToAbsent) {
    return LocalVotesCompanion(
      tmdbId: Value(tmdbId),
      hasScene: Value(hasScene),
      worthIt: worthIt == null && nullToAbsent ? const Value.absent() : Value(worthIt),
      updatedAt: Value(updatedAt),
      pendingSync: Value(pendingSync),
    );
  }

  factory LocalVote.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalVote(
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      hasScene: serializer.fromJson<bool>(json['hasScene']),
      worthIt: serializer.fromJson<bool?>(json['worthIt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      pendingSync: serializer.fromJson<bool>(json['pendingSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tmdbId': serializer.toJson<int>(tmdbId),
      'hasScene': serializer.toJson<bool>(hasScene),
      'worthIt': serializer.toJson<bool?>(worthIt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'pendingSync': serializer.toJson<bool>(pendingSync),
    };
  }

  LocalVote copyWith({
    int? tmdbId,
    bool? hasScene,
    Value<bool?> worthIt = const Value.absent(),
    DateTime? updatedAt,
    bool? pendingSync,
  }) => LocalVote(
    tmdbId: tmdbId ?? this.tmdbId,
    hasScene: hasScene ?? this.hasScene,
    worthIt: worthIt.present ? worthIt.value : this.worthIt,
    updatedAt: updatedAt ?? this.updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );
  LocalVote copyWithCompanion(LocalVotesCompanion data) {
    return LocalVote(
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      hasScene: data.hasScene.present ? data.hasScene.value : this.hasScene,
      worthIt: data.worthIt.present ? data.worthIt.value : this.worthIt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      pendingSync: data.pendingSync.present ? data.pendingSync.value : this.pendingSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalVote(')
          ..write('tmdbId: $tmdbId, ')
          ..write('hasScene: $hasScene, ')
          ..write('worthIt: $worthIt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tmdbId, hasScene, worthIt, updatedAt, pendingSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalVote &&
          other.tmdbId == this.tmdbId &&
          other.hasScene == this.hasScene &&
          other.worthIt == this.worthIt &&
          other.updatedAt == this.updatedAt &&
          other.pendingSync == this.pendingSync);
}

class LocalVotesCompanion extends UpdateCompanion<LocalVote> {
  final Value<int> tmdbId;
  final Value<bool> hasScene;
  final Value<bool?> worthIt;
  final Value<DateTime> updatedAt;
  final Value<bool> pendingSync;
  const LocalVotesCompanion({
    this.tmdbId = const Value.absent(),
    this.hasScene = const Value.absent(),
    this.worthIt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.pendingSync = const Value.absent(),
  });
  LocalVotesCompanion.insert({
    this.tmdbId = const Value.absent(),
    required bool hasScene,
    this.worthIt = const Value.absent(),
    required DateTime updatedAt,
    this.pendingSync = const Value.absent(),
  }) : hasScene = Value(hasScene),
       updatedAt = Value(updatedAt);
  static Insertable<LocalVote> custom({
    Expression<int>? tmdbId,
    Expression<bool>? hasScene,
    Expression<bool>? worthIt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? pendingSync,
  }) {
    return RawValuesInsertable({
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (hasScene != null) 'has_scene': hasScene,
      if (worthIt != null) 'worth_it': worthIt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (pendingSync != null) 'pending_sync': pendingSync,
    });
  }

  LocalVotesCompanion copyWith({
    Value<int>? tmdbId,
    Value<bool>? hasScene,
    Value<bool?>? worthIt,
    Value<DateTime>? updatedAt,
    Value<bool>? pendingSync,
  }) {
    return LocalVotesCompanion(
      tmdbId: tmdbId ?? this.tmdbId,
      hasScene: hasScene ?? this.hasScene,
      worthIt: worthIt ?? this.worthIt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (hasScene.present) {
      map['has_scene'] = Variable<bool>(hasScene.value);
    }
    if (worthIt.present) {
      map['worth_it'] = Variable<bool>(worthIt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (pendingSync.present) {
      map['pending_sync'] = Variable<bool>(pendingSync.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalVotesCompanion(')
          ..write('tmdbId: $tmdbId, ')
          ..write('hasScene: $hasScene, ')
          ..write('worthIt: $worthIt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('pendingSync: $pendingSync')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting && other.key == this.key && other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedMoviesTable cachedMovies = $CachedMoviesTable(this);
  late final $CachedStatsTable cachedStats = $CachedStatsTable(this);
  late final $FeedEntriesTable feedEntries = $FeedEntriesTable(this);
  late final $SearchEntriesTable searchEntries = $SearchEntriesTable(this);
  late final $LocalVotesTable localVotes = $LocalVotesTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    cachedMovies,
    cachedStats,
    feedEntries,
    searchEntries,
    localVotes,
    appSettings,
  ];
}

typedef $$CachedMoviesTableCreateCompanionBuilder =
    CachedMoviesCompanion Function({
      Value<int> tmdbId,
      required String title,
      Value<String> originalTitle,
      Value<String?> posterPath,
      Value<DateTime?> releaseDate,
      Value<String> overview,
      required DateTime fetchedAt,
      Value<DateTime?> detailsFetchedAt,
    });
typedef $$CachedMoviesTableUpdateCompanionBuilder =
    CachedMoviesCompanion Function({
      Value<int> tmdbId,
      Value<String> title,
      Value<String> originalTitle,
      Value<String?> posterPath,
      Value<DateTime?> releaseDate,
      Value<String> overview,
      Value<DateTime> fetchedAt,
      Value<DateTime?> detailsFetchedAt,
    });

class $$CachedMoviesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMoviesTable> {
  $$CachedMoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get detailsFetchedAt => $composableBuilder(
    column: $table.detailsFetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMoviesTable> {
  $$CachedMoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overview => $composableBuilder(
    column: $table.overview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get detailsFetchedAt => $composableBuilder(
    column: $table.detailsFetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMoviesTable> {
  $$CachedMoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle =>
      $composableBuilder(column: $table.originalTitle, builder: (column) => column);

  GeneratedColumn<String> get posterPath =>
      $composableBuilder(column: $table.posterPath, builder: (column) => column);

  GeneratedColumn<DateTime> get releaseDate =>
      $composableBuilder(column: $table.releaseDate, builder: (column) => column);

  GeneratedColumn<String> get overview =>
      $composableBuilder(column: $table.overview, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get detailsFetchedAt =>
      $composableBuilder(column: $table.detailsFetchedAt, builder: (column) => column);
}

class $$CachedMoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMoviesTable,
          CachedMovie,
          $$CachedMoviesTableFilterComposer,
          $$CachedMoviesTableOrderingComposer,
          $$CachedMoviesTableAnnotationComposer,
          $$CachedMoviesTableCreateCompanionBuilder,
          $$CachedMoviesTableUpdateCompanionBuilder,
          (CachedMovie, BaseReferences<_$AppDatabase, $CachedMoviesTable, CachedMovie>),
          CachedMovie,
          PrefetchHooks Function()
        > {
  $$CachedMoviesTableTableManager(_$AppDatabase db, $CachedMoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> originalTitle = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String> overview = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<DateTime?> detailsFetchedAt = const Value.absent(),
              }) => CachedMoviesCompanion(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                posterPath: posterPath,
                releaseDate: releaseDate,
                overview: overview,
                fetchedAt: fetchedAt,
                detailsFetchedAt: detailsFetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                required String title,
                Value<String> originalTitle = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<DateTime?> releaseDate = const Value.absent(),
                Value<String> overview = const Value.absent(),
                required DateTime fetchedAt,
                Value<DateTime?> detailsFetchedAt = const Value.absent(),
              }) => CachedMoviesCompanion.insert(
                tmdbId: tmdbId,
                title: title,
                originalTitle: originalTitle,
                posterPath: posterPath,
                releaseDate: releaseDate,
                overview: overview,
                fetchedAt: fetchedAt,
                detailsFetchedAt: detailsFetchedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMoviesTable,
      CachedMovie,
      $$CachedMoviesTableFilterComposer,
      $$CachedMoviesTableOrderingComposer,
      $$CachedMoviesTableAnnotationComposer,
      $$CachedMoviesTableCreateCompanionBuilder,
      $$CachedMoviesTableUpdateCompanionBuilder,
      (CachedMovie, BaseReferences<_$AppDatabase, $CachedMoviesTable, CachedMovie>),
      CachedMovie,
      PrefetchHooks Function()
    >;
typedef $$CachedStatsTableCreateCompanionBuilder =
    CachedStatsCompanion Function({
      Value<int> tmdbId,
      Value<int> rawVotes,
      Value<double> totalWeight,
      Value<double> sceneWeight,
      Value<double> worthWeight,
      Value<double> worthTotal,
      required DateTime fetchedAt,
    });
typedef $$CachedStatsTableUpdateCompanionBuilder =
    CachedStatsCompanion Function({
      Value<int> tmdbId,
      Value<int> rawVotes,
      Value<double> totalWeight,
      Value<double> sceneWeight,
      Value<double> worthWeight,
      Value<double> worthTotal,
      Value<DateTime> fetchedAt,
    });

class $$CachedStatsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedStatsTable> {
  $$CachedStatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rawVotes => $composableBuilder(
    column: $table.rawVotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sceneWeight => $composableBuilder(
    column: $table.sceneWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get worthWeight => $composableBuilder(
    column: $table.worthWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get worthTotal => $composableBuilder(
    column: $table.worthTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedStatsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedStatsTable> {
  $$CachedStatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rawVotes => $composableBuilder(
    column: $table.rawVotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWeight => $composableBuilder(
    column: $table.totalWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sceneWeight => $composableBuilder(
    column: $table.sceneWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get worthWeight => $composableBuilder(
    column: $table.worthWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get worthTotal => $composableBuilder(
    column: $table.worthTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedStatsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedStatsTable> {
  $$CachedStatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get rawVotes =>
      $composableBuilder(column: $table.rawVotes, builder: (column) => column);

  GeneratedColumn<double> get totalWeight =>
      $composableBuilder(column: $table.totalWeight, builder: (column) => column);

  GeneratedColumn<double> get sceneWeight =>
      $composableBuilder(column: $table.sceneWeight, builder: (column) => column);

  GeneratedColumn<double> get worthWeight =>
      $composableBuilder(column: $table.worthWeight, builder: (column) => column);

  GeneratedColumn<double> get worthTotal =>
      $composableBuilder(column: $table.worthTotal, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$CachedStatsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedStatsTable,
          CachedStat,
          $$CachedStatsTableFilterComposer,
          $$CachedStatsTableOrderingComposer,
          $$CachedStatsTableAnnotationComposer,
          $$CachedStatsTableCreateCompanionBuilder,
          $$CachedStatsTableUpdateCompanionBuilder,
          (CachedStat, BaseReferences<_$AppDatabase, $CachedStatsTable, CachedStat>),
          CachedStat,
          PrefetchHooks Function()
        > {
  $$CachedStatsTableTableManager(_$AppDatabase db, $CachedStatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedStatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedStatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedStatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                Value<int> rawVotes = const Value.absent(),
                Value<double> totalWeight = const Value.absent(),
                Value<double> sceneWeight = const Value.absent(),
                Value<double> worthWeight = const Value.absent(),
                Value<double> worthTotal = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => CachedStatsCompanion(
                tmdbId: tmdbId,
                rawVotes: rawVotes,
                totalWeight: totalWeight,
                sceneWeight: sceneWeight,
                worthWeight: worthWeight,
                worthTotal: worthTotal,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                Value<int> rawVotes = const Value.absent(),
                Value<double> totalWeight = const Value.absent(),
                Value<double> sceneWeight = const Value.absent(),
                Value<double> worthWeight = const Value.absent(),
                Value<double> worthTotal = const Value.absent(),
                required DateTime fetchedAt,
              }) => CachedStatsCompanion.insert(
                tmdbId: tmdbId,
                rawVotes: rawVotes,
                totalWeight: totalWeight,
                sceneWeight: sceneWeight,
                worthWeight: worthWeight,
                worthTotal: worthTotal,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedStatsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedStatsTable,
      CachedStat,
      $$CachedStatsTableFilterComposer,
      $$CachedStatsTableOrderingComposer,
      $$CachedStatsTableAnnotationComposer,
      $$CachedStatsTableCreateCompanionBuilder,
      $$CachedStatsTableUpdateCompanionBuilder,
      (CachedStat, BaseReferences<_$AppDatabase, $CachedStatsTable, CachedStat>),
      CachedStat,
      PrefetchHooks Function()
    >;
typedef $$FeedEntriesTableCreateCompanionBuilder =
    FeedEntriesCompanion Function({
      required int page,
      required int position,
      required int tmdbId,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$FeedEntriesTableUpdateCompanionBuilder =
    FeedEntriesCompanion Function({
      Value<int> page,
      Value<int> position,
      Value<int> tmdbId,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$FeedEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FeedEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get page => $composableBuilder(
    column: $table.page,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FeedEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get page =>
      $composableBuilder(column: $table.page, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$FeedEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedEntriesTable,
          FeedEntry,
          $$FeedEntriesTableFilterComposer,
          $$FeedEntriesTableOrderingComposer,
          $$FeedEntriesTableAnnotationComposer,
          $$FeedEntriesTableCreateCompanionBuilder,
          $$FeedEntriesTableUpdateCompanionBuilder,
          (FeedEntry, BaseReferences<_$AppDatabase, $FeedEntriesTable, FeedEntry>),
          FeedEntry,
          PrefetchHooks Function()
        > {
  $$FeedEntriesTableTableManager(_$AppDatabase db, $FeedEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> page = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> tmdbId = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedEntriesCompanion(
                page: page,
                position: position,
                tmdbId: tmdbId,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int page,
                required int position,
                required int tmdbId,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => FeedEntriesCompanion.insert(
                page: page,
                position: position,
                tmdbId: tmdbId,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FeedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedEntriesTable,
      FeedEntry,
      $$FeedEntriesTableFilterComposer,
      $$FeedEntriesTableOrderingComposer,
      $$FeedEntriesTableAnnotationComposer,
      $$FeedEntriesTableCreateCompanionBuilder,
      $$FeedEntriesTableUpdateCompanionBuilder,
      (FeedEntry, BaseReferences<_$AppDatabase, $FeedEntriesTable, FeedEntry>),
      FeedEntry,
      PrefetchHooks Function()
    >;
typedef $$SearchEntriesTableCreateCompanionBuilder =
    SearchEntriesCompanion Function({
      required String query,
      required int position,
      required int tmdbId,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$SearchEntriesTableUpdateCompanionBuilder =
    SearchEntriesCompanion Function({
      Value<String> query,
      Value<int> position,
      Value<int> tmdbId,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$SearchEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SearchEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get query => $composableBuilder(
    column: $table.query,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SearchEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SearchEntriesTable> {
  $$SearchEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get query =>
      $composableBuilder(column: $table.query, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$SearchEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SearchEntriesTable,
          SearchEntry,
          $$SearchEntriesTableFilterComposer,
          $$SearchEntriesTableOrderingComposer,
          $$SearchEntriesTableAnnotationComposer,
          $$SearchEntriesTableCreateCompanionBuilder,
          $$SearchEntriesTableUpdateCompanionBuilder,
          (SearchEntry, BaseReferences<_$AppDatabase, $SearchEntriesTable, SearchEntry>),
          SearchEntry,
          PrefetchHooks Function()
        > {
  $$SearchEntriesTableTableManager(_$AppDatabase db, $SearchEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SearchEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SearchEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SearchEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> query = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> tmdbId = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SearchEntriesCompanion(
                query: query,
                position: position,
                tmdbId: tmdbId,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String query,
                required int position,
                required int tmdbId,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => SearchEntriesCompanion.insert(
                query: query,
                position: position,
                tmdbId: tmdbId,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SearchEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SearchEntriesTable,
      SearchEntry,
      $$SearchEntriesTableFilterComposer,
      $$SearchEntriesTableOrderingComposer,
      $$SearchEntriesTableAnnotationComposer,
      $$SearchEntriesTableCreateCompanionBuilder,
      $$SearchEntriesTableUpdateCompanionBuilder,
      (SearchEntry, BaseReferences<_$AppDatabase, $SearchEntriesTable, SearchEntry>),
      SearchEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalVotesTableCreateCompanionBuilder =
    LocalVotesCompanion Function({
      Value<int> tmdbId,
      required bool hasScene,
      Value<bool?> worthIt,
      required DateTime updatedAt,
      Value<bool> pendingSync,
    });
typedef $$LocalVotesTableUpdateCompanionBuilder =
    LocalVotesCompanion Function({
      Value<int> tmdbId,
      Value<bool> hasScene,
      Value<bool?> worthIt,
      Value<DateTime> updatedAt,
      Value<bool> pendingSync,
    });

class $$LocalVotesTableFilterComposer extends Composer<_$AppDatabase, $LocalVotesTable> {
  $$LocalVotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasScene => $composableBuilder(
    column: $table.hasScene,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get worthIt => $composableBuilder(
    column: $table.worthIt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalVotesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalVotesTable> {
  $$LocalVotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasScene => $composableBuilder(
    column: $table.hasScene,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get worthIt => $composableBuilder(
    column: $table.worthIt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingSync => $composableBuilder(
    column: $table.pendingSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalVotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalVotesTable> {
  $$LocalVotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<bool> get hasScene =>
      $composableBuilder(column: $table.hasScene, builder: (column) => column);

  GeneratedColumn<bool> get worthIt =>
      $composableBuilder(column: $table.worthIt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get pendingSync =>
      $composableBuilder(column: $table.pendingSync, builder: (column) => column);
}

class $$LocalVotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalVotesTable,
          LocalVote,
          $$LocalVotesTableFilterComposer,
          $$LocalVotesTableOrderingComposer,
          $$LocalVotesTableAnnotationComposer,
          $$LocalVotesTableCreateCompanionBuilder,
          $$LocalVotesTableUpdateCompanionBuilder,
          (LocalVote, BaseReferences<_$AppDatabase, $LocalVotesTable, LocalVote>),
          LocalVote,
          PrefetchHooks Function()
        > {
  $$LocalVotesTableTableManager(_$AppDatabase db, $LocalVotesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalVotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalVotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalVotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                Value<bool> hasScene = const Value.absent(),
                Value<bool?> worthIt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> pendingSync = const Value.absent(),
              }) => LocalVotesCompanion(
                tmdbId: tmdbId,
                hasScene: hasScene,
                worthIt: worthIt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
              ),
          createCompanionCallback:
              ({
                Value<int> tmdbId = const Value.absent(),
                required bool hasScene,
                Value<bool?> worthIt = const Value.absent(),
                required DateTime updatedAt,
                Value<bool> pendingSync = const Value.absent(),
              }) => LocalVotesCompanion.insert(
                tmdbId: tmdbId,
                hasScene: hasScene,
                worthIt: worthIt,
                updatedAt: updatedAt,
                pendingSync: pendingSync,
              ),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalVotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalVotesTable,
      LocalVote,
      $$LocalVotesTableFilterComposer,
      $$LocalVotesTableOrderingComposer,
      $$LocalVotesTableAnnotationComposer,
      $$LocalVotesTableCreateCompanionBuilder,
      $$LocalVotesTableUpdateCompanionBuilder,
      (LocalVote, BaseReferences<_$AppDatabase, $LocalVotesTable, LocalVote>),
      LocalVote,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) =>
              p0.map((e) => (e.readTable(table), BaseReferences(db, table, e))).toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
      AppSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedMoviesTableTableManager get cachedMovies =>
      $$CachedMoviesTableTableManager(_db, _db.cachedMovies);
  $$CachedStatsTableTableManager get cachedStats =>
      $$CachedStatsTableTableManager(_db, _db.cachedStats);
  $$FeedEntriesTableTableManager get feedEntries =>
      $$FeedEntriesTableTableManager(_db, _db.feedEntries);
  $$SearchEntriesTableTableManager get searchEntries =>
      $$SearchEntriesTableTableManager(_db, _db.searchEntries);
  $$LocalVotesTableTableManager get localVotes =>
      $$LocalVotesTableTableManager(_db, _db.localVotes);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
