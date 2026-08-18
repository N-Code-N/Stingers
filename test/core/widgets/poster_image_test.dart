import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/theme/app_theme.dart';
import 'package:stingers/core/widgets/poster_image.dart';

import '../../support/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required ThemeData theme}) => tester.pumpWidget(
    testApp(
      theme: theme,
      child: const Scaffold(body: PosterImage(path: null, width: 88, height: 132)),
    ),
  );

  /// The colours actually painted by every `ColoredBox` in the subtree.
  List<Color> paintedColours(WidgetTester tester) => tester
      .widgetList<ColoredBox>(find.byType(ColoredBox))
      .map((box) => box.color)
      .toList();

  testWidgets('a missing poster is a dark box, never a light placeholder', (
    tester,
  ) async {
    await pump(tester, theme: AppTheme.dark());

    // `cached_network_image` defaults to a light placeholder; a poster resolving over
    // one is a white flash in a dark auditorium.
    for (final colour in paintedColours(tester)) {
      expect(colour, isNot(const Color(0xFFFFFFFF)));
      expect(colour.computeLuminance(), lessThan(0.1));
    }
  });

  testWidgets('cinema mode lays black over the poster', (tester) async {
    await pump(tester, theme: AppTheme.cinema());

    final veil = paintedColours(tester).where((c) => c.a > 0 && c.a < 1).toList();

    expect(veil, hasLength(1));
    expect(veil.single.a, AppPalette.cinema.posterVeil);
  });

  testWidgets('dark mode leaves the poster alone', (tester) async {
    await pump(tester, theme: AppTheme.dark());

    expect(paintedColours(tester).where((c) => c.a > 0 && c.a < 1), isEmpty);
  });
}
