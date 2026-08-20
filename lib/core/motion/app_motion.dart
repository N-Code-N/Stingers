import 'package:flutter/widgets.dart';

import '../theme/app_theme.dart';

/// Motion tokens, and the one rule that governs every animation in the app.
///
/// **Cinema mode or the OS "Reduce Motion" setting collapses every duration to zero.**
/// Either alone is enough. Motion in a dark auditorium is light travelling across a
/// screen other people can see, which is the same reason the palette is warm and the
/// page transition is a cross-fade — see [CinemaExtras.reduceMotion].
///
/// The durations are short on purpose. This app is used one-handed, in the dark, for two
/// seconds at a time; an animation long enough to be admired is an animation in the way.
abstract final class AppMotion {
  /// The default: state cross-fades, revealing a follow-up question, a badge changing.
  static const Duration medium = Duration(milliseconds: 240);

  /// Reserved for something that changes meaning — a verdict appearing or flipping.
  static const Duration long = Duration(milliseconds: 420);

  /// Decelerating, no overshoot. Content arriving at rest, not bouncing into place.
  static const Curve curve = Curves.easeOutCubic;

  /// True when motion must be suppressed, for either of the two reasons above.
  ///
  /// `disableAnimationsOf`, not `MediaQuery.of(context).disableAnimations`: the scoped
  /// accessor does not rebuild every subscriber when an unrelated media query changes.
  static bool reduced(BuildContext context) =>
      CinemaExtras.of(context).reduceMotion || MediaQuery.disableAnimationsOf(context);

  /// A duration honouring [reduced]. Zero is the correct fallback rather than "fast":
  /// a 40 ms fade is still a fade, and the setting asks for none.
  static Duration duration(BuildContext context, Duration value) =>
      reduced(context) ? Duration.zero : value;
}
