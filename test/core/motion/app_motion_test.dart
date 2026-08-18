import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/motion/app_motion.dart';
import 'package:stingers/core/theme/app_theme.dart';

import '../../support/test_app.dart';

void main() {
  /// Reads the tokens from inside a real theme, which is the only place the cinema-mode
  /// extension exists.
  Future<({bool reduced, Duration medium})> read(
    WidgetTester tester, {
    required ThemeData theme,
    bool disableAnimations = false,
  }) async {
    late bool reduced;
    late Duration medium;

    await tester.pumpWidget(
      testApp(
        theme: theme,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Builder(
            builder: (context) {
              reduced = AppMotion.reduced(context);
              medium = AppMotion.duration(context, AppMotion.medium);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    return (reduced: reduced, medium: medium);
  }

  testWidgets('animates normally in the default dark theme', (tester) async {
    final motion = await read(tester, theme: AppTheme.dark());

    expect(motion.reduced, isFalse);
    expect(motion.medium, AppMotion.medium);
  });

  testWidgets('cinema mode suppresses motion on its own', (tester) async {
    final motion = await read(tester, theme: AppTheme.cinema());

    expect(motion.reduced, isTrue);
    // Zero, not "fast": a 40 ms fade is still light moving in a dark auditorium.
    expect(motion.medium, Duration.zero);
  });

  testWidgets('the OS reduce-motion setting suppresses motion on its own', (
    tester,
  ) async {
    final motion = await read(tester, theme: AppTheme.dark(), disableAnimations: true);

    expect(motion.reduced, isTrue);
    expect(motion.medium, Duration.zero);
  });
}
