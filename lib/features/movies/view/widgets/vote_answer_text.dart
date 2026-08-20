import '../../../../core/l10n/l10n.dart';
import '../../data/movie_models.dart';

/// The user's own answer as one readable line: "You said: there is a scene · Worth
/// waiting for".
///
/// Shared because two screens say the same sentence — the vote history lists it under
/// every film, and the film's own card falls back to it while the crowd has not reached
/// a verdict. One place means the two cannot drift into wording each other differently.
String describeOwnVote(AppLocalizations l10n, MyVote vote) {
  final answer = vote.hasScene ? l10n.voteAnswerSceneYes : l10n.voteAnswerSceneNo;
  final worth = switch (vote.worthIt) {
    true => l10n.voteAnswerWorthYes,
    false => l10n.voteAnswerWorthNo,
    null => null,
  };
  return worth == null ? answer : '$answer · $worth';
}
