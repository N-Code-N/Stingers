import 'package:flutter/material.dart';
import 'package:stingers/core/l10n/l10n.dart';
import 'package:stingers/core/theme/app_theme.dart';

/// Wraps a widget under test in the delegates and theme every screen assumes.
///
/// A screen that reads `context.l10n` throws under a bare `MaterialApp`, and one that
/// reads a `ColorScheme` role renders against Material's blue defaults — both of which
/// make a test pass or fail for the wrong reason.
Widget testApp({
  required Widget child,
  Locale locale = const Locale('en'),
  ThemeData? theme,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: theme ?? AppTheme.dark(),
  home: child,
);
