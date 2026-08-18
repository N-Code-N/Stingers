import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/motion/app_motion.dart';
import '../../../../core/widgets/reveal.dart';
import '../../data/movie_models.dart';

/// The answer, at the size someone can read one-handed, in the dark, in two seconds.
///
/// This is the largest thing on the movie screen on purpose: fewer lit pixels carrying
/// more meaning is the entire design brief. Vote counts and description sit below it, at
/// a visibly lower weight.
///
/// Nothing here animates on first paint — the answer is the reason the screen exists and
/// it must be readable in the first frame. The motion is reserved for the answer
/// *changing* under the reader, which is what happens the moment they vote.
class VerdictPanel extends StatelessWidget {
  const VerdictPanel({
    super.key,
    required this.stats,
    this.isLoading = false,
    this.isVoting = false,
  });

  final SceneStats stats;
  final bool isLoading;
  final bool isVoting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VerdictSwitch(
          // Identity, not content: the percentage ticking up by one is an update to the
          // same verdict and must not cross-fade the headline. "No verdict" becoming
          // "there is a scene" is a different answer and must.
          verdictKey: ValueKey((stats.hasVerdict, stats.hasVerdict && stats.hasScene)),
          child: stats.hasVerdict
              ? _Block(
                  headline: stats.hasScene ? l10n.detailsSceneYes : l10n.detailsSceneNo,
                  detail: isLoading
                      ? ''
                      : l10n.detailsSceneConfidence(stats.verdictPercent),
                  emphasis: stats.hasScene,
                )
              : _Block(
                  headline: l10n.detailsSceneUnknown,
                  detail: l10n.detailsSceneUnknownHint,
                  emphasis: false,
                ),
        ),
        Reveal(
          visible: stats.hasWorthVerdict,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Divider(color: theme.colorScheme.outline),
              const SizedBox(height: 24),
              _Block(
                headline: stats.worthIt ? l10n.detailsWorthYes : l10n.detailsWorthNo,
                detail: isLoading
                    ? ''
                    : l10n.detailsWorthConfidence(stats.worthVerdictPercent),
                emphasis: stats.worthIt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cross-fades one verdict into another, with a little vertical travel so the new answer
/// reads as arriving rather than as the old one recolouring.
class _VerdictSwitch extends StatelessWidget {
  const _VerdictSwitch({required this.verdictKey, required this.child});

  final Key verdictKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.duration(context, AppMotion.long),
    switchInCurve: AppMotion.curve,
    switchOutCurve: AppMotion.curve,
    transitionBuilder: (child, animation) =>
        FadeTransition(opacity: animation, child: child),
    layoutBuilder: (currentChild, previousChildren) {
      final children = [...previousChildren];
      if (currentChild != null) {
        children.add(currentChild);
      }
      return Stack(alignment: AlignmentDirectional.topStart, children: children);
    },
    child: KeyedSubtree(key: verdictKey, child: child),
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.headline, required this.detail, required this.emphasis});

  final String headline;
  final String detail;

  /// A positive verdict is the one worth lighting up; a negative one is information the
  /// user acts on by leaving, so it does not need the accent colour.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPercent = detail.contains('%');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: theme.textTheme.displaySmall?.copyWith(
            color: emphasis ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: detail.isEmpty
              ? const SizedBox(key: ValueKey('empty-detail'), height: 20, width: 1)
              : Align(
                  key: ValueKey(detail),
                  alignment: isPercent
                      ? AlignmentDirectional.centerEnd
                      : AlignmentDirectional.centerStart,
                  child: Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
