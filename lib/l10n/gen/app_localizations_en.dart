// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Stingers';

  @override
  String get navSearch => 'Search';

  @override
  String get navMyVotes => 'My votes';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonClose => 'Close';

  @override
  String get errorGeneric => 'Something went wrong.';

  @override
  String get errorOffline => 'No connection.';

  @override
  String get errorNotFound => 'Not found.';

  @override
  String get errorSession =>
      'Could not start a session. Check your connection and try again.';

  @override
  String get errorUpstream => 'The film database is not responding right now.';

  @override
  String get errorVoteRejected =>
      'Your vote was not counted. Try again in a little while.';

  @override
  String get errorNotConfigured =>
      'The app was built without a backend. Pass SUPABASE_URL and SUPABASE_ANON_KEY.';

  @override
  String get feedEmpty => 'Nothing is playing right now.';

  @override
  String get feedEmptyOffline =>
      'Nothing has been downloaded yet. Connect once to fill the feed.';

  @override
  String feedStale(String time) {
    return 'Data from $time';
  }

  @override
  String get badgeScene => 'Scene';

  @override
  String get badgeNoScene => 'No scene';

  @override
  String get badgeUnknown => 'Unknown';

  @override
  String get detailsSceneYes => 'There is a scene';

  @override
  String get detailsSceneNo => 'No scene';

  @override
  String get detailsSceneUnknown => 'Not enough votes yet';

  @override
  String get detailsSceneUnknownHint => 'Say one of the first — it takes one tap.';

  @override
  String detailsSceneConfidence(int percent) {
    return '$percent% of voters agree';
  }

  @override
  String get detailsWorthYes => 'Worth waiting for';

  @override
  String get detailsWorthNo => 'Not worth waiting for';

  @override
  String detailsWorthConfidence(int percent) {
    return '$percent% of those who saw it';
  }

  @override
  String get detailsVoteQuestion =>
      'Did this film have a scene during or after the credits?';

  @override
  String get detailsVoteYes => 'Yes, there was';

  @override
  String get detailsVoteNo => 'No, there wasn\'t';

  @override
  String get detailsWorthQuestion => 'Was it worth waiting for?';

  @override
  String get detailsWorthYesAction => 'Worth it';

  @override
  String get detailsWorthNoAction => 'Not worth it';

  @override
  String get detailsVoteQueued => 'Saved. It will be sent when you are back online.';

  @override
  String get detailsOverview => 'About the film';

  @override
  String get searchHint => 'Film title';

  @override
  String get searchPrompt => 'Find a film to check or to vote on.';

  @override
  String searchEmpty(String query) {
    return 'Nothing found for “$query”.';
  }

  @override
  String get searchEmptyOffline =>
      'Only films you have already searched for are available offline.';

  @override
  String get myVotesEmpty => 'You have not voted yet.';

  @override
  String get myVotesEmptyHint =>
      'Open a film and say whether it has a scene during or after the credits.';

  @override
  String get myVotesPending => 'Waiting to be sent';

  @override
  String get voteAnswerSceneYes => 'You said: there is a scene';

  @override
  String get voteAnswerSceneNo => 'You said: no scene';

  @override
  String get voteAnswerWorthYes => 'Worth waiting for';

  @override
  String get voteAnswerWorthNo => 'Not worth waiting for';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCinemaMode => 'Cinema mode';

  @override
  String get settingsCinemaModeHint =>
      'True black and a dimmed screen, for a dark auditorium.';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsMyVotes => 'My votes';

  @override
  String get settingsMyVotesHint => 'Everything you have voted on.';

  @override
  String get aboutTmdbAttribution =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
}
