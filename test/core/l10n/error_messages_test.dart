import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/errors/app_exceptions.dart';
import 'package:stingers/core/l10n/error_messages.dart';
import 'package:stingers/core/l10n/l10n.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ru;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ru = await AppLocalizations.delegate.load(const Locale('ru'));
  });

  test('offline is a quiet line, not an alarm', () {
    expect(describeError(en, const NetworkException()), en.errorOffline);
  });

  test('a rejected vote says the vote did not land, not "try again"', () {
    // The user has to be told something honest: their vote is not counted.
    expect(
      describeError(en, const VoteRejectedException('rate limited')),
      en.errorVoteRejected,
    );
  });

  test('a session failure has its own line', () {
    expect(
      describeError(en, const UnauthenticatedException('no session')),
      en.errorSession,
    );
  });

  test('TMDb being down is distinct from the app being down', () {
    expect(
      describeError(en, const UpstreamUnavailableException('tmdb')),
      en.errorUpstream,
    );
  });

  test('the server message is never passed through to the user', () {
    // It is either internal detail or a hint about which anti-abuse layer fired.
    const leak = 'device_hourly rate limit exceeded for device 41f2';
    expect(describeError(en, const VoteRejectedException(leak)), isNot(contains('41f2')));
    expect(
      describeError(en, const UnknownApiException(leak)),
      isNot(contains('device_hourly')),
    );
  });

  test('anything unrecognised collapses to the generic line rather than throwing', () {
    expect(describeError(en, StateError('something internal')), en.errorGeneric);
  });

  test('translates with the locale it is handed', () {
    expect(describeError(ru, const NetworkException()), 'Нет соединения.');
  });
}
