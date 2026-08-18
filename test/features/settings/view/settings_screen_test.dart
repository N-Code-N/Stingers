import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stingers/core/l10n/app_locale_controller.dart';
import 'package:stingers/core/l10n/l10n.dart';
import 'package:stingers/core/router/app_routes.dart';
import 'package:stingers/core/theme/app_theme.dart';
import 'package:stingers/core/theme/cinema_mode.dart';
import 'package:stingers/features/settings/view/settings_screen.dart';

import '../../../support/test_app.dart';

void main() {
  late CinemaMode cinemaMode;
  late AppLocaleController locale;
  late List<bool> persisted;

  setUp(() {
    persisted = [];
    cinemaMode = CinemaMode(persist: (value) async => persisted.add(value));
    locale = AppLocaleController();
  });

  tearDown(() {
    cinemaMode.dispose();
    locale.dispose();
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    testApp(
      child: SettingsScreen(cinemaMode: cinemaMode, locale: locale),
    ),
  );

  testWidgets('the cinema mode switch reflects the current state', (tester) async {
    await pump(tester);

    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isFalse);
  });

  testWidgets('toggling the switch enables cinema mode', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();

    expect(cinemaMode.enabled, isTrue);
    expect(persisted, [true]);
    final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(tile.value, isTrue);
  });

  testWidgets(
    'the language menu keeps only explicit choices and keeps the current value visible',
    (tester) async {
      await pump(tester);

      await tester.tap(find.byType(PopupMenuButton<Locale?>));
      await tester.pumpAndSettle();

      expect(find.byType(PopupMenuItem<Locale>), findsNWidgets(2));
      expect(find.text('System language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Русский'), findsOneWidget);
    },
  );

  testWidgets('tapping "My votes" navigates to the votes screen', (tester) async {
    final router = GoRouter(
      initialLocation: AppPath.settings,
      routes: [
        GoRoute(
          path: AppPath.settings,
          name: AppRoute.settings,
          builder: (context, state) =>
              SettingsScreen(cinemaMode: cinemaMode, locale: locale),
          routes: [
            GoRoute(
              path: AppPath.myVotes,
              name: AppRoute.myVotes,
              builder: (context, state) => const Scaffold(body: Text('my votes screen')),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.dark(),
      ),
    );

    await tester.tap(find.text('My votes'));
    await tester.pumpAndSettle();

    expect(find.text('my votes screen'), findsOneWidget);
  });
}
