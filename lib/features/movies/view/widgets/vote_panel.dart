import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/press_bounce.dart';
import '../../../../core/widgets/reveal.dart';
import '../../data/movie_models.dart';

/// The two questions, asked in order.
///
/// The second one only appears once the first is answered "yes" — asking whether a scene
/// that does not exist was worth waiting for is the same nonsense the database's
/// `worth_it_only_with_scene` constraint refuses.
///
/// Nothing here is disabled while a vote is in flight. The vote is written to the local
/// database before the network is touched, so what is on screen is already the answer;
/// greying the buttons out for the two round trips it takes to reach the server would be
/// making the user wait for something that has already happened.
class VotePanel extends StatelessWidget {
  const VotePanel({
    super.key,
    required this.vote,
    required this.onHasScene,
    required this.onWorthIt,
  });

  final MyVote? vote;
  final ValueChanged<bool> onHasScene;
  final ValueChanged<bool> onWorthIt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final current = vote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.detailsVoteQuestion, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        _Choice(
          yesLabel: l10n.detailsVoteYes,
          noLabel: l10n.detailsVoteNo,
          selected: current?.hasScene,
          onSelected: onHasScene,
        ),
        // Answering "yes" is what makes the second question exist, so it grows in rather
        // than appearing between two frames and shoving the page down.
        Reveal(
          visible: current?.hasScene ?? false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(l10n.detailsWorthQuestion, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _Choice(
                yesLabel: l10n.detailsWorthYesAction,
                noLabel: l10n.detailsWorthNoAction,
                selected: current?.worthIt,
                onSelected: onWorthIt,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.yesLabel,
    required this.noLabel,
    required this.selected,
    required this.onSelected,
  });

  final String yesLabel;
  final String noLabel;
  final bool? selected;
  final ValueChanged<bool> onSelected;

  void _select(bool answer) {
    // The vote is a round trip that may take a second or queue offline; the tick is the
    // app confirming it heard the tap, before anything else can.
    HapticFeedback.selectionClick();
    onSelected(answer);
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ChoiceButton(
          label: yesLabel,
          isSelected: selected == true,
          onPressed: () => _select(true),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _ChoiceButton(
          label: noLabel,
          isSelected: selected == false,
          onPressed: () => _select(false),
        ),
      ),
    ],
  );
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressBounce(
    child: isSelected
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton(onPressed: onPressed, child: Text(label)),
  );
}
