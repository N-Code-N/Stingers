import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/poster_image.dart';
import '../../data/movie_models.dart';
import 'movie_title_stack.dart';
import 'scene_badge.dart';

/// One film in a list. Shared by the feed and by search, which is most of the reason
/// those two screens are one feature rather than two.
class MovieRow extends StatelessWidget {
  const MovieRow({super.key, required this.item});

  /// Fixed so the list can set `itemExtent` and skip per-item measurement.
  static const double height = 148;

  final MovieWithStats item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = item.movie.releaseYear;

    return SizedBox(
      height: height,
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoute.movie,
          pathParameters: {'tmdbId': '${item.movie.tmdbId}'},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosterImage(path: item.movie.posterPath, width: 88, height: 132),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MovieTitleStack(
                      movie: item.movie,
                      year: year,
                      titleStyle: theme.textTheme.titleMedium,
                      subtitleStyle: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    SceneBadge(stats: item.stats),
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
