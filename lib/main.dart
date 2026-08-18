import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/db/app_database.dart';
import 'core/di/app_dependencies.dart';
import 'core/errors/error_handlers.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandlers();

  // Set before the first frame so no default light system bar can appear during startup.
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle(AppPalette.dark));

  if (!AppConfig.isConfigured) {
    runApp(const NotConfiguredApp());
    return;
  }

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // Supabase renamed the anon key to the publishable key; the `--dart-define` keeps
    // the name the project's docs and the dashboard both still use.
    publishableKey: AppConfig.supabaseAnonKey,
  );

  final deps = await AppDependencies.bootstrap(
    supabase: Supabase.instance.client,
    database: AppDatabase(),
  );

  // Not awaited: signing in anonymously needs the network, and with none the app must
  // still open and show everything already cached. The feed reads fine with just the
  // publishable key; only voting needs the session, and it will be there by then.
  unawaited(deps.startSession());

  runApp(StingersApp(deps: deps));
}
