import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';

void main() {
  test('light and dark themes expose matching brightness', () {
    expect(AppTheme.light.brightness, Brightness.light);
    expect(AppTheme.dark.brightness, Brightness.dark);
  });

  test('all themes meet normal-text surface contrast', () {
    for (final theme in <ThemeData>[
      AppTheme.light,
      AppTheme.dark,
      AppTheme.lowLight,
    ]) {
      expect(
        _contrastRatio(theme.colorScheme.onSurface, theme.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
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
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first
      : second;
  final darker = lighter == first ? second : first;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}
