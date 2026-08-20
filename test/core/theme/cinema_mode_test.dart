import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/theme/app_theme.dart';
import 'package:stingers/core/theme/cinema_mode.dart';

class RecordingDimmer implements ScreenDimmer {
  final List<String> calls = [];

  @override
  Future<void> dim(double level) async => calls.add('dim($level)');

  @override
  Future<void> restore() async => calls.add('restore');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecordingDimmer dimmer;
  late List<bool> persisted;

  CinemaMode build({bool initialEnabled = false}) => CinemaMode(
    initialEnabled: initialEnabled,
    persist: (value) async => persisted.add(value),
    dimmer: dimmer,
  );

  setUp(() {
    dimmer = RecordingDimmer();
    persisted = [];
  });

  test('is off by default and uses the near-black palette', () {
    final mode = build();

    expect(mode.enabled, isFalse);
    expect(mode.theme.scaffoldBackgroundColor, AppPalette.dark.background);
    expect(dimmer.calls, isEmpty);

    mode.dispose();
  });

  test('turning it on dims the backlight and persists the choice', () async {
    final mode = build();

    await mode.setEnabled(true);

    expect(mode.enabled, isTrue);
    expect(mode.theme.scaffoldBackgroundColor, const Color(0xFF000000));
    expect(persisted, [true]);
    expect(dimmer.calls, ['dim(${CinemaMode.dimLevel})']);

    mode.dispose();
  });

  test('turning it off restores the backlight', () async {
    final mode = build(initialEnabled: true);
    dimmer.calls.clear();

    await mode.setEnabled(false);

    expect(dimmer.calls, ['restore']);
    expect(persisted, [false]);

    mode.dispose();
  });

  test('notifies listeners so the theme swaps without a restart', () async {
    final mode = build();
    var notifications = 0;
    mode.addListener(() => notifications++);

    await mode.setEnabled(true);

    expect(notifications, 1);

    mode.dispose();
  });

  test('setting the same value again does nothing', () async {
    final mode = build();

    await mode.setEnabled(false);

    expect(persisted, isEmpty);
    expect(dimmer.calls, isEmpty);

    mode.dispose();
  });

  test('restores the backlight when the app goes to the background', () {
    // Without this, the user walks out of the cinema with a phone stuck at 5%.
    final mode = build(initialEnabled: true);
    dimmer.calls.clear();

    mode.didChangeAppLifecycleState(AppLifecycleState.paused);

    expect(dimmer.calls, ['restore']);

    mode.dispose();
  });

  test('dims again when the app comes back', () {
    final mode = build(initialEnabled: true);
    mode.didChangeAppLifecycleState(AppLifecycleState.paused);
    dimmer.calls.clear();

    mode.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(dimmer.calls, ['dim(${CinemaMode.dimLevel})']);

    mode.dispose();
  });

  test('leaves the backlight alone when it is switched off', () {
    final mode = build();

    mode.didChangeAppLifecycleState(AppLifecycleState.paused);
    mode.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(dimmer.calls, isEmpty);

    mode.dispose();
  });

  test('restores the backlight on disposal', () {
    final mode = build(initialEnabled: true);
    dimmer.calls.clear();

    mode.dispose();

    expect(dimmer.calls, ['restore']);
  });

  test('forces reduced motion in cinema mode', () async {
    // Asserted through the theme because that is the only way a widget can read it.
    final mode = build();
    expect(mode.theme.extension<CinemaExtras>()!.reduceMotion, isFalse);

    await mode.setEnabled(true);
    expect(mode.theme.extension<CinemaExtras>()!.reduceMotion, isTrue);

    mode.dispose();
  });
}
