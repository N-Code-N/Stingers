import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/error_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/stale_banner.dart';
import '../../../core/widgets/state_fade.dart';
import '../data/movie_repository.dart';
import '../state/now_playing_controller.dart';
import 'widgets/movie_row.dart';

/// The feed, and the app's only root screen.
///
/// No title: the list is posters and film names, and a bar saying "in cinemas" over it
/// is a line of lit text explaining what is already obvious.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key, required this.repository, required this.locale});

  final MovieRepository repository;
  final AppLocaleController locale;

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  late final NowPlayingController _controller;
  final ScrollController _scroll = ScrollController();
  int? _lastLocaleGeneration;

  @override
  void initState() {
    super.initState();
    _controller = NowPlayingController(repository: widget.repository);
    widget.locale.addListener(_onLocaleChanged);
    _lastLocaleGeneration = widget.locale.generation;
    _controller.load();
    _scroll.addListener(_onScroll);
  }

  void _refreshForLocale() {
    final generation = widget.locale.generation;
    if (_lastLocaleGeneration == generation) return;
    _lastLocaleGeneration = generation;
    _controller.refresh();
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    _refreshForLocale();
  }

  /// Loads the next page about two screens before the end, so the list never actually
  /// runs out under the user's thumb.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < MovieRow.height * 6) _controller.loadMore();
  }

  @override
  void dispose() {
    widget.locale.removeListener(_onLocaleChanged);
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Above the Scaffold, not inside it: `ScaffoldState.handleStatusBarTap` looks the
    // controller up from its own context, so a tap on the iOS status bar only scrolls
    // this list if the controller is an *ancestor* of the Scaffold.
    return PrimaryScrollController(
      controller: _scroll,
      child: Scaffold(
        // No app bar. It carried one icon, and a strip across the top of a screen used
        // in the dark is a strip of lit pixels spent on chrome. Both controls float
        // over the list instead.
        body: Stack(
          children: [
            Padding(
              // Clears the settings button, which floats over this same space.
              padding: const EdgeInsets.only(top: 56),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => StateFade(child: _body(l10n)),
              ),
            ),
            Positioned(
              top: 56,
              right: 16,
              child: GlassButton(
                icon: Icons.settings_outlined,
                tooltip: l10n.settingsTitle,
                onPressed: () => context.pushNamed(AppRoute.settings),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: GlassButton(
                icon: Icons.search,
                tooltip: l10n.navSearch,
                onPressed: () => context.pushNamed(AppRoute.search),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Each state carries its own key: that is what [StateFade] switches on. The content
  /// key is constant, so a refresh that keeps the list on screen does not re-create it
  /// and lose the scroll position.
  Widget _body(AppLocalizations l10n) {
    if (_controller.isLoading && _controller.items.isEmpty) {
      return const LoadingView(key: ValueKey('loading'));
    }

    final error = _controller.error;
    if (error != null && _controller.items.isEmpty) {
      return ErrorView(
        key: const ValueKey('error'),
        message: describeError(l10n, error),
        onRetry: _controller.refresh,
      );
    }

    if (_controller.items.isEmpty) {
      return EmptyView(
        key: const ValueKey('empty'),
        title: l10n.feedEmpty,
        hint: l10n.feedEmptyOffline,
      );
    }

    final fetchedAt = _controller.snapshot.fetchedAt;
    // Snapshotted for the same reason as on the search screen: a list that is fading out
    // still rebuilds its items, and must not read a collection that has moved on.
    final items = _controller.items;
    return Column(
      key: const ValueKey('content'),
      children: [
        if (_controller.isStale && !_controller.isLoading && fetchedAt != null)
          StaleBanner(fetchedAt: fetchedAt),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _controller.refresh,
            child: ListView.builder(
              controller: _scroll,
              itemExtent: MovieRow.height,
              // Room for the paging spinner, and for the floating button not to cover
              // the last row.
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return _controller.isLoadingMore
                      ? const LoadingView()
                      : const SizedBox.shrink();
                }
                final item = items[index];
                return MovieRow(key: ValueKey(item.movie.tmdbId), item: item);
              },
            ),
          ),
        ),
      ],
    );
  }
}
