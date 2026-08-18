import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/di/app_dependencies.dart';
import 'core/l10n/l10n.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// The root widget.
///
/// `themeMode` is pinned to dark and there is no light `ThemeData` at all — the two
/// themes it swaps between are Dark and Cinema mode, both dark. `platformBrightness` is
/// never consulted.
class StingersApp extends StatefulWidget {
  const StingersApp({super.key, required this.deps});

  final AppDependencies deps;

  @override
  State<StingersApp> createState() => _StingersAppState();
}

class _StingersAppState extends State<StingersApp> {
  /// Built once. Recreating a `GoRouter` in `build` would reset the navigation stack on
  /// every theme or locale change.
  late final GoRouter _router = createAppRouter(deps: widget.deps);

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([widget.deps.cinemaMode, widget.deps.locale]),
    builder: (context, _) {
      final theme = widget.deps.cinemaMode.theme;
      return MaterialApp.router(
        onGenerateTitle: (context) => context.l10n.appTitle,
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: theme,
        themeMode: ThemeMode.dark,
        locale: widget.deps.locale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
      );
    },
  );
}

/// Shown when the app was built without `SUPABASE_URL` / `SUPABASE_ANON_KEY`.
///
/// A missing define is a build mistake, not a runtime condition to handle gracefully —
/// but it should say so on a black screen instead of crashing inside the SDK.
class NotConfiguredApp extends StatelessWidget {
  const NotConfiguredApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.dark(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.dark,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              context.l10n.errorNotConfigured,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      ),
    ),
  );
}
