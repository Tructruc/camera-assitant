import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

import '../test/fixtures/equipment_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calculates manually and from saved equipment offline', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftEquipmentRepository(database);
    await repository.createCamera(fullFrameCameraFixture());
    await repository.createLens(standardZoomFixture());
    await repository.createFilter(tenStopFilterFixture());
    final preferences = PreferencesRepository(database);
    await preferences.save(
      const AppPreferences(shutterDisplay: ShutterDisplay.conventional),
    );

    Widget app() => ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        equipmentRepositoryProvider.overrideWithValue(repository),
      ],
      child: const PhotographyAssistantApp(),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Saved camera and lens values remain editable one-off inputs.
    await tester.tap(find.text('Depth of field'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24-70 mm f/2.8').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('Near limit'), findsOneWidget);
    expect(find.textContaining('From 24-70 mm'), findsWidgets);
    expect(find.textContaining('connect'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    expect(find.text('Result saved on this device.'), findsOneWidget);

    // Manual exposure comparison works without inventory or network access.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exposure comparison'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Compare exposures'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Compare exposures'));
    await tester.pumpAndSettle();
    expect(find.text('Equivalent exposure'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    // A saved ND filter applies its canonical strength to the quickstart case.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long exposure / ND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved ND filter (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-stop ND').last);
    await tester.enterText(
      find.byKey(const Key('long-base')),
      '0.0333333333333333',
    );
    await tester.scrollUntilVisible(
      find.text('Calculate exposure'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate exposure'));
    await tester.pumpAndSettle();
    expect(find.text('34.1 s'), findsOneWidget);
    expect(find.textContaining('From 10-stop ND'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    // Later equipment and display changes cannot rewrite saved payloads.
    final snapshots = DriftSnapshotRepository(database);
    expect(await snapshots.listNewestFirst(), hasLength(3));
    await repository.archiveCamera('camera-full-frame');
    await repository.archiveLens('lens-standard-zoom');
    await repository.archiveFilter('filter-ten-stop');
    await preferences.save(
      const AppPreferences(
        lengthDisplay: LengthDisplay.imperial,
        shutterDisplay: ShutterDisplay.exact,
        themeMode: AppThemeMode.lowLight,
      ),
    );
    await database.customStatement('''
      INSERT INTO calculation_snapshots (
        id, calculator_id, formula_version, created_at, title,
        payload_version, input_payload, output_payload, display_context,
        assumptions, warnings, equipment_snapshot
      ) VALUES (
        'integration-corrupt', 'depth_of_field', 1, 1, 'Damaged result',
        1, '{broken', '{}', '{}', '[]', '[]', '[]'
      )
    ''');

    // All snapshots survive rebuilding offline with their original context.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Depth of field result'), findsOneWidget);
    expect(find.text('Exposure comparison result'), findsOneWidget);
    expect(find.text('Long exposure result'), findsOneWidget);
    expect(find.text('Saved calculation needs recovery'), findsOneWidget);
    await tester.tap(find.text('Depth of field result'));
    await tester.pumpAndSettle();
    expect(find.text('focalLengthMm: 70.0'), findsOneWidget);
    expect(find.text('distanceUnit: metric'), findsOneWidget);
    expect(find.text('24-70 mm f/2.8'), findsOneWidget);
    expect(find.text('Full Frame Camera'), findsOneWidget);
    expect(find.textContaining('immutable'), findsOneWidget);
  });
}
