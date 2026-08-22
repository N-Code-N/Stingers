import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/view/widgets/verdict_panel.dart';

import '../../../support/test_app.dart';

void main() {
  SceneStats stats({
    double total = 0,
    double scene = 0,
    double worth = 0,
    double worthTotal = 0,
  }) => SceneStats(
    rawVotes: total.round(),
    totalWeight: total,
    sceneWeight: scene,
    worthWeight: worth,
    worthTotal: worthTotal,
  );

  Future<void> pump(
    WidgetTester tester,
    SceneStats value, {
    Locale? locale,
    MyVote? myVote,
  }) => tester.pumpWidget(
    testApp(
      locale: locale ?? const Locale('en'),
      child: Scaffold(
        body: VerdictPanel(stats: value, myVote: myVote),
      ),
    ),
  );

  MyVote ownVote({required bool hasScene, bool? worthIt}) => MyVote(
    tmdbId: 1,
    hasScene: hasScene,
    worthIt: worthIt,
    updatedAt: DateTime(2026, 8, 20),
  );

  testWidgets('says nothing when there are too few votes to say it', (tester) async {
    // One ordinary voter: 0.3 of weight, under the threshold.
    await pump(tester, stats(total: 0.3, scene: 0.3));

    expect(find.text('Not enough votes yet'), findsOneWidget);
    // Crucially, no percentage: a number derived from two votes is worse than none.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('answers the voter with their own answer, not another invitation', (
    tester,
  ) async {
    // One unattested vote weighs 0.12 and cannot reach the 0.75 threshold on its own, so
    // the card still has no verdict — but it must not keep asking someone who has already
    // answered to be one of the first.
    await pump(
      tester,
      stats(total: 0.12, scene: 0.12),
      myVote: ownVote(hasScene: true, worthIt: true),
    );

    expect(find.text('Not enough votes yet'), findsOneWidget);
    expect(find.text('You said: there is a scene · Worth waiting for'), findsOneWidget);
    expect(find.text('Say one of the first — it takes one tap.'), findsNothing);
    // Still no percentage: their own answer is not a crowd verdict.
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('still invites a vote from someone who has not given one', (tester) async {
    await pump(tester, stats(total: 0.12, scene: 0.12));

    expect(find.text('Say one of the first — it takes one tap.'), findsOneWidget);
  });

  testWidgets('states the verdict and the confidence behind it', (tester) async {
    await pump(tester, stats(total: 14, scene: 12));

    expect(find.text('There is a scene'), findsOneWidget);
    expect(find.text('86% of voters agree'), findsOneWidget);
  });

  testWidgets('states the negative verdict with the share backing it', (tester) async {
    await pump(tester, stats(total: 14, scene: 2));

    expect(find.text('No scene'), findsOneWidget);
    expect(find.text('86% of voters agree'), findsOneWidget);
  });

  testWidgets('asks the second question only when there was a scene', (tester) async {
    await pump(tester, stats(total: 14, scene: 12, worth: 7, worthTotal: 11));

    expect(find.text('Worth waiting for'), findsOneWidget);
    expect(find.text('64% of those who saw it'), findsOneWidget);
  });

  testWidgets('has no worth-it verdict when too few people answered', (tester) async {
    // Plenty of weight on "is there a scene", almost none on "was it worth it".
    await pump(tester, stats(total: 14, scene: 12, worth: 0.3, worthTotal: 0.3));

    expect(find.text('Worth waiting for'), findsNothing);
    expect(find.text('Not worth waiting for'), findsNothing);
  });

  testWidgets('renders the verdict in Russian', (tester) async {
    await pump(tester, stats(total: 14, scene: 12), locale: const Locale('ru'));

    expect(find.text('Сцена есть'), findsOneWidget);
    expect(find.text('86% проголосовавших согласны'), findsOneWidget);
  });

  testWidgets('never puts a number of votes next to the percentage', (tester) async {
    // The figures behind the percentage are sums of trust weight, not people. Any count
    // derived from them would be a wrong number stated to the user as a fact — with
    // attestation unavailable every device weighs 0.3, so 47 voters would read as "14".
    await pump(tester, stats(total: 14, scene: 12));

    expect(find.text('86% of voters agree'), findsOneWidget);
    // 14 is the summed weight. It is not a number of people and must never be shown
    // beside the percentage as if it were.
    expect(find.textContaining('14'), findsNothing);
  });

  testWidgets('the verdict outweighs its supporting detail visually', (tester) async {
    await pump(tester, stats(total: 14, scene: 12));

    final headline = tester.widget<Text>(find.text('There is a scene'));
    final detail = tester.widget<Text>(find.text('86% of voters agree'));

    expect(
      headline.style!.fontSize!,
      greaterThan(detail.style!.fontSize! * 1.5),
      reason: 'the answer must be readable at a glance, in the dark',
    );
  });
}
