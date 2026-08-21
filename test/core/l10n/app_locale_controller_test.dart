import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/l10n/app_locale_controller.dart';

void main() {
  late List<Locale?> persisted;

  AppLocaleController build({Locale? initialOverride}) => AppLocaleController(
    initialOverride: initialOverride,
    persist: (locale) async => persisted.add(locale),
  );

  setUp(() {
    persisted = [];
  });

  test('starts on whatever was persisted, not on the system default', () {
    // This is the whole point: a restart must hand the stored choice straight back in,
    // before anything reads `locale`.
    final controller = build(initialOverride: const Locale('ru'));

    expect(controller.locale, const Locale('ru'));
    expect(controller.languageCode, 'ru');
  });

  test('picking a language persists it', () async {
    final controller = build();

    await controller.setLocale(const Locale('ru'));

    expect(persisted, [const Locale('ru')]);
  });

  test('setting the same language again does not touch storage', () async {
    final controller = build(initialOverride: const Locale('ru'));

    await controller.setLocale(const Locale('ru'));

    expect(persisted, isEmpty);
  });

  test('a restart replays exactly what the previous session persisted', () async {
    // Simulates AppDependencies.bootstrap: one controller writes, a fresh one on the
    // next launch is seeded from what was written.
    final first = build();
    await first.setLocale(const Locale('ru'));

    final second = AppLocaleController(
      initialOverride: persisted.single,
      persist: (locale) async {},
    );

    expect(second.locale, const Locale('ru'));
  });

  test('notifies listeners when the language changes', () async {
    final controller = build();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.setLocale(const Locale('ru'));

    expect(notifications, 1);
  });
}
