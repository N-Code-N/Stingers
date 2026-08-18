import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Colour tokens for the two levels of darkness. There is no light palette, and there
/// will not be one: the only place this app matters is a dark auditorium.
///
/// Every value here is warm. Dark-adapted vision runs on rods, which peak near 500 nm
/// and are nearly blind to deep red, so blue-white light is simultaneously the most
/// disruptive to the viewer's own adaptation and the most visible to the strangers
/// sitting next to them. Amber is the least of both. This is the same reason aviation
/// and astronomy light their instruments red.
class AppPalette {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.accent,
    required this.onAccent,
    required this.outline,
    required this.error,
    required this.posterVeil,
    required this.isCinema,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color accent;
  final Color onAccent;
  final Color outline;
  final Color error;

  /// Black laid over posters. Zero in Dark, heavy in Cinema mode — a poster is the
  /// brightest thing this app can put on screen.
  final double posterVeil;

  final bool isCinema;

  /// Default. Near-black rather than true black so elevation is still legible.
  static const AppPalette dark = AppPalette(
    background: Color(0xFF0A0A0B),
    // Warm-neutral greys. A "neutral" dark grey picked by eye almost always comes out
    // a step blue, and a step of blue repeated across every surface is what makes a
    // dark UI read as cold.
    surface: Color(0xFF141312),
    surfaceRaised: Color(0xFF1D1B18),
    // Warm off-white, never #FFFFFF: 10.8:1 on the background, and it does not read as
    // a light source the way pure white does.
    onSurface: Color(0xFFF2EBE0),
    onSurfaceMuted: Color(0xFF9A9086), // 6.3:1 — still comfortably above 4.5:1
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF241703),
    outline: Color(0xFF2E2A26),
    error: Color(0xFFE5533B), // warm red; nothing blue-tinted
    posterVeil: 0,
    isCinema: false,
  );

  /// Opt-in. True black switches OLED pixels off entirely, which is one of only two
  /// levers that actually reduce emitted light — the other is the backlight API.
  /// Muting the palette to grey is the wrong lever: it destroys legibility and an LCD
  /// emits on a black pixel anyway.
  static const AppPalette cinema = AppPalette(
    background: Color(0xFF000000),
    surface: Color(0xFF000000),
    surfaceRaised: Color(0xFF0A0806),
    // No off-white at all here. Amber carries every role, at 11.5:1 on true black.
    onSurface: Color(0xFFFFB020),
    onSurfaceMuted: Color(0xFFB07714),
    accent: Color(0xFFFFB020),
    onAccent: Color(0xFF000000),
    outline: Color(0xFF241703),
    error: Color(0xFFE5533B),
    posterVeil: 0.72,
    isCinema: true,
  );
}

/// The parts of the palette that are not colours, carried through `ThemeData` so a
/// widget still reads a theme value rather than reaching for the `CinemaMode` singleton.
class CinemaExtras extends ThemeExtension<CinemaExtras> {
  const CinemaExtras({required this.posterVeil, required this.reduceMotion});

  final double posterVeil;

  /// True in cinema mode. The View combines it with `MediaQuery.disableAnimations`;
  /// either one alone is enough to drop to a cross-fade.
  final bool reduceMotion;

  static CinemaExtras of(BuildContext context) =>
      Theme.of(context).extension<CinemaExtras>() ??
      const CinemaExtras(posterVeil: 0, reduceMotion: false);

  @override
  CinemaExtras copyWith({double? posterVeil, bool? reduceMotion}) => CinemaExtras(
    posterVeil: posterVeil ?? this.posterVeil,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  CinemaExtras lerp(CinemaExtras? other, double t) {
    if (other == null) return this;
    return CinemaExtras(
      posterVeil: lerpDouble(posterVeil, other.posterVeil, t) ?? posterVeil,
      reduceMotion: t < 0.5 ? reduceMotion : other.reduceMotion,
    );
  }
}

/// The app's two themes. Both are `Brightness.dark`; `themeMode` is never consulted and
/// `platformBrightness` is never read.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppPalette.dark);

  static ThemeData cinema() => _build(AppPalette.cinema);

  /// Status and navigation bars. Applied at the `MaterialApp` level so route
  /// transitions cannot reveal a default light system bar.
  static SystemUiOverlayStyle overlayStyle(AppPalette palette) => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: palette.background,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  static const PageTransitionsTheme _crossFade = PageTransitionsTheme(
    builders: {
      TargetPlatform.iOS: _CrossFadeTransitionsBuilder(),
      TargetPlatform.android: _CrossFadeTransitionsBuilder(),
    },
  );

