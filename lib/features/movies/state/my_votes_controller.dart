import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exceptions.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';

/// State for "my votes".
///
/// The local database is the authority here — these are the user's own rows, written
/// before the network ever saw them. The server read only fills in votes cast on a
/// previous install, and failing it changes nothing on screen.
class MyVotesController extends ChangeNotifier {
  MyVotesController({required MovieRepository repository}) : _repository = repository;

  final MovieRepository _repository;

  StreamSubscription<List<MyVoteEntry>>? _subscription;

  List<MyVoteEntry> _entries = const [];
  bool _isLoading = true;
  Object? _error;

  List<MyVoteEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> load() async {
    _subscription ??= _repository.watchMyVotes().listen(_onEntries);
    _error = null;
    notifyListeners();
    try {
      await _repository.refreshMyVotes();
      await _repository.flushPendingVotes();
    } on AppException catch (e) {
      // Only worth reporting when there is nothing local to show; otherwise the list is
      // already correct and the reconciliation can wait.
      if (_entries.isEmpty) _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onEntries(List<MyVoteEntry> entries) {
    _entries = entries;
    if (entries.isNotEmpty) {
      _isLoading = false;
      _error = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
