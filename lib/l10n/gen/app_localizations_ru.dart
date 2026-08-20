// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Stingers';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navMyVotes => 'Мои голоса';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get errorGeneric => 'Что-то пошло не так.';

  @override
  String get errorOffline => 'Нет соединения.';

  @override
  String get errorNotFound => 'Не найдено.';

  @override
  String get errorSession =>
      'Не удалось начать сессию. Проверьте соединение и попробуйте снова.';

  @override
  String get errorUpstream => 'База фильмов сейчас не отвечает.';

  @override
  String get errorVoteRejected => 'Голос не засчитан. Попробуйте чуть позже.';

  @override
  String get errorNotConfigured =>
      'Приложение собрано без бэкенда. Передайте SUPABASE_URL и SUPABASE_ANON_KEY.';

  @override
  String get feedEmpty => 'Сейчас ничего не идёт.';

  @override
  String get feedEmptyOffline =>
      'Ничего ещё не загружено. Подключитесь один раз, чтобы наполнить ленту.';

  @override
  String feedStale(String time) {
    return 'Данные от $time';
  }

  @override
  String get badgeScene => 'Есть сцена';

  @override
  String get badgeNoScene => 'Нет сцены';

  @override
  String get badgeUnknown => 'Неизвестно';

  @override
  String get detailsSceneYes => 'После титров есть сцена';

  @override
  String get detailsSceneNo => 'После титров сцены нет';

  @override
  String get detailsSceneUnknown => 'Голосов пока мало';

  @override
  String get detailsSceneUnknownHint => 'Скажите одним из первых — это одно касание.';

  @override
  String detailsSceneConfidence(int percent) {
    return '$percent% проголосовавших согласны';
  }

  @override
  String get detailsWorthYes => 'Стоит дождаться';

  @override
  String get detailsWorthNo => 'Ждать не стоит';

  @override
  String detailsWorthConfidence(int percent) {
    return '$percent% из тех, кто видел';
  }

  @override
  String get detailsVoteQuestion => 'После титров в этом фильме была сцена?';

  @override
  String get detailsVoteYes => 'Да, была';

  @override
  String get detailsVoteNo => 'Нет, не было';

  @override
  String get detailsWorthQuestion => 'Её стоило дождаться?';

  @override
  String get detailsWorthYesAction => 'Стоило';

  @override
  String get detailsWorthNoAction => 'Не стоило';

  @override
  String get detailsVoteQueued => 'Сохранено. Отправим, когда появится сеть.';

  @override
  String get detailsOverview => 'О фильме';

  @override
  String get searchHint => 'Название фильма';

  @override
  String get searchPrompt => 'Найдите фильм, чтобы проверить или проголосовать.';

  @override
  String searchEmpty(String query) {
    return 'По запросу «$query» ничего не найдено.';
  }

  @override
  String get searchEmptyOffline =>
      'Без сети доступны только те фильмы, которые вы уже искали.';

  @override
  String get myVotesEmpty => 'Вы ещё не голосовали.';

  @override
  String get myVotesEmptyHint =>
      'Откройте фильм и скажите, есть ли в нём сцена после титров.';

  @override
  String get myVotesPending => 'Ожидает отправки';

  @override
  String get voteAnswerSceneYes => 'Вы сказали: сцена есть';

  @override
  String get voteAnswerSceneNo => 'Вы сказали: сцены нет';

  @override
  String get voteAnswerWorthYes => 'Стоит дождаться';

  @override
  String get voteAnswerWorthNo => 'Ждать не стоит';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsCinemaMode => 'Кинорежим';

  @override
  String get settingsCinemaModeHint =>
      'Чёрный фон и приглушённый экран — для тёмного зала.';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSystem => 'Язык системы';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageRussian => 'Русский';

  @override
  String get settingsMyVotes => 'Мои голоса';

  @override
  String get settingsMyVotesHint => 'Всё, за что вы голосовали.';

  @override
  String get aboutTmdbAttribution =>
      'This product uses the TMDB API but is not endorsed or certified by TMDB.';
}
