/// Models for the `movies` vertical. Hand-written `fromJson`, no codegen.
///
/// [Movie] mirrors TMDb, which the `tmdb` Edge Function passes through unchanged.
/// [SceneStats] mirrors `movie_scene_stats`, which is the app's own data and the only
/// thing in here that nobody else has.
library;

class Movie {
  const Movie({
    required this.tmdbId,
    required this.title,
    required this.posterPath,
    required this.releaseDate,
    this.overview = '',
    this.originalTitle = '',
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      tmdbId: (json['id'] as num).toInt(),
      // `title` is the localised title and `original_title` the fallback; TMDb omits
      // neither in practice, but a film with no title at all should render as a row with
      // an empty name rather than crash the whole page.
      title: json['title'] as String? ?? json['original_title'] as String? ?? '',
      originalTitle: json['original_title'] as String? ?? '',
      posterPath: _nonEmpty(json['poster_path'] as String?),
      releaseDate: parseReleaseDate(json['release_date'] as String?),
      overview: json['overview'] as String? ?? '',
    );
  }

  final int tmdbId;
  final String title;
  final String originalTitle;
  final String? posterPath;
  final DateTime? releaseDate;
  final String overview;

  int? get releaseYear => releaseDate?.year;

  /// Whether the localised title is in Cyrillic, which is the only non-Latin script the
  /// app ships an interface for and therefore the only case where showing the original
  /// title alongside it tells the reader something.
  bool get isTitleNonEnglish => title.contains(RegExp(r'[а-яёА-ЯЁ]'));

  /// TMDb sends `""` for a film with no announced date. It is a calendar day, not an
  /// instant, so it is deliberately not converted to local time — doing so would move
  /// a release into the previous day for anyone west of UTC.
  static DateTime? parseReleaseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;
}

/// A page of TMDb results, paired with the paging info the controller needs.
class MoviesPage {
  const MoviesPage({required this.movies, required this.page, required this.totalPages});

  factory MoviesPage.fromJson(Map<String, dynamic> json) => MoviesPage(
    movies: (json['results'] as List<dynamic>? ?? const [])
        .map((e) => Movie.fromJson((e as Map).cast<String, dynamic>()))
        .toList(growable: false),
    page: (json['page'] as num?)?.toInt() ?? 1,
    totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
  );

  final List<Movie> movies;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}

/// Trust-weighted vote aggregate. Every number here is a **sum of weights**, not a count
/// of rows: a farmed vote is stored and simply weighs nothing.
///
/// The percentages and the threshold live here rather than in SQL because they are
/// display logic — division by zero and "too few votes to say" are decisions about what
/// a person is shown, and they are covered by tests.
class SceneStats {
  const SceneStats({
    required this.rawVotes,
    required this.totalWeight,
    required this.sceneWeight,
    required this.worthWeight,
    required this.worthTotal,
  });

  factory SceneStats.fromJson(Map<String, dynamic> json) => SceneStats(
    rawVotes: (json['raw_votes'] as num?)?.toInt() ?? 0,
    totalWeight: (json['total_weight'] as num?)?.toDouble() ?? 0,
    sceneWeight: (json['scene_weight'] as num?)?.toDouble() ?? 0,
    worthWeight: (json['worth_weight'] as num?)?.toDouble() ?? 0,
    worthTotal: (json['worth_total'] as num?)?.toDouble() ?? 0,
  );

  static const SceneStats empty = SceneStats(
    rawVotes: 0,
    totalWeight: 0,
    sceneWeight: 0,
    worthWeight: 0,
    worthTotal: 0,
  );

  /// Below this much *weight*, the app says "not enough votes" instead of a verdict.
  /// Weight rather than row count is the point: a farm's votes weigh next to nothing
  /// and therefore still produce no verdict however many of them there are.
  ///
  /// The number is calibrated against what a real device is actually worth today. With
  /// attestation unimplemented every phone lands on `unavailable`, which is 0.3 — so
  /// this is three ordinary people agreeing, not three votes' worth of a hypothetical
  /// fully-attested device. At the old value of 3 it took *ten* voters before a film
  /// could say anything at all, which for a crowdsourced app with no crowd yet meant
  /// every film read "unknown" forever.
  ///
  /// It also sets what one trusted device is worth: a weight of 1 clears this on its
  /// own, which is the point of being able to lock a device's trust.
  ///
  /// The value sits in the *gap* between two ordinary voters (0.6) and three (0.9)
  /// rather than on either edge. Landing it on 0.9 exactly would have been a coin flip:
  /// `0.3 * 3` is 0.8999999999999999 in binary floating point, and the sum arrives here
  /// through a Postgres `real` and a JSON round trip besides.
  static const double minWeightForVerdict = 0.75;

  /// Number of vote rows behind the aggregate, ignoring weight. Never shown as a
  /// percentage — it exists so the UI can tell "nobody voted" from "the votes weigh
  /// nothing", and so the raw/weighted gap can be audited.
  final int rawVotes;

  final double totalWeight;
  final double sceneWeight;
  final double worthWeight;

