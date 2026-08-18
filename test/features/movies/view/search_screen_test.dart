import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/l10n/app_locale_controller.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/view/search_screen.dart';

import '../../../support/fake_movie_repository.dart';
import '../../../support/test_app.dart';

void main() {
  late FakeMovieRepository repository;

  setUp(() => repository = FakeMovieRepository());
  tearDown(() => repository.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    testApp(
      child: SearchScreen(repository: repository, locale: AppLocaleController()),
    ),
  );

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
  }

  testWidgets('autofocuses the search field', (tester) async {
    await pump(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.autofocus, isTrue);
  });

  testWidgets('prompts for a title before anything has been searched', (tester) async {
    await pump(tester);

    expect(find.text('Find a film to check or to vote on.'), findsOneWidget);
  });

  testWidgets('shows the results the database streams back', (tester) async {
    await pump(tester);

    await submit(tester, 'dune');
    repository.search.add([
      MovieWithStats(movie: fakeMovie(1, 'Dune'), stats: fakeStats()),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('says nothing was found for a query with no results', (tester) async {
    await pump(tester);

    await submit(tester, 'nonexistent');
    repository.search.add(const []);
    await tester.pump();
    await tester.pump();

    expect(find.text('Nothing found for “nonexistent”.'), findsOneWidget);
  });

  testWidgets('shows a retry button when the search fails outright', (tester) async {
    repository.refreshSearchFailure = const UpstreamUnavailableException('down');
    await pump(tester);

    await submit(tester, 'dune');
    await tester.pump();
    await tester.pump();

    expect(find.text('The film database is not responding right now.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('offline with nothing cached reads as empty, not broken', (tester) async {
    repository.refreshSearchFailure = const NetworkException();
    await pump(tester);

    await submit(tester, 'dune');
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Only films you have already searched for are available offline.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
  });
}
