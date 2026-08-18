import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/errors/app_exceptions.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';

/// State for the search screen.
///
/// Named `MovieSearchController` because `SearchController` is already a Material
/// widget-layer class, and having both in scope is a trap.
class MovieSearchController extends ChangeNotifier {
  MovieSearchController({
    required MovieRepository repository,
    this.debounce = const Duration(milliseconds: 350),
  }) : _repository = repository {
    input.addListener(_onInputChanged);
  }

  /// Long enough that typing a title is one request rather than eight, short enough that
  /// pausing feels like an answer is already on the way.
  final Duration debounce;

  final TextEditingController input = TextEditingController();

  final MovieRepository _repository;

  Timer? _debounceTimer;
  StreamSubscription<List<MovieWithStats>>? _subscription;

  String _query = '';
  List<MovieWithStats> _results = const [];
  bool _isSearching = false;
  Object? _error;
  bool _disposed = false;

  String get query => _query;
  List<MovieWithStats> get results => _results;
  bool get isSearching => _isSearching;
  Object? get error => _error;
  bool get hasQuery => _query.isNotEmpty;

  void _onInputChanged() {
    _debounceTimer?.cancel();
    final text = input.text.trim();

    if (text.isEmpty) {
      _subscription?.cancel();
      _subscription = null;
      _query = '';
      _results = const [];
      _error = null;
      _isSearching = false;
      _notify();
      return;
    }

    _debounceTimer = Timer(debounce, () => search(text));
  }

  Future<void> search(String text, {bool force = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (trimmed != _query) {
      _query = trimmed;
      // Subscribe before refreshing, so an already-cached query paints immediately and
      // an offline search of something searched before still answers.
      await _subscription?.cancel();
      _subscription = _repository.watchSearch(trimmed).listen(_onResults);
      _results = const [];
    }

    _isSearching = true;
    _error = null;
    _notify();

    try {
      await _repository.refreshSearch(trimmed, force: force);
    } on NetworkException catch (e) {
      if (!_disposed) _failed(trimmed, e);
    } on ApiException catch (e) {
      if (!_disposed) _failed(trimmed, e);
    } finally {
      if (!_disposed) {
        // A request for a query the user has since moved on from must not clear the
        // spinner or report its failure: by the time it lands, the screen is about
        // something else, and the search still running is not this one.
        if (trimmed == _query) {
          _isSearching = false;
          _notify();
        }
      }
    }
  }

  void _failed(String query, AppException error) {
    if (query != _query || _results.isNotEmpty) return;
    _error = error;
  }

  void clear() {
    input.clear(); // fires the listener, which resets the rest
  }

  void _onResults(List<MovieWithStats> results) {
    if (_disposed) return;
    _results = results;
    if (results.isNotEmpty) _error = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _subscription?.cancel();
    input
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }
}