  static ThemeData _build(AppPalette palette) {
    final colors = _scheme(palette);
    final text = _textTheme(palette);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colors,
      textTheme: text,
      extensions: [
        CinemaExtras(posterVeil: palette.posterVeil, reduceMotion: palette.isCinema),
      ],
      // In cinema mode a slide transition is a bright rectangle sweeping across a dark
      // room. A cross-fade moves the same content with no travelling light. Outside
      // cinema mode the platform default is left alone — it is what users expect.
      pageTransitionsTheme: palette.isCinema ? _crossFade : const PageTransitionsTheme(),
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      splashColor: palette.accent.withValues(alpha: 0.08),
      highlightColor: palette.accent.withValues(alpha: 0.06),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.onSurface,
        // M3 tints an app bar with the primary colour on scroll; left on, the bar
        // brightens as the user scrolls, which is the opposite of what this app wants.
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlayStyle(palette),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: palette.surfaceRaised,
      ),
      // M3 defaults a snackbar to `inverseSurface`, which in a dark theme is a *light*
      // slab. In a dark auditorium that is the worst frame this app could show.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surfaceRaised,
        contentTextStyle: text.bodyMedium?.copyWith(color: palette.onSurface),
        actionTextColor: palette.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.accent.withValues(alpha: 0.16),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? text.labelMedium?.copyWith(color: palette.accent)
              : text.labelMedium?.copyWith(color: palette.onSurfaceMuted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.onSurfaceMuted,
          ),
        ),
      ),
      // Material's default indicator is the primary colour, but an unstyled one still
      // slips through in places; naming it here means no blue spinner can appear.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: palette.accent,
        circularTrackColor: palette.outline,
        linearTrackColor: palette.outline,
      ),
      dividerTheme: DividerThemeData(color: palette.outline, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: palette.onSurface),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.outline,
          disabledForegroundColor: palette.onSurfaceMuted,
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 52), // one-handed, in the dark
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.onSurface,
          side: BorderSide(color: palette.outline),
          textStyle: text.labelLarge,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.accent,
          textStyle: text.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: text.bodyLarge?.copyWith(color: palette.onSurfaceMuted),
        prefixIconColor: palette.onSurfaceMuted,
        suffixIconColor: palette.onSurfaceMuted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.accent),
        ),
      ),
    );
  }

  /// Built by hand rather than `ColorScheme.fromSeed`. A seeded scheme derives
  /// secondary/tertiary roles by rotating hue, which is exactly how a cool colour gets
  /// in through a role nobody thought to check.
  static ColorScheme _scheme(AppPalette palette) => ColorScheme(
    brightness: Brightness.dark,
    primary: palette.accent,
    onPrimary: palette.onAccent,
    primaryContainer: palette.surfaceRaised,
    onPrimaryContainer: palette.accent,
    secondary: palette.accent,
    onSecondary: palette.onAccent,
    secondaryContainer: palette.surfaceRaised,
    onSecondaryContainer: palette.onSurface,
    tertiary: palette.onSurfaceMuted,
    onTertiary: palette.background,
    tertiaryContainer: palette.surfaceRaised,
    onTertiaryContainer: palette.onSurface,
    error: palette.error,
    onError: palette.background,
    errorContainer: palette.surfaceRaised,
    onErrorContainer: palette.error,
    surface: palette.surface,
    onSurface: palette.onSurface,
    surfaceContainerLowest: palette.background,
    surfaceContainerLow: palette.background,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surfaceRaised,
    surfaceContainerHighest: palette.surfaceRaised,
    onSurfaceVariant: palette.onSurfaceMuted,
    outline: palette.outline,
    outlineVariant: palette.outline,
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    // The inverse roles are where a dark M3 theme hides a light slab (snackbars,
    // tooltips). Kept dark on purpose.
    inverseSurface: palette.surfaceRaised,
    onInverseSurface: palette.onSurface,
    inversePrimary: palette.accent,
    surfaceTint: Colors.transparent,
  );

  /// One scale, defined once. Hierarchy comes from weight + size + leading together;
  /// tracking tightens as size grows and leading loosens as size shrinks.
  static TextTheme _textTheme(AppPalette palette) {
    const display = TextStyle(fontWeight: FontWeight.w700);
    return TextTheme(
      displayLarge: display.copyWith(fontSize: 44, letterSpacing: -1.2, height: 1.04),
      displayMedium: display.copyWith(fontSize: 36, letterSpacing: -0.9, height: 1.08),
      displaySmall: display.copyWith(fontSize: 30, letterSpacing: -0.6, height: 1.12),
      headlineLarge: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        height: 1.15,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
        height: 1.18,
      ),
      headlineSmall: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      titleLarge: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.25,
      ),
      titleMedium: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleSmall: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.3,
      ),
      bodyLarge: const TextStyle(fontSize: 17, height: 1.45),
      bodyMedium: const TextStyle(fontSize: 15, height: 1.45),
      bodySmall: const TextStyle(fontSize: 13, letterSpacing: 0.1, height: 1.4),
      labelLarge: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        height: 1.2,
      ),
      labelMedium: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.2,
      ),
      labelSmall: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        height: 1.2,
      ),
    ).apply(bodyColor: palette.onSurface, displayColor: palette.onSurface);
  }
}

/// A route transition that changes nothing but opacity.
///
/// `FadeTransition` rather than an animated `Opacity` widget: the former is driven by
/// the compositor, the latter forces an offscreen layer for every frame.
class _CrossFadeTransitionsBuilder extends PageTransitionsBuilder {
  const _CrossFadeTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => FadeTransition(opacity: animation, child: child);
}
