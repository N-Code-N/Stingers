import 'package:flutter/material.dart';

import '../../data/movie_models.dart';

/// Displays up to two title variants plus year: primary, English fallback (if different).
///
/// Logic:
/// 1. Primary title (from TMDb, localized to requested language)
/// 2. If primary is non-English (has Cyrillic, etc.) and original exists → show original
///    as English fallback (dimmed)
/// 3. Year in dimmed style
///
/// Used in both list rows and details screen.
class MovieTitleStack extends StatelessWidget {
  const MovieTitleStack({
    super.key,
    required this.movie,
    this.titleStyle,
    this.subtitleStyle,
    this.year,
  });

  final Movie movie;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final int? year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSubtitleStyle =
        subtitleStyle ??
        theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.normal,
        );
    final yearStyle = (effectiveSubtitleStyle ?? const TextStyle()).copyWith(
      fontSize: (effectiveSubtitleStyle?.fontSize ?? 12) + 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: titleStyle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Show original as English fallback if primary is non-English
        if (_shouldShowAsEnglishFallback()) ...[
          const SizedBox(height: 2),
          Text(
            movie.originalTitle,
            style: effectiveSubtitleStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (year != null) ...[const SizedBox(height: 4), Text('$year', style: yearStyle)],
      ],
    );
  }

  bool _shouldShowAsEnglishFallback() {
    return movie.isTitleNonEnglish &&
        movie.originalTitle.isNotEmpty &&
        movie.originalTitle != movie.title;
  }
}
