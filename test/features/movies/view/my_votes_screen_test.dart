import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/view/my_votes_screen.dart';

import '../../../support/fake_movie_repository.dart';
import '../../../support/test_app.dart';

void main() {
  late FakeMovieRepository repository;

  MyVoteEntry entry(int id, {bool pending = false}) => MyVoteEntry(
    movie: fakeMovie(id, 'Dune'),
    vote: MyVote(
      tmdbId: id,
      hasScene: true,
      worthIt: true,
      updatedAt: DateTime(2026, 8, 15),
      pendingSync: pending,
    ),
  );

  setUp(() => repository = FakeMovieRepository());
  tearDown(() => repository.close());

  Future<void> pump(WidgetTester tester) =>
      tester.pumpWidget(testApp(child: MyVotesScreen(repository: repository)));

  testWidgets('shows the empty view before anything has been voted on', (tester) async {
    await pump(tester);
    await tester.pump();

    expect(find.text('You have not voted yet.'), findsOneWidget);
  });

  testWidgets('shows the voted films and the answers given', (tester) async {
    await pump(tester);
    repository.myVotes.add([entry(1)]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('You said: there is a scene · Worth waiting for'), findsOneWidget);
  });

  testWidgets('marks a vote still waiting to be sent', (tester) async {
    await pump(tester);
    repository.myVotes.add([entry(1, pending: true)]);
    await tester.pump();
    await tester.pump();

    expect(find.text('Waiting to be sent'), findsOneWidget);
  });
}
