import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/app_motion.dart';
import '../../data/movie_models.dart';

/// The one-glance answer in a list row.
///
/// Below the vote threshold it says "no verdict" rather than showing a percentage —
/// a number computed from two votes is worse than no number, and a raw percentage is
/// never shown at all.
///
/// It animates because of one specific moment: voting on a film and coming back to the
/// list, where the badge this user just decided crossfades from "no verdict" to the
/// answer. Rows are keyed by film id, so scrolling builds new badges rather than
/// re-labelling recycled ones — nothing animates under a moving finger.
class SceneBadge extends StatelessWidget {
  const SceneBadge({super.key, required this.stats});

  final SceneStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final (String label, Color foreground, Color border) = switch (stats) {
      SceneStats(hasVerdict: false) => (
        l10n.badgeUnknown,
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.outline,
      ),
      SceneStats(hasScene: true) => (
        l10n.badgeScene,
        theme.colorScheme.primary,
        theme.colorScheme.primary,
      ),
      _ => (
        l10n.badgeNoScene,
        theme.colorScheme.onSurfaceVariant,
        theme.colorScheme.outline,
      ),
    };

    final duration = AppMotion.duration(context, AppMotion.medium);

    // A badge is a tiny label, not a layout element that should morph its own size.
    // `AnimatedSize` can re-enter layout while the parent is still laying out the row,
    // which is exactly the crash path seen in cinema mode.
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.curve,
      switchOutCurve: AppMotion.curve,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: child,
      ),
      child: Container(
        key: ValueKey(label),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: foreground),
        ),
      ),
    );
  }
}
