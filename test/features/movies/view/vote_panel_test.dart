import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/features/movies/data/movie_models.dart';
import 'package:stingers/features/movies/view/widgets/vote_panel.dart';

import '../../../support/test_app.dart';

void main() {
  MyVote vote({required bool hasScene, bool? worthIt, bool pending = false}) => MyVote(
    tmdbId: 7,
    hasScene: hasScene,
    worthIt: worthIt,
    updatedAt: DateTime(2026, 8, 15),
    pendingSync: pending,
  );

  Future<void> pump(
    WidgetTester tester, {
    MyVote? current,
    void Function(bool)? onHasScene,
    void Function(bool)? onWorthIt,
  }) => tester.pumpWidget(
    testApp(
      child: Scaffold(
        body: VotePanel(
          vote: current,
          onHasScene: onHasScene ?? (_) {},
          onWorthIt: onWorthIt ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('asks only the first question before anyone has answered', (tester) async {
    await pump(tester);

    expect(
      find.text('Did this film have a scene during or after the credits?'),
      findsOneWidget,
    );
    expect(find.text('Was it worth waiting for?'), findsNothing);
  });

  testWidgets('asks the second question once the first is yes', (tester) async {
    await pump(tester, current: vote(hasScene: true));

    expect(find.text('Was it worth waiting for?'), findsOneWidget);
  });

  testWidgets('never asks whether a scene that does not exist was worth it', (
    tester,
  ) async {
    await pump(tester, current: vote(hasScene: false));

    expect(find.text('Was it worth waiting for?'), findsNothing);
  });

  testWidgets('reports the answer to the first question', (tester) async {
    final answers = <bool>[];
    await pump(tester, onHasScene: answers.add);

    await tester.tap(find.text('Yes, there was'));

    expect(answers, [true]);
  });

  testWidgets('reports the answer to the second question', (tester) async {
    final answers = <bool>[];
    await pump(tester, current: vote(hasScene: true), onWorthIt: answers.add);

    await tester.tap(find.text('Not worth it'));

    expect(answers, [false]);
  });

  testWidgets('shows which answer is already selected', (tester) async {
    await pump(tester, current: vote(hasScene: true, worthIt: true));

    // The selected answer is the filled button; the other stays outlined.
    expect(
      find.ancestor(of: find.text('Yes, there was'), matching: find.byType(FilledButton)),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text("No, there wasn't"),
        matching: find.byType(OutlinedButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('stays tappable while a vote is in flight', (tester) async {
    // The vote is written locally before the network is touched, so the answer on
    // screen is already final. Disabling the buttons for the round trip would make the
    // user wait for something that has already happened — and would drop the second
    // answer of anyone who taps both questions quickly.
    final answers = <bool>[];
    await pump(tester, onHasScene: answers.add);

    await tester.tap(find.text('Yes, there was'));
    await tester.tap(find.text("No, there wasn't"));

    expect(answers, [true, false]);
  });
}
