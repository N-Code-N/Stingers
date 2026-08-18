import 'package:flutter/widgets.dart';

import '../motion/app_motion.dart';

/// Grows a block into and out of the layout, fading as it goes.
///
/// For content that appears in response to something the user just did — a follow-up
/// question, a status line. Without it the block arrives between two frames and shoves
/// everything below it down, which reads as a glitch rather than as an answer.
///
/// [child] is only mounted while [visible]; it is built eagerly by the caller but the
/// switcher never puts it in the tree otherwise.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.duration(context, AppMotion.medium),
    switchInCurve: AppMotion.curve,
    switchOutCurve: AppMotion.curve,
    transitionBuilder: (child, animation) => SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: FadeTransition(opacity: animation, child: child),
    ),
    // The default layout centres its children, which would slide a block in from the
    // middle of a left-aligned column.
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: AlignmentDirectional.topStart,
      children: [...previousChildren, ?currentChild],
    ),
    child: visible ? child : const SizedBox.shrink(),
  );
}
