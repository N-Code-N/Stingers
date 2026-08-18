import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stingers/core/theme/app_theme.dart';

/// WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + 0.05) / (lo + 0.05);
}

/// Every named role, listed by hand because `ColorScheme` cannot be iterated. A role
/// added to the scheme without being added here is the gap this test is guarding, so
/// keep the list in step with `AppTheme._scheme`.
Map<String, Color> _roles(ColorScheme s) => {
  'primary': s.primary,
  'onPrimary': s.onPrimary,
  'primaryContainer': s.primaryContainer,
  'onPrimaryContainer': s.onPrimaryContainer,
  'secondary': s.secondary,
  'onSecondary': s.onSecondary,
  'secondaryContainer': s.secondaryContainer,
  'onSecondaryContainer': s.onSecondaryContainer,
  'tertiary': s.tertiary,
  'onTertiary': s.onTertiary,
  'tertiaryContainer': s.tertiaryContainer,
  'onTertiaryContainer': s.onTertiaryContainer,
  'error': s.error,
  'onError': s.onError,
  'errorContainer': s.errorContainer,
  'onErrorContainer': s.onErrorContainer,
  'surface': s.surface,
  'onSurface': s.onSurface,
  'surfaceContainerLowest': s.surfaceContainerLowest,
  'surfaceContainerLow': s.surfaceContainerLow,
  'surfaceContainer': s.surfaceContainer,
  'surfaceContainerHigh': s.surfaceContainerHigh,
  'surfaceContainerHighest': s.surfaceContainerHighest,
  'onSurfaceVariant': s.onSurfaceVariant,
  'outline': s.outline,
  'outlineVariant': s.outlineVariant,
  'inverseSurface': s.inverseSurface,
  'onInverseSurface': s.onInverseSurface,
  'inversePrimary': s.inversePrimary,
};

void main() {
  final themes = {'dark': AppTheme.dark(), 'cinema': AppTheme.cinema()};
  final palettes = {'dark': AppPalette.dark, 'cinema': AppPalette.cinema};

  // This is the only thing standing between the app and a blue-white surface creeping
  // back in six months through a role nobody looked at.
  themes.forEach((name, theme) {
    group('$name theme', () {
      test('is dark, and there is no light theme to switch to', () {
        expect(theme.brightness, Brightness.dark);
        expect(theme.colorScheme.brightness, Brightness.dark);
      });

      test('contains no cool colour in any ColorScheme role', () {
        _roles(theme.colorScheme).forEach((role, color) {
          // Warm means blue never leads. Exactly one 8-bit step of tolerance, because
          // the background is #0A0A0B and that last bit is invisible — two steps is
          // where a grey starts reading cold.
          expect(
            color.b - color.r,
            lessThanOrEqualTo(1 / 255),
            reason: '$role ($color) is blue-dominant',
          );
        });
      });

      test('never uses pure white', () {
        _roles(theme.colorScheme).forEach((role, color) {
          expect(color, isNot(const Color(0xFFFFFFFF)), reason: '$role is pure white');
        });
      });

      test('keeps text legible — nothing is dimmed by crushing contrast', () {
        final colors = theme.colorScheme;
        final background = palettes[name]!.background;
        expect(_contrast(colors.onSurface, background), greaterThanOrEqualTo(4.5));
        expect(_contrast(colors.onSurfaceVariant, background), greaterThanOrEqualTo(4.5));
        expect(_contrast(colors.primary, background), greaterThanOrEqualTo(4.5));
        expect(_contrast(colors.error, background), greaterThanOrEqualTo(4.5));
      });

      test('has no light surface hiding in a component theme', () {
        final background = palettes[name]!.background;
        final surfaces = <String, Color?>{
          'scaffold': theme.scaffoldBackgroundColor,
          'canvas': theme.canvasColor,
          'appBar': theme.appBarTheme.backgroundColor,
          'card': theme.cardTheme.color,
          'dialog': theme.dialogTheme.backgroundColor,
          'bottomSheet': theme.bottomSheetTheme.backgroundColor,
          // M3 defaults a snackbar to `inverseSurface`, which is light in a dark theme.
          'snackBar': theme.snackBarTheme.backgroundColor,
          'navigationBar': theme.navigationBarTheme.backgroundColor,
        };

        surfaces.forEach((name, color) {
          expect(color, isNotNull, reason: '$name has no explicit colour');
          expect(
            _luminance(color!),
            lessThanOrEqualTo(_luminance(background) + 0.02),
            reason: '$name is lighter than the background',
          );
        });
      });

      test('spinners and app bars cannot pick up a Material default', () {
        expect(theme.progressIndicatorTheme.color, palettes[name]!.accent);
        expect(theme.appBarTheme.surfaceTintColor, const Color(0x00000000));
      });

      test('carries the cinema extras a widget reads instead of the singleton', () {
        final extras = theme.extension<CinemaExtras>();
        expect(extras, isNotNull);
        expect(extras!.posterVeil, palettes[name]!.posterVeil);
        expect(extras.reduceMotion, palettes[name]!.isCinema);
      });
    });
  });

  group('cinema mode specifically', () {
    test('is true black, so OLED pixels are physically off', () {
      expect(AppPalette.cinema.background, const Color(0xFF000000));
      expect(AppTheme.cinema().scaffoldBackgroundColor, const Color(0xFF000000));
    });

    test('drops off-white entirely — amber carries every role', () {
      expect(AppPalette.cinema.onSurface, AppPalette.cinema.accent);
    });

    test('veils posters, which are the brightest thing on screen', () {
      expect(AppPalette.cinema.posterVeil, greaterThan(0.5));
      expect(AppPalette.dark.posterVeil, 0);
    });

    test('keeps contrast high rather than dimming the palette', () {
      // The wrong lever is a muted grey palette; the right ones are true black and the
      // backlight API. So contrast must stay high, not drop.
      expect(
        _contrast(AppPalette.cinema.onSurface, AppPalette.cinema.background),
        greaterThan(
          _contrast(AppPalette.dark.onSurfaceMuted, AppPalette.dark.background),
        ),
      );
    });
  });

  group('type scale', () {
    test('tightens tracking as size grows and loosens leading as it shrinks', () {
      final text = AppTheme.dark().textTheme;
      expect(text.displayLarge!.letterSpacing, lessThan(0));
      expect(text.displayLarge!.height, lessThan(1.2));
      expect(text.bodyLarge!.height, greaterThanOrEqualTo(1.4));
      expect(text.labelSmall!.letterSpacing, greaterThan(0));
    });

    test('builds hierarchy from weight as well as size', () {
      final text = AppTheme.dark().textTheme;
      expect(text.displayLarge!.fontSize, greaterThan(text.bodyLarge!.fontSize!));
      expect(
        text.displayLarge!.fontWeight!.value,
        greaterThan(text.bodyLarge!.fontWeight?.value ?? FontWeight.w400.value),
      );
    });
  });
}
