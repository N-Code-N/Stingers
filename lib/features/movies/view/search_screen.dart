import 'package:flutter/material.dart';

import '../../../core/errors/app_exceptions.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/error_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/state_fade.dart';
import '../data/movie_repository.dart';
import '../state/search_controller.dart';
import 'widgets/movie_row.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.repository, required this.locale});

  final MovieRepository repository;
  final AppLocaleController locale;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final MovieSearchController _controller;
  final ScrollController _scroll = ScrollController();
  int? _lastLocaleGeneration;

  @override
  void initState() {
    super.initState();
    _controller = MovieSearchController(repository: widget.repository);
    widget.locale.addListener(_onLocaleChanged);
    _lastLocaleGeneration = widget.locale.generation - 1;
    _refreshForLocale();
  }

  void _refreshForLocale() {
    final generation = widget.locale.generation;
    if (_lastLocaleGeneration == generation) return;
    _lastLocaleGeneration = generation;
    final query = _controller.query;
    if (query.trim().isEmpty) return;
    _controller.search(query, force: true);
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    _refreshForLocale();
  }

  @override
  void dispose() {
    widget.locale.removeListener(_onLocaleChanged);
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Ancestor of the Scaffold so a tap on the iOS status bar reaches the results.
    return PrimaryScrollController(
      controller: _scroll,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.navSearch)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) => TextField(
                  controller: _controller.input,
                  // The screen exists to be typed into; there is nothing else on it.
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _controller.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _controller.hasQuery
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l10n.commonClose,
                            onPressed: _controller.clear,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) =>
                    _SearchResults(controller: _controller, scrollController: _scroll),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.controller, required this.scrollController});

  final MovieSearchController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => StateFade(child: _state(context));

  /// Each state is keyed, which is what [StateFade] switches on. The result list keeps a
  /// constant key so typing a new query updates it in place rather than fading a list
  /// into an identical-looking one.
  Widget _state(BuildContext context) {
    final l10n = context.l10n;

    if (!controller.hasQuery) {
      return EmptyView(key: const ValueKey('prompt'), title: l10n.searchPrompt);
    }

    if (controller.isSearching && controller.results.isEmpty) {
      return const LoadingView(key: ValueKey('loading'));
    }

    final error = controller.error;
    if (error != null && controller.results.isEmpty) {
      // Offline with nothing cached is not a broken search — it is an honest "only what
      // you already looked for is here".
      return error is NetworkException
          ? EmptyView(
              key: const ValueKey('empty'),
              title: l10n.searchEmpty(controller.query),
              hint: l10n.searchEmptyOffline,
            )
          : ErrorView(
              key: const ValueKey('error'),
              message: describeError(l10n, error),
              onRetry: () => controller.search(controller.query),
            );
    }

    if (controller.results.isEmpty) {
      return EmptyView(
        key: const ValueKey('empty'),
        title: l10n.searchEmpty(controller.query),
      );
    }

    // Snapshotted, not read live. `StateFade` keeps the outgoing list mounted while it
    // fades out, and that list is still scrollable and still rebuilding its items — off
    // a `controller.results` that the next query has already emptied.
    final results = controller.results
        .where((item) => item.movie.matchesSearch(controller.query))
        .toList();
    return ListView.builder(
      key: const ValueKey('content'),
      controller: scrollController,
      itemExtent: MovieRow.height,
      itemCount: results.length,
      itemBuilder: (context, index) =>
          MovieRow(key: ValueKey(results[index].movie.tmdbId), item: results[index]),
    );
  }
}
