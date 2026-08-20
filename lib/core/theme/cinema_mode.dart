import 'package:flutter/material.dart' show ThemeData;
import 'package:flutter/widgets.dart';
import 'package:screen_brightness/screen_brightness.dart';

import 'app_theme.dart';

/// The screen backlight, behind an interface so the toggle is testable without a device.
abstract interface class ScreenDimmer {
  Future<void> dim(double level);
  Future<void> restore();
}

class PlatformScreenDimmer implements ScreenDimmer {
  const PlatformScreenDimmer();

  @override
  Future<void> dim(double level) =>
      _quietly(() => ScreenBrightness.instance.setApplicationScreenBrightness(level));

  @override
  Future<void> restore() =>
      _quietly(() => ScreenBrightness.instance.resetApplicationScreenBrightness());

  /// The brightness APIs throw on simulators and on platforms without the capability.
  /// Cinema mode still works there — the palette does most of the job — so a failure to
  /// reach the backlight must not take the toggle down with it.
  static Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('screen brightness unavailable: $e');
    }
  }
}

/// Cinema mode: true black plus a dimmed backlight, for someone sitting in a dark
/// auditorium.
///
/// It is a **toggle**, never a sensor heuristic. Guessing "they are in a cinema" from
/// ambient light and silently dimming the screen is a hostile surprise.
///
/// A composition-root singleton because more than one place consumes it: `MaterialApp`
/// picks the theme from it, and the movie screen owns the switch.
class CinemaMode extends ChangeNotifier with WidgetsBindingObserver {
  CinemaMode({
    required Future<void> Function(bool enabled) persist,
    bool initialEnabled = false,
    ScreenDimmer dimmer = const PlatformScreenDimmer(),
  }) : _persist = persist,
       _enabled = initialEnabled,
       _dimmer = dimmer {
    WidgetsBinding.instance.addObserver(this);
    if (_enabled) _dimmer.dim(dimLevel);
  }

  /// Low enough to stop being a light source for the row behind, high enough that amber
  /// at 11:1 contrast is still readable.
  static const double dimLevel = 0.05;

  final Future<void> Function(bool enabled) _persist;
  final ScreenDimmer _dimmer;

  bool _enabled;
  bool get enabled => _enabled;

  /// The whole of what this mode exposes: the palette and the reduce-motion flag reach
  /// widgets through the theme and its `CinemaExtras` extension, never off this object,
  /// so nothing has to reach for the toggle to find out how to paint itself.
  ThemeData get theme => _enabled ? AppTheme.cinema() : AppTheme.dark();

  Future<void> setEnabled(bool value) async {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
    await _persist(value);
    await (value ? _dimmer.dim(dimLevel) : _dimmer.restore());
  }

  /// Restoring the backlight is not optional. Without this the user walks out of the
  /// cinema with a phone stuck at 5% and no idea why.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_enabled) return;
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _dimmer.restore();
      case AppLifecycleState.resumed:
        _dimmer.dim(dimLevel);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_enabled) _dimmer.restore();
    super.dispose();
  }
}
