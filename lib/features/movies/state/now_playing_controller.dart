import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';

/// State for the "in cinemas" feed.
///
/// The shape follows from reading out of the database: the controller subscribes once
/// and the stream drives every repaint, so a refresh that lands in the background needs
/// no reload call. A refresh that *fails* is only an error when there is nothing cached
/// to show — otherwise it is a staleness banner over content that still works.
class NowPlayingController extends ChangeNotifier {
  NowPlayingController({required MovieRepository repository}) : _repository = repository;

  final MovieRepository _repository;

  StreamSubscription<FeedSnapshot>? _subscription;

  FeedSnapshot _snapshot = FeedSnapshot.empty;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isStale = false;
  bool _hasMore = true;
  Object? _error;

  FeedSnapshot get snapshot => _snapshot;
  List<MovieWithStats> get items => _snapshot.items;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  Object? get error => _error;

  /// True when the content on screen came from the cache and the refresh behind it
  /// failed. Paired with [FeedSnapshot.fetchedAt] to say how old it is.
  bool get isStale => _isStale;

  Future<void> load() async {
    _subscription ??= _repository.watchFeed().listen(_onSnapshot);
    await _refresh(page: 1, force: false);
  }

  /// Pull-to-refresh: ignores the TTL, because the user just asked.
  Future<void> refresh() => _refresh(page: 1, force: true);

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _snapshot.loadedPages == 0) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      _hasMore = await _repository.refreshFeed(page: _snapshot.loadedPages + 1);
      _isStale = false;
    } on AppException catch (e) {
      // Failing to extend the list must not blank out the list. The next scroll retries.
      debugPrint('feed page load failed: $e');
      _isStale = true;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void _onSnapshot(FeedSnapshot snapshot) {
    _snapshot = snapshot;
    if (snapshot.items.isNotEmpty) _isLoading = false;
    notifyListeners();
  }

  Future<void> _refresh({required int page, required bool force}) async {
    _error = null;
    notifyListeners();
    try {
      _hasMore = await _repository.refreshFeed(page: page, force: force);
      _isStale = false;
    } on AppException catch (e) {
      _failed(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _failed(AppException e) {
    if (_snapshot.isEmpty) {
      _error = e;
    } else {
      _isStale = true;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
