import 'dart:async';

import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/data/movie_repository.dart';

/// Hand-rolled fake of the repository interface — the thing every controller depends on,
/// and the reason that dependency is an interface at all.
///
/// The streams are broadcast controllers so a test can push a new snapshot and watch the
/// controller react exactly as it would to a real database write.
class FakeMovieRepository implements MovieRepository {
  final feed = StreamController<FeedSnapshot>.broadcast();
  final movie = StreamController<MovieDetails?>.broadcast();
  final search = StreamController<List<MovieWithStats>>.broadcast();
  final myVotes = StreamController<List<MyVoteEntry>>.broadcast();

  Object? refreshFeedFailure;
  Object? refreshMovieFailure;
  Object? refreshSearchFailure;
  Object? refreshMyVotesFailure;
  Object? castVoteFailure;

  /// Runs inside `refreshMovie`, before it fails. Lets a test pin the interleaving a
  /// real device produces: the database answers from disk while the network request is
  /// still on its way to failing.
  void Function()? onRefreshMovie;

  /// Holds `refreshMovie` open until it completes. A request that hangs rather than
  /// fails is the airplane-mode case that matters: the DNS answer is still cached from
  /// the online visit, so the socket connect waits instead of being refused.
  Future<void>? refreshMovieGate;
  VoteOutcome castVoteOutcome = VoteOutcome.sent;
  bool feedHasMore = true;

  int refreshFeedCalls = 0;
  int refreshMovieCalls = 0;
  int forcedRefreshMovieCalls = 0;
  int flushCalls = 0;
  final List<String> searches = [];
  final List<({int tmdbId, bool hasScene, bool? worthIt})> castVotes = [];

  Future<void> close() async {
    await feed.close();
    await movie.close();
    await search.close();
    await myVotes.close();
  }

  @override
  Stream<FeedSnapshot> watchFeed() => feed.stream;

  @override
  Future<bool> refreshFeed({int page = 1, bool force = false}) async {
    refreshFeedCalls++;
    if (refreshFeedFailure != null) throw refreshFeedFailure!;
    return feedHasMore;
  }

  @override
  Stream<MovieDetails?> watchMovie(int tmdbId) => movie.stream;

  @override
  Future<void> refreshMovie(int tmdbId, {bool force = false}) async {
    refreshMovieCalls++;
    if (force) forcedRefreshMovieCalls++;
    onRefreshMovie?.call();
    if (refreshMovieGate != null) await refreshMovieGate;
    if (refreshMovieFailure != null) throw refreshMovieFailure!;
  }

  @override
  Stream<List<MovieWithStats>> watchSearch(String query) => search.stream;

  @override
  Future<void> refreshSearch(String query, {bool force = false}) async {
    searches.add(query);
    if (refreshSearchFailure != null) throw refreshSearchFailure!;
  }

  @override
  Stream<List<MyVoteEntry>> watchMyVotes() => myVotes.stream;

  @override
  Future<void> refreshMyVotes() async {
    if (refreshMyVotesFailure != null) throw refreshMyVotesFailure!;
  }

  @override
  Future<VoteOutcome> castVote({
    required int tmdbId,
    required bool hasScene,
    required bool? worthIt,
  }) async {
    castVotes.add((tmdbId: tmdbId, hasScene: hasScene, worthIt: worthIt));
    if (castVoteFailure != null) throw castVoteFailure!;
    return castVoteOutcome;
  }

  @override
  Future<int> flushPendingVotes() async {
    flushCalls++;
    return 0;
  }
}

/// Test data helpers, so a test says what it is about instead of filling in five fields.
Movie fakeMovie(int id, [String title = 'Film']) => Movie(
  tmdbId: id,
  title: title,
  posterPath: null,
  releaseDate: null,
  originalTitle: '',
);

SceneStats fakeStats({double total = 4, double scene = 3}) => SceneStats(
  rawVotes: total.round(),
  totalWeight: total,
  sceneWeight: scene,
  worthWeight: 0,
  worthTotal: 0,
);

FeedSnapshot fakeFeed(List<Movie> movies, {DateTime? fetchedAt}) => FeedSnapshot(
  items: [for (final m in movies) MovieWithStats(movie: m, stats: SceneStats.empty)],
  fetchedAt: fetchedAt,
  loadedPages: movies.isEmpty ? 0 : 1,
);
