import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/l10n/app_locale_controller.dart';
import 'package:stingers/core/l10n/l10n.dart';
import 'package:stingers/core/router/app_routes.dart';
import 'package:stingers/core/theme/app_theme.dart';
import 'package:stingers/features/movies/view/now_playing_screen.dart';

import '../../../support/fake_movie_repository.dart';
import '../../../support/test_app.dart';

void main() {
  late FakeMovieRepository repository;

  setUp(() => repository = FakeMovieRepository());
  tearDown(() => repository.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    testApp(child: NowPlayingScreen(repository: repository, locale: AppLocaleController())),
  );

  testWidgets('shows a spinner before the feed has loaded', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
  });

  testWidgets('shows the empty view once an empty feed has loaded', (tester) async {
    await pump(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('empty')), findsOneWidget);
    expect(find.text('Nothing is playing right now.'), findsOneWidget);
  });

  testWidgets('shows a retry button when loading fails with nothing cached', (
    tester,
  ) async {
    repository.refreshFeedFailure = const NetworkException();
    await pump(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('error')), findsOneWidget);
    expect(find.text('No connection.'), findsOneWidget);

    repository.refreshFeedFailure = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(repository.refreshFeedCalls, 2);
  });

  testWidgets('shows the loaded films by title', (tester) async {
    await pump(tester);
    await tester.pump();
    repository.feed.add(fakeFeed([fakeMovie(1, 'Dune'), fakeMovie(2, 'Arrival')]));
    await tester.pump();
    await tester.pump();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Arrival'), findsOneWidget);
  });

  Widget routedApp({required Widget destination, required String routeName}) {
    final router = GoRouter(
      initialLocation: AppPath.feed,
      routes: [
        GoRoute(
          path: AppPath.feed,
          name: AppRoute.feed,
          builder: (context, state) =>
              NowPlayingScreen(repository: repository, locale: AppLocaleController()),
          routes: [
            GoRoute(
              path: routeName == AppRoute.settings ? AppPath.settings : AppPath.search,
              name: routeName,
              builder: (context, state) => destination,
            ),
          ],
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.dark(),
    );
  }

  testWidgets('the settings button opens settings', (tester) async {
    await tester.pumpWidget(
      routedApp(
        destination: const Scaffold(body: Text('settings screen')),
        routeName: AppRoute.settings,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('settings screen'), findsOneWidget);
  });

  testWidgets('the search button opens search', (tester) async {
    await tester.pumpWidget(
      routedApp(
        destination: const Scaffold(body: Text('search screen')),
        routeName: AppRoute.search,
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    expect(find.text('search screen'), findsOneWidget);
  });
}
