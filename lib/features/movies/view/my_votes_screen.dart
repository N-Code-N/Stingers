import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/error_messages.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/poster_image.dart';
import '../../../core/widgets/state_fade.dart';
import '../data/movie_models.dart';
import '../data/movie_repository.dart';
import '../state/my_votes_controller.dart';
import 'widgets/vote_answer_text.dart';

class MyVotesScreen extends StatefulWidget {
  const MyVotesScreen({super.key, required this.repository});

  final MovieRepository repository;

  @override
  State<MyVotesScreen> createState() => _MyVotesScreenState();
}

class _MyVotesScreenState extends State<MyVotesScreen> {
  late final MyVotesController _controller;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = MyVotesController(repository: widget.repository);
    _controller.load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Ancestor of the Scaffold so a tap on the iOS status bar reaches the list.
    return PrimaryScrollController(
      controller: _scroll,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.navMyVotes)),
        body: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => StateFade(child: _body(l10n)),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_controller.isLoading && _controller.entries.isEmpty) {
      return const LoadingView(key: ValueKey('loading'));
    }

    final error = _controller.error;
    if (error != null && _controller.entries.isEmpty) {
      return ErrorView(
        key: const ValueKey('error'),
        message: describeError(l10n, error),
        onRetry: _controller.load,
      );
    }

    if (_controller.entries.isEmpty) {
      return EmptyView(
        key: const ValueKey('empty'),
        title: l10n.myVotesEmpty,
        hint: l10n.myVotesEmptyHint,
      );
    }

    final entries = _controller.entries;
    return ListView.builder(
      key: const ValueKey('content'),
      controller: _scroll,
      itemExtent: _MyVoteRow.height,
      itemCount: entries.length,
      itemBuilder: (context, index) =>
          _MyVoteRow(key: ValueKey(entries[index].movie.tmdbId), entry: entries[index]),
    );
  }
}

class _MyVoteRow extends StatelessWidget {
  const _MyVoteRow({super.key, required this.entry});

  static const double height = 104;

  final MyVoteEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final vote = entry.vote;

    return SizedBox(
      height: height,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoute.movie,
          pathParameters: {'tmdbId': '${entry.movie.tmdbId}'},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              PosterImage(path: entry.movie.posterPath, width: 58, height: 88),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.movie.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      describeOwnVote(l10n, vote),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (vote.pendingSync) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.myVotesPending,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
