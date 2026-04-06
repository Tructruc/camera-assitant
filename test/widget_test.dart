import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app shows tool grid', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          settings: AppSettings(),
          onSettingsChanged: _noopSettingsChanged,
        ),
      ),
    );

    expect(find.text('Photography toolkit'), findsOneWidget);
    expect(find.text('Exposure'), findsOneWidget);
    expect(find.text('DOF'), findsOneWidget);
    expect(find.text('Extension Tubes'), findsOneWidget);
    expect(find.text('Reverse Lens'), findsOneWidget);
    expect(find.byTooltip('Reorder tools'), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Dual Lens Macro'),
      300,
    );

    expect(find.text('Dual Lens Macro'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sun Planner'),
      300,
    );

    expect(find.text('Sun Planner'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Long Exposure'),
      300,
    );

    expect(find.text('Long Exposure'), findsOneWidget);
  });

  testWidgets('home screen respects saved tool order', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          settings: AppSettings(
            homeToolOrder: [
              'long_exposure',
              'sun_planner',
              'exposure',
              'dof',
              'extension_tubes',
              'reverse_lens',
              'dual_lens_macro',
            ],
          ),
          onSettingsChanged: _noopSettingsChanged,
        ),
      ),
    );

    final longExposureTopLeft = tester.getTopLeft(find.text('Long Exposure'));
    final exposureTopLeft = tester.getTopLeft(find.text('Exposure'));

    expect(longExposureTopLeft.dy, lessThan(exposureTopLeft.dy));
  });

  testWidgets('home screen shows folders for grouped cards', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(
          settings: AppSettings(
            homeToolOrder: ['folder:macro_group', 'exposure', 'dof'],
            homeFolders: [
              HomeFolder(
                id: 'macro_group',
                name: 'Macro',
                toolIds: ['extension_tubes', 'reverse_lens'],
              ),
            ],
          ),
          onSettingsChanged: _noopSettingsChanged,
        ),
      ),
    );

    expect(find.text('Macro'), findsOneWidget);
    expect(find.text('Extension Tubes'), findsNothing);
    expect(find.text('Reverse Lens'), findsNothing);
  });
}

void _noopSettingsChanged(AppSettings _) {}
