import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Stingers'**
  String get appTitle;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navMyVotes.
  ///
  /// In en, this message translates to:
  /// **'My votes'**
  String get navMyVotes;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get errorGeneric;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection.'**
  String get errorOffline;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get errorNotFound;

  /// No description provided for @errorSession.
  ///
  /// In en, this message translates to:
  /// **'Could not start a session. Check your connection and try again.'**
  String get errorSession;

  /// No description provided for @errorUpstream.
  ///
  /// In en, this message translates to:
  /// **'The film database is not responding right now.'**
  String get errorUpstream;

  /// No description provided for @errorVoteRejected.
  ///
  /// In en, this message translates to:
  /// **'Your vote was not counted. Try again in a little while.'**
  String get errorVoteRejected;

  /// No description provided for @errorNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'The app was built without a backend. Pass SUPABASE_URL and SUPABASE_ANON_KEY.'**
  String get errorNotConfigured;

  /// No description provided for @feedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing right now.'**
  String get feedEmpty;

  /// No description provided for @feedEmptyOffline.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been downloaded yet. Connect once to fill the feed.'**
  String get feedEmptyOffline;

  /// Banner shown when the feed is being served from the cache
  ///
  /// In en, this message translates to:
  /// **'Data from {time}'**
  String feedStale(String time);

  /// No description provided for @badgeScene.
  ///
  /// In en, this message translates to:
  /// **'Scene'**
  String get badgeScene;

  /// No description provided for @badgeNoScene.
  ///
  /// In en, this message translates to:
  /// **'No scene'**
  String get badgeNoScene;

  /// No description provided for @badgeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get badgeUnknown;

  /// No description provided for @detailsSceneYes.
  ///
  /// In en, this message translates to:
  /// **'There is a scene'**
  String get detailsSceneYes;

  /// No description provided for @detailsSceneNo.
  ///
  /// In en, this message translates to:
  /// **'No scene'**
  String get detailsSceneNo;

  /// No description provided for @detailsSceneUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not enough votes yet'**
  String get detailsSceneUnknown;

  /// No description provided for @detailsSceneUnknownHint.
  ///
  /// In en, this message translates to:
  /// **'Say one of the first — it takes one tap.'**
  String get detailsSceneUnknownHint;

  /// Confidence in the verdict. Deliberately carries no vote count: the numbers behind it are sums of trust weight, not people, so any count would be a wrong number.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of voters agree'**
  String detailsSceneConfidence(int percent);

  /// No description provided for @detailsWorthYes.
  ///
  /// In en, this message translates to:
  /// **'Worth waiting for'**
  String get detailsWorthYes;

  /// No description provided for @detailsWorthNo.
  ///
  /// In en, this message translates to:
  /// **'Not worth waiting for'**
  String get detailsWorthNo;

  /// No description provided for @detailsWorthConfidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of those who saw it'**
  String detailsWorthConfidence(int percent);

  /// No description provided for @detailsVoteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Did this film have a scene during or after the credits?'**
  String get detailsVoteQuestion;

  /// No description provided for @detailsVoteYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, there was'**
  String get detailsVoteYes;

  /// No description provided for @detailsVoteNo.
  ///
  /// In en, this message translates to:
  /// **'No, there wasn\'t'**
  String get detailsVoteNo;

  /// No description provided for @detailsWorthQuestion.
  ///
  /// In en, this message translates to:
  /// **'Was it worth waiting for?'**
  String get detailsWorthQuestion;

  /// No description provided for @detailsWorthYesAction.
  ///
  /// In en, this message translates to:
  /// **'Worth it'**
  String get detailsWorthYesAction;

  /// No description provided for @detailsWorthNoAction.
  ///
  /// In en, this message translates to:
  /// **'Not worth it'**
  String get detailsWorthNoAction;

  /// No description provided for @detailsVoteQueued.
  ///
  /// In en, this message translates to:
  /// **'Saved. It will be sent when you are back online.'**
  String get detailsVoteQueued;

  /// No description provided for @detailsOverview.
  ///
  /// In en, this message translates to:
  /// **'About the film'**
  String get detailsOverview;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Film title'**
  String get searchHint;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Find a film to check or to vote on.'**
  String get searchPrompt;

  /// No description provided for @searchEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing found for “{query}”.'**
  String searchEmpty(String query);

  /// No description provided for @searchEmptyOffline.
  ///
  /// In en, this message translates to:
  /// **'Only films you have already searched for are available offline.'**
  String get searchEmptyOffline;

  /// No description provided for @myVotesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You have not voted yet.'**
  String get myVotesEmpty;

  /// No description provided for @myVotesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Open a film and say whether it has a scene during or after the credits.'**
  String get myVotesEmptyHint;

  /// No description provided for @myVotesPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be sent'**
  String get myVotesPending;

  /// No description provided for @voteAnswerSceneYes.
  ///
  /// In en, this message translates to:
  /// **'You said: there is a scene'**
  String get voteAnswerSceneYes;

  /// No description provided for @voteAnswerSceneNo.
  ///
  /// In en, this message translates to:
  /// **'You said: no scene'**
  String get voteAnswerSceneNo;

  /// No description provided for @voteAnswerWorthYes.
  ///
  /// In en, this message translates to:
  /// **'Worth waiting for'**
  String get voteAnswerWorthYes;

  /// No description provided for @voteAnswerWorthNo.
  ///
  /// In en, this message translates to:
  /// **'Not worth waiting for'**
  String get voteAnswerWorthNo;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsCinemaMode.
  ///
  /// In en, this message translates to:
  /// **'Cinema mode'**
  String get settingsCinemaMode;

  /// No description provided for @settingsCinemaModeHint.
  ///
  /// In en, this message translates to:
  /// **'True black and a dimmed screen, for a dark auditorium.'**
  String get settingsCinemaModeHint;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System language'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get settingsLanguageRussian;

  /// No description provided for @settingsMyVotes.
  ///
  /// In en, this message translates to:
  /// **'My votes'**
  String get settingsMyVotes;

  /// No description provided for @settingsMyVotesHint.
  ///
  /// In en, this message translates to:
  /// **'Everything you have voted on.'**
  String get settingsMyVotesHint;

  /// No description provided for @aboutTmdbAttribution.
  ///
  /// In en, this message translates to:
  /// **'This product uses the TMDB API but is not endorsed or certified by TMDB.'**
  String get aboutTmdbAttribution;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
