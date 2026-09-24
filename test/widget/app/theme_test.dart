import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';

void main() {
  test('light and dark themes expose matching brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  // The app does not only paint onSurface on surface: captions and provenance
  // lines are onSurfaceVariant, section labels and accents are primary, saved
  // results sit on the container colours, warnings are error, and snackbars are
  // onInverseSurface. Each of those pairs is what a photographer has to read in
  // daylight, so each one is held to WCAG AA (4.5:1 for text, 3:1 for the
  // dividers and borders that use outline).
  test('every text-on-surface pair the app uses meets WCAG AA', () {
    for (final theme in <ThemeData>[
      AppTheme.light,
      AppTheme.dark,
      AppTheme.lowLight,
    ]) {
      final scheme = theme.colorScheme;
      final pairs = <String, (Color, Color, double)>{
        'onSurface on surface': (scheme.onSurface, scheme.surface, 4.5),
        'onSurface on surfaceContainer': (
          scheme.onSurface,
          scheme.surfaceContainer,
          4.5,
        ),
        'onSurface on surfaceContainerHigh': (
          scheme.onSurface,
          scheme.surfaceContainerHigh,
          4.5,
        ),
        'onSurface on surfaceContainerHighest': (
          scheme.onSurface,
          scheme.surfaceContainerHighest,
          4.5,
        ),
        'onSurfaceVariant on surface': (
          scheme.onSurfaceVariant,
          scheme.surface,
          4.5,
        ),
        'onSurfaceVariant on surfaceContainer': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainer,
          4.5,
        ),
        'onSurfaceVariant on surfaceContainerLow': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerLow,
          4.5,
        ),
        'onSurfaceVariant on surfaceContainerHighest': (
          scheme.onSurfaceVariant,
          scheme.surfaceContainerHighest,
          4.5,
        ),
        'primary on surface': (scheme.primary, scheme.surface, 4.5),
        'primary on surfaceContainer': (
          scheme.primary,
          scheme.surfaceContainer,
          4.5,
        ),
        'onPrimary on primary': (scheme.onPrimary, scheme.primary, 4.5),
        'onPrimaryContainer on primaryContainer': (
          scheme.onPrimaryContainer,
          scheme.primaryContainer,
          4.5,
        ),
        'onSecondaryContainer on secondaryContainer': (
          scheme.onSecondaryContainer,
          scheme.secondaryContainer,
          4.5,
        ),
        'onTertiaryContainer on tertiaryContainer': (
          scheme.onTertiaryContainer,
          scheme.tertiaryContainer,
          4.5,
        ),
        'error on surface': (scheme.error, scheme.surface, 4.5),
        'onError on error': (scheme.onError, scheme.error, 4.5),
        'onErrorContainer on errorContainer': (
          scheme.onErrorContainer,
          scheme.errorContainer,
          4.5,
        ),
        'onInverseSurface on inverseSurface': (
          scheme.onInverseSurface,
          scheme.inverseSurface,
          4.5,
        ),
        'outline on surface (dividers, borders)': (
          scheme.outline,
          scheme.surface,
          3,
        ),
      };

      for (final pair in pairs.entries) {
        final ratio = _contrastRatio(pair.value.$1, pair.value.$2);
        expect(
          ratio,
          greaterThanOrEqualTo(pair.value.$3),
          reason:
              '${theme.brightness.name} theme: ${pair.key} is '
              '${ratio.toStringAsFixed(2)}:1, below ${pair.value.$3}:1',
        );
      }
    }
  });

  test('low-light theme uses a black field surface and red accents', () {
    final scheme = AppTheme.lowLight.colorScheme;

    expect(AppTheme.lowLight.brightness, Brightness.dark);
    expect(scheme.surface, Colors.black);
    expect(scheme.primary.r, greaterThan(scheme.primary.g));
    expect(scheme.primary.r, greaterThan(scheme.primary.b));
  });

  testWidgets('theme keeps controls at accessible minimum target size', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(IconButton)).shortestSide,
      greaterThanOrEqualTo(48),
    );
  });
}

double _contrastRatio(Color first, Color second) {
  // A translucent foreground is composited onto the surface it is painted on
  // before measuring: comparing raw alpha channels would overstate the ratio.
  final foreground = first.a >= 1 ? first : Color.alphaBlend(first, second);
  final firstLuminance = foreground.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter = math.max(firstLuminance, secondLuminance);
  final darker = math.min(firstLuminance, secondLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}
