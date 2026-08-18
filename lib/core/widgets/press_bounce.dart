import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import '../motion/app_motion.dart';

/// Swells a control slightly while it is held, and lets it spring back on release.
///
/// Scaling *up* rather than down is the iOS 26 gesture: the control grows toward the
/// finger instead of retreating from it, which reads as the thing acknowledging the
/// touch rather than being pushed away by it.
///
/// A spring rather than a fixed tween, because this animation is interrupted constantly
/// — a press released mid-swell has to reverse from wherever it currently is, and a
/// tween would restart from its own begin value and visibly jump. Damping is under 1 so
/// the release overshoots once; that single bounce is the whole effect.
class PressBounce extends StatefulWidget {
  const PressBounce({super.key, required this.child, this.scale = 1.06});

  final Widget child;

  /// Peak scale while held. Small on purpose: a control that grows visibly is a control
  /// that shifts the layout around it.
  final double scale;

  @override
  State<PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<PressBounce> with SingleTickerProviderStateMixin {
  /// Drives 0 (at rest) → 1 (fully pressed); the scale is interpolated from it.
  late final AnimationController _controller = AnimationController.unbounded(vsync: this);

  /// Critically damped on the way in — the swell should not wobble under a held finger.
  static final SpringDescription _press = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 600,
    ratio: 1,
  );

  /// Underdamped on the way out. This is the bounce.
  static final SpringDescription _release = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 420,
    ratio: 0.55,
  );

  void _animateTo(double target, SpringDescription spring) {
    if (AppMotion.reduced(context)) {
      _controller.value = target;
      return;
    }
    // From the current value and current velocity, never from a fixed start: that is
    // what makes a press cancelled mid-swell continue rather than snap.
    _controller.animateWith(
      SpringSimulation(spring, _controller.value, target, _controller.velocity),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `Listener`, not `GestureDetector`: raw pointer events never enter the gesture
    // arena, so the button underneath still wins the tap. And the response fires on
    // pointer-down — the press is the moment the user is asking for feedback, not the
    // release.
    return Listener(
      onPointerDown: (_) => _animateTo(1, _press),
      onPointerUp: (_) => _animateTo(0, _release),
      onPointerCancel: (_) => _animateTo(0, _release),
      child: AnimatedBuilder(
        animation: _controller,
        // Built once and reused: the child does not depend on the animation, only the
        // transform above it does.
        child: widget.child,
        builder: (context, child) => Transform.scale(
          scale: 1 + (widget.scale - 1) * _controller.value,
          filterQuality: FilterQuality.low,
          child: child,
        ),
      ),
    );
  }
}
