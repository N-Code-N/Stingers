import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_locale_controller.dart';
import '../../../core/l10n/error_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/poster_image.dart';
import '../../../core/widgets/reveal.dart';
import '../../../core/widgets/state_fade.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';
import '../state/movie_details_controller.dart';
import 'widgets/movie_title_stack.dart';
import 'widgets/verdict_panel.dart';
import 'widgets/vote_panel.dart';

/// One film: the verdict and the vote, and nothing else competing with them.
class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({
    super.key,
    required this.tmdbId,
    required this.repository,
    required this.locale,
  });

  final int tmdbId;
  final MovieRepository repository;
  final AppLocaleController locale;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late final MovieDetailsController _controller;
  final ScrollController _scroll = ScrollController();
  int? _lastLocaleGeneration;

  @override
  void initState() {
    super.initState();
    _controller = MovieDetailsController(
      repository: widget.repository,
      tmdbId: widget.tmdbId,
      showError: _showError,
      showQueued: _showQueued,
    );
    widget.locale.addListener(_onLocaleChanged);
    _lastLocaleGeneration = widget.locale.generation - 1;
    _refreshForLocale();
  }

  void _refreshForLocale() {
    final generation = widget.locale.generation;
    if (_lastLocaleGeneration == generation) return;
    _lastLocaleGeneration = generation;
    _controller.load(force: true);
  }

  void _onLocaleChanged() {
    if (!mounted) return;
    _refreshForLocale();
  }

  void _showError(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(describeError(context.l10n, error))));
  }

  void _showQueued() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.detailsVoteQueued)));
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

    // Ancestor of the Scaffold so a tap on the iOS status bar reaches this list; see
    // the same wiring on the feed.
    return PrimaryScrollController(
      controller: _scroll,
      child: Scaffold(
        appBar: AppBar(),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => StateFade(child: _body(l10n)),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    final details = _controller.details;

    if (details == null) {
      if (_controller.isLoading) return const LoadingView(key: ValueKey('loading'));
      final error = _controller.error;
      return ErrorView(
        key: const ValueKey('error'),
        message: describeError(l10n, error ?? l10n.errorNotFound),
        onRetry: _controller.load,
      );
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    final bodyKey =
        'content-${details.movie.tmdbId}-$languageCode-${widget.locale.generation}';

    return _DetailsBody(
      key: ValueKey(bodyKey),
      hideMedia: _controller.isLoading,
      details: details,
      hasFullDetails: _controller.hasFullDetails,
      isLoading: _controller.isLoading,
      displayStats: _controller.displayStats,
      scrollController: _scroll,
      onHasScene: _controller.setHasScene,
      onWorthIt: _controller.setWorthIt,
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    super.key,
    required this.hideMedia,
    required this.details,
    required this.hasFullDetails,
    required this.isLoading,
    required this.displayStats,
    required this.scrollController,
    required this.onHasScene,
    required this.onWorthIt,
  });

  final bool hideMedia;
  final MovieDetails details;
  final bool hasFullDetails;
  final bool isLoading;
  final SceneStats displayStats;
  final ScrollController scrollController;
  final ValueChanged<bool> onHasScene;
  final ValueChanged<bool> onWorthIt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final movie = details.movie;
    final posterPath = hideMedia ? null : movie.posterPath;

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // The verdict comes first and largest. Poster and description are detail, and
        // detail belongs below it.
        VerdictPanel(stats: displayStats, myVote: details.myVote, isLoading: isLoading),
        const SizedBox(height: 32),
        Divider(color: theme.colorScheme.outline),
        const SizedBox(height: 24),
        VotePanel(vote: details.myVote, onHasScene: onHasScene, onWorthIt: onWorthIt),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PosterImage(
              path: posterPath,
              width: 96,
              height: 144,
              size: AppConfig.posterDetailSize,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: MovieTitleStack(
                movie: movie,
                year: movie.releaseYear,
                titleStyle: theme.textTheme.titleLarge,
                subtitleStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        // The description arrives a round trip after the rest of the screen, so it grows
        // in rather than shoving the page around between two frames. Same widget as the
        // second vote question, and it obeys the same reduce-motion rule.
        Reveal(
          visible: !hideMedia && hasFullDetails && movie.overview.isNotEmpty,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(l10n.detailsOverview, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                movie.overview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
