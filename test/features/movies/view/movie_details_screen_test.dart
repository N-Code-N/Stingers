import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/l10n/app_locale_controller.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/data/movie_repository.dart';
import 'package:stingers/features/movies/view/movie_details_screen.dart';

import '../../../support/fake_movie_repository.dart';
import '../../../support/test_app.dart';

void main() {
  late FakeMovieRepository repository;

  MovieDetails details({MyVote? vote, SceneStats? stats}) => MovieDetails(
    movie: fakeMovie(7, 'Dune'),
    stats: stats ?? SceneStats.empty,
    myVote: vote,
    detailsFetchedAt: DateTime(2026, 8, 15),
  );

  setUp(() => repository = FakeMovieRepository());
  tearDown(() => repository.close());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    testApp(
      child: MovieDetailsScreen(
        tmdbId: 7,
        repository: repository,
        locale: AppLocaleController(),
      ),
    ),
  );

  testWidgets('forces a locale refresh when the app language changes', (tester) async {
    final locale = AppLocaleController();
    await tester.pumpWidget(
      testApp(
        child: MovieDetailsScreen(tmdbId: 7, repository: repository, locale: locale),
      ),
    );

    expect(repository.refreshMovieCalls, 1);
    expect(repository.forcedRefreshMovieCalls, 1);

    locale.setLocale(const Locale('ru'));
    await tester.pump();
    await tester.pump();

    expect(repository.refreshMovieCalls, 2);
    expect(repository.forcedRefreshMovieCalls, 2);
  });

  testWidgets('uses the low-vote hint wording for the first-to-say CTA', (tester) async {
    await tester.pumpWidget(
      testApp(
        locale: const Locale('ru'),
        child: MovieDetailsScreen(
          tmdbId: 7,
          repository: repository,
          locale: AppLocaleController(),
        ),
      ),
    );

    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: '...',
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 15),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Скажите одним из первых — это одно касание.'), findsOneWidget);
  });

  testWidgets('never renders the outgoing overview while the new locale is loading', (
    tester,
  ) async {
    final locale = AppLocaleController();
    const oldOverview = 'A desert empire finds its destiny.';
    const newOverview = 'Пустынная империя находит своё предназначение.';

    await tester.pumpWidget(
      testApp(
        locale: const Locale('en'),
        child: MovieDetailsScreen(tmdbId: 7, repository: repository, locale: locale),
      ),
    );

    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: oldOverview,
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 15),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(oldOverview), findsOneWidget);

    locale.setLocale(const Locale('ru'));
    await tester.pump();
    expect(find.text(oldOverview), findsNothing);
    expect(find.text(newOverview), findsNothing);

    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: newOverview,
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 16),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(oldOverview), findsNothing);
    expect(find.text(newOverview), findsOneWidget);
  });

  testWidgets('shows a spinner before the film has loaded', (tester) async {
    await pump(tester);

    expect(find.byKey(const ValueKey('loading')), findsOneWidget);
  });

  testWidgets('shows a retry button when loading fails with nothing cached', (
    tester,
  ) async {
    repository.refreshMovieFailure = const NetworkException();
    await pump(tester);
    await tester.pump();

    expect(find.byKey(const ValueKey('error')), findsOneWidget);
    expect(find.text('No connection.'), findsOneWidget);
  });

  testWidgets('shows the verdict, the vote panel and the film once loaded', (
    tester,
  ) async {
    await pump(tester);
    repository.movie.add(details());
    await tester.pump();
    await tester.pump();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Not enough votes yet'), findsOneWidget);
    expect(find.text('Did this film have a scene after the credits?'), findsOneWidget);
  });

  testWidgets('grows the description in when it arrives after the page opened', (
    tester,
  ) async {
    const overview = 'A desert empire finds its destiny.';
    Size revealed() => tester.getSize(
      find.ancestor(of: find.text(overview), matching: find.byType(SizeTransition)).first,
    );

    await pump(tester);

    // First emit: the film is known from a list read, so there is no description yet.
    repository.movie.add(
      MovieDetails(
        movie: fakeMovie(7, 'Dune'),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: null,
      ),
    );
    await tester.pump();
    expect(find.text(overview), findsNothing);

    // The details read lands. The block must grow into the layout rather than appear
    // between two frames and shove the page down.
    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: overview,
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 15),
      ),
    );
    await tester.pump();
    expect(revealed().height, 0);

    await tester.pumpAndSettle();
    expect(revealed().height, greaterThan(0));
    expect(find.text(overview), findsOneWidget);
  });

  testWidgets('keeps old overview text hidden until the new localized one is ready', (
    tester,
  ) async {
    final locale = AppLocaleController();
    const englishText = 'A desert empire finds its destiny.';
    const russianText = 'Пустынная империя находит своё предназначение.';

    await tester.pumpWidget(
      testApp(
        locale: locale.locale ?? const Locale('en'),
        child: MovieDetailsScreen(tmdbId: 7, repository: repository, locale: locale),
      ),
    );

    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: englishText,
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 15),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text(englishText), findsOneWidget);

    locale.setLocale(const Locale('ru'));
    await tester.pump();

    expect(find.text(englishText), findsNothing);
    expect(find.text(russianText), findsNothing);

    repository.movie.add(
      MovieDetails(
        movie: Movie(
          tmdbId: 7,
          title: 'Dune',
          posterPath: null,
          releaseDate: null,
          originalTitle: '',
          overview: russianText,
        ),
        stats: SceneStats.empty,
        myVote: null,
        detailsFetchedAt: DateTime(2026, 8, 16),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text(englishText), findsNothing);
    expect(find.text(russianText), findsOneWidget);
  });

  testWidgets('tapping a vote choice sends it through the repository', (tester) async {
    await pump(tester);
    repository.movie.add(details());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Yes, there was'));
    await tester.pump();
    await tester.pump();

    expect(repository.castVotes.single.tmdbId, 7);
    expect(repository.castVotes.single.hasScene, isTrue);
  });

  testWidgets('a queued vote tells the user it will be sent later', (tester) async {
    repository.castVoteOutcome = VoteOutcome.queued;
    await pump(tester);
    repository.movie.add(details());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Yes, there was'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Saved. It will be sent when you are back online.'), findsOneWidget);
  });

  testWidgets('a rejected vote is reported without losing the film', (tester) async {
    repository.castVoteFailure = const VoteRejectedException('rate limited');
    await pump(tester);
    repository.movie.add(details());
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Yes, there was'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Your vote was not counted. Try again in a little while.'),
      findsOneWidget,
    );
    expect(find.text('Dune'), findsOneWidget);
  });
}
