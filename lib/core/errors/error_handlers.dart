import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Global error capture, dependency-free.
///
/// No `runZonedGuarded`: since Flutter 3.10 `PlatformDispatcher.onError` catches the
/// async errors it used to, and a guarded zone adds a whole class of confusing
/// interactions for nothing.
void installErrorHandlers() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    reportError(details.exception, details.stack);
  };

  WidgetsBinding.instance.platformDispatcher.onError = onPlatformError;

  if (kReleaseMode) ErrorWidget.builder = _blackErrorWidget;
}

/// Named rather than inline so a test can call it directly.
bool onPlatformError(Object error, StackTrace stack) {
  reportError(error, stack);
  return true;
}

/// The seam a monitoring SDK plugs into later. Logging only for now — adding an SDK is
/// human-review-gated, not something to slip in.
void reportError(Object error, StackTrace? stack) {
  debugPrint('unhandled error: $error\n$stack');
}

/// Flutter's default error widget is a red-on-white box. In a dark auditorium that is
/// the single worst frame this app can produce, so in release it is a black one.
Widget _blackErrorWidget(FlutterErrorDetails details) =>
    ColoredBox(color: AppPalette.dark.background, child: const SizedBox.expand());
