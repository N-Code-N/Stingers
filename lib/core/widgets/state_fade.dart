import 'package:flutter/widgets.dart';

import '../motion/app_motion.dart';

/// Cross-fades between a screen's states — loading, error, empty, content.
///
/// Every screen in the app is a `ListenableBuilder` returning one of four widgets, and
/// without this the spinner is replaced by a full list between two frames. That hard cut
/// is the most-seen animation in the app, so it is the one worth getting right.
///
/// **Callers must key each state**, because that is what tells one state from another;
/// two `ListView`s under the same key are the same widget and must not cross-fade, and
/// re-keying the content on every rebuild would restart the list's scroll position.
class StateFade extends StatelessWidget {
  const StateFade({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppMotion.duration(context, AppMotion.medium),
    switchInCurve: AppMotion.curve,
    switchOutCurve: AppMotion.curve,
    // The default layout builder centres the children in a `Stack`, which would take a
    // top-aligned list and float it in the middle of the screen while it fades.
    layoutBuilder: (currentChild, previousChildren) => Stack(
      alignment: AlignmentDirectional.topStart,
      children: [...previousChildren, ?currentChild],
    ),
    child: child,
  );
}
