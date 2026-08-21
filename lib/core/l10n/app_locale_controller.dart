import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

Future<void> _noopPersist(Locale? _) async {}

/// The single source of truth for "what language is this session in".
///
/// It drives `MaterialApp.locale` and the outgoing `Accept-Language` header *and* the
/// `language` parameter sent to TMDb, so changing the language switches the interface
/// and the film descriptions together, with no restart.
///
/// The choice outlives the session: [initialOverride] is what a previous run persisted,
/// read by the composition root before this is constructed, and [setLocale] hands
/// [persist] whatever should be read back next time. Screens that only care about the
/// in-memory value — most of the test suite — can ignore both parameters entirely.
class AppLocaleController extends ChangeNotifier {
  AppLocaleController({
    Locale? initialOverride,
    Future<void> Function(Locale? locale) persist = _noopPersist,
  }) : _override = initialOverride,
       _persist = persist;

  static const List<Locale> supported = [Locale('en'), Locale('ru')];

  final Future<void> Function(Locale? locale) _persist;

  Locale? _override;
  int _generation = 0;

  /// null means "follow the system", which is what `MaterialApp.locale` wants.
  Locale? get locale => _override;

  /// Monotonic bump for every locale change, so screens can revalidate their cached data
  /// without relying on a route being currently mounted.
  int get generation => _generation;

  Future<void> setLocale(Locale? value) async {
    if (_override == value) return;
    _override = value;
    _generation++;
    notifyListeners();
    await _persist(value);
  }

  /// The language actually in effect, already narrowed to what the app ships.
  ///
  /// Resolving here rather than sending the raw system code keeps interface and content
  /// in step: a device set to German renders English copy, so it should also be asking
  /// TMDb for English, not German.
  String get languageCode {
    final code =
        _override?.languageCode ?? PlatformDispatcher.instance.locale.languageCode;
    return supported.any((l) => l.languageCode == code) ? code : 'en';
  }

  /// TMDb wants a full `language` tag, not a bare code.
  String get tmdbLanguage => switch (languageCode) {
    'ru' => 'ru-RU',
    _ => 'en-US',
  };
}