  /// Weight of the votes that answered the second question at all — that is, said there
  /// was a scene and then said whether it was worth it.
  final double worthTotal;

  bool get hasVerdict => totalWeight >= minWeightForVerdict;

  /// Strict majority. An exact 50/50 split is not a verdict of "yes".
  bool get hasScene => sceneWeight * 2 > totalWeight;

  /// Share of weight that said there *is* a scene, 0..100.
  int get scenePercent =>
      totalWeight <= 0 ? 0 : (sceneWeight / totalWeight * 100).round();

  /// The share backing whatever [hasScene] concluded, so the number always agrees with
  /// the sentence next to it.
  int get verdictPercent => hasScene ? scenePercent : 100 - scenePercent;

  bool get hasWorthVerdict => hasVerdict && hasScene && worthTotal >= minWeightForVerdict;

  bool get worthIt => worthWeight * 2 > worthTotal;

  int get worthPercent => worthTotal <= 0 ? 0 : (worthWeight / worthTotal * 100).round();

  int get worthVerdictPercent => worthIt ? worthPercent : 100 - worthPercent;

  /// Folds the user's own vote into the aggregate so the percentage moves the instant
  /// they tap, instead of after a round trip.
  ///
  /// [weight] is assumed to be 1.0 because the client is never told its own trust score
  /// — that is the point of the trust model. The server's answer overwrites this a
  /// moment later, so the assumption only has to hold for one frame.
  SceneStats withOwnVote({
    required MyVote? previous,
    required bool hasScene,
    required bool? worthIt,
    double weight = 1,
  }) {
    var votes = rawVotes;
    var total = totalWeight;
    var scene = sceneWeight;
    var worth = worthWeight;
    var worthOf = worthTotal;

    if (previous != null) {
      total -= weight;
      if (previous.hasScene) scene -= weight;
      if (previous.hasScene && previous.worthIt != null) worthOf -= weight;
      if (previous.worthIt == true) worth -= weight;
    } else {
      votes += 1;
    }

    total += weight;
    if (hasScene) scene += weight;
    if (hasScene && worthIt != null) worthOf += weight;
    if (worthIt == true) worth += weight;

    // Rounding and a stale cache can each push a subtraction below zero; a negative
    // weight would render as a negative percentage.
    double atLeastZero(double v) => v < 0 ? 0 : v;

    return SceneStats(
      rawVotes: votes,
      totalWeight: atLeastZero(total),
      sceneWeight: atLeastZero(scene),
      worthWeight: atLeastZero(worth),
      worthTotal: atLeastZero(worthOf),
    );
  }
}

/// A film plus what is known about its post-credits scene. The join the whole app exists
/// to perform — TMDb on one side, our own votes on the other.
class MovieWithStats {
  const MovieWithStats({required this.movie, required this.stats});

  final Movie movie;
  final SceneStats stats;
}

/// The user's own vote. Local truth: it is written before the network is consulted and
/// survives being offline.
class MyVote {
  const MyVote({
    required this.tmdbId,
    required this.hasScene,
    required this.worthIt,
    required this.updatedAt,
    this.pendingSync = false,
  });

  final int tmdbId;
  final bool hasScene;

  /// null when there was no scene to wait for — mirrors the database's
  /// `worth_it_only_with_scene` constraint.
  final bool? worthIt;

  final DateTime updatedAt;

  /// True while the vote is still only local. It will be flushed on the next successful
  /// request; re-sending is safe because the server upserts on (film, device).
  final bool pendingSync;

  MyVote copyWith({
    bool? hasScene,
    bool? worthIt,
    bool clearWorthIt = false,
    bool? pendingSync,
  }) => MyVote(
    tmdbId: tmdbId,
    hasScene: hasScene ?? this.hasScene,
    worthIt: clearWorthIt ? null : (worthIt ?? this.worthIt),
    updatedAt: updatedAt,
    pendingSync: pendingSync ?? this.pendingSync,
  );
}

/// One row of the "my votes" screen: the vote, plus enough of the film to render it.
class MyVoteEntry {
  const MyVoteEntry({required this.movie, required this.vote});

  final Movie movie;
  final MyVote vote;
}

/// Everything the movie screen renders, in one object so the screen has one stream.
class MovieDetails {
  const MovieDetails({
    required this.movie,
    required this.stats,
    required this.myVote,
    required this.detailsFetchedAt,
  });

  final Movie movie;
  final SceneStats stats;
  final MyVote? myVote;

  /// null when only a list read has ever touched this film, so the screen knows the
  /// overview is missing rather than empty.
  final DateTime? detailsFetchedAt;
}

/// The feed as the local database currently holds it, with the age of the oldest page
/// so the screen can say how stale it is.
class FeedSnapshot {
  const FeedSnapshot({
    required this.items,
    required this.fetchedAt,
    required this.loadedPages,
  });

  static const FeedSnapshot empty = FeedSnapshot(
    items: [],
    fetchedAt: null,
    loadedPages: 0,
  );

  final List<MovieWithStats> items;
  final DateTime? fetchedAt;
  final int loadedPages;

  bool get isEmpty => items.isEmpty;
}
