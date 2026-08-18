import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'press_bounce.dart';

/// A round control that floats over content instead of sitting in a bar.
///
/// The app has no app bar on its main screen: one icon does not justify a strip across
/// the top, and every pixel of chrome is lit. These float over the list instead, blurred
/// so the posters behind them read as depth rather than as noise under the glyph.
///
/// In cinema mode the blur is dropped and the surface goes opaque. There is nothing to
/// blur over true black, and `BackdropFilter` forces an offscreen render pass per frame
/// it is on screen — paying for that to composite black over black is the definition of
/// wasted battery in a dark room.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 52,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// 52 is the same minimum tap target the vote buttons use — one-handed, in the dark.
  final double size;

  static const double _blurSigma = 18;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCinema = CinemaExtras.of(context).reduceMotion;

    final surface = Material(
      color: isCinema
          ? colors.surfaceContainerHigh
          : colors.surfaceContainerHigh.withValues(alpha: 0.55),
      shape: CircleBorder(
        side: BorderSide(color: colors.outline.withValues(alpha: isCinema ? 1 : 0.8)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: colors.primary, size: size * 0.44),
        ),
      ),
    );

    return PressBounce(
      child: Tooltip(
        message: tooltip,
        child: ClipOval(
          // The clip is not decoration: an unclipped `BackdropFilter` samples the whole
          // layer beneath it, not just what shows through the circle.
          child: isCinema
              ? surface
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
                  child: surface,
                ),
        ),
      ),
    );
  }
}
