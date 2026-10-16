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
import 'support/journey.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('plans flash and timelapse results offline', (tester) async {
    configureJourneyView(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          equipmentRepositoryProvider.overrideWithValue(
            DriftEquipmentRepository(database),
          ),
        ],
        child: const PhotographyAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tapVisibleFromTop(tester, find.text('Timelapse planner'));
    // The plan is live: there is no Plan timelapse button to press.
    expect(find.widgetWithText(FilledButton, 'Plan timelapse'), findsNothing);
    await reveal(tester, find.text('361'));
    expect(find.text('361'), findsOneWidget);
    await scrollToResultActions(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save result'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisibleFromTop(tester, find.text('Flash exposure'));
    expect(
      find.widgetWithText(FilledButton, 'Calculate flash exposure'),
      findsNothing,
    );
    await reveal(tester, find.text('Recommended aperture'));
    expect(find.text('f/8'), findsOneWidget);
    await scrollToResultActions(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save result'));
    await tester.pumpAndSettle();

    final snapshots = await DriftSnapshotRepository(database).listNewestFirst();
    expect(snapshots.map((item) => item.calculatorId).toSet(), {
      'timelapse',
      'flash_exposure',
    });
  });

  testWidgets('calculates manually and from saved equipment offline', (
    tester,
  ) async {
    // Integration tests share a running app process. Dispose the previous
    // navigator and provider tree before starting an independent journey.
    configureJourneyView(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
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

    // Saved camera and lens values remain editable one-off inputs, and both
    // pickers sit with the shot parameters the answer is built from.
    await tapVisibleFromTop(tester, find.text('Depth of field'));
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24-70 mm f/2.8').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();

    // The applied provenance is visible before the answer is scrolled to.
    expect(find.textContaining('From 24-70 mm'), findsWidgets);
    expect(find.textContaining('connect'), findsNothing);

    // The depth-of-field answer is live, so no action stands between the
    // equipment and the result.
    expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);
    await reveal(tester, find.text('Near limit'));
    expect(find.text('Near limit'), findsOneWidget);
    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    expect(find.text('Result saved on this device.'), findsOneWidget);

    // Manual exposure comparison works without inventory or network access.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisibleFromTop(tester, find.text('Exposure comparison'));
    await reveal(tester, find.text('Equivalent exposure'));
    expect(find.text('Equivalent exposure'), findsOneWidget);
    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    // A saved ND filter applies its canonical strength to the quickstart case.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisibleFromTop(tester, find.text('Long exposure / ND'));
    await tester.tap(find.text('Saved ND filter (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-stop ND').last);
    await tester.enterText(
      find.byKey(const Key('long-base')),
      '0.0333333333333333',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('From 10-stop ND'), findsWidgets);
    await reveal(tester, find.text('Filtered exposure time'));
    // The hero carries the human-readable time; the conventional label rounds
    // to the selected stop increment and the exact value lives in Details.
    expect(find.text('34.1 s'), findsOneWidget);
    expect(find.textContaining('32 s'), findsWidgets);
    await reveal(tester, find.text('Details'));
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('34.133333 s'), findsOneWidget);
    await scrollToResultActions(tester);
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
    configureJourneyView(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Saved'));
    expect(find.text('Depth of field result'), findsOneWidget);
    expect(find.text('Exposure comparison result'), findsOneWidget);
    expect(find.text('Long exposure result'), findsOneWidget);
    expect(find.text('Saved calculation needs recovery'), findsOneWidget);
    await tester.tap(find.text('Depth of field result'));
    await tester.pumpAndSettle();
    // The saved plan leads with the same answer as the live screen; the raw
    // provenance maps open one section at a time.
    expect(find.text('Hyperfocal distance'), findsOneWidget);
    await tapVisible(tester, find.text('Values used'), delta: 300);
    expect(find.text('focalLengthMm: 70.0'), findsOneWidget);
    await tapVisible(tester, find.text('Display context'), delta: 300);
    expect(find.text('distanceUnit: metric'), findsOneWidget);
    await tapVisible(tester, find.text('Applied equipment'), delta: 300);
    expect(find.textContaining('24-70 mm f/2.8'), findsOneWidget);
    expect(find.textContaining('Full Frame Camera'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('immutable'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('immutable'), findsOneWidget);
  });

  testWidgets('editing an input keeps the live answer current and savable', (
    tester,
  ) async {
    configureJourneyView(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          equipmentRepositoryProvider.overrideWithValue(
            DriftEquipmentRepository(database),
          ),
        ],
        child: const PhotographyAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tapVisibleFromTop(tester, find.text('Depth of field'));
    // The cheap calculator has no Calculate action: its answer is live.
    expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);
    await reveal(tester, find.text('Hyperfocal distance'));
    expect(find.text('10.47 m'), findsOneWidget);
    expect(find.text('Save result'), findsOneWidget);

    // Editing an input updates the answer in place; it must never leave a
    // stale figure, and it must never stop being savable.
    final focalField = find.widgetWithText(TextField, 'Focal length (mm)');
    await tester.ensureVisible(focalField);
    await tester.pumpAndSettle();
    await tester.enterText(focalField, '85');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Hyperfocal distance'));
    expect(find.text('30.19 m'), findsOneWidget);
    expect(find.text('10.47 m'), findsNothing);
    expect(find.text('Save result'), findsOneWidget);

    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    final snapshots = await DriftSnapshotRepository(database).listNewestFirst();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.canonicalInputs['focalLengthMm'], 85);
  });
}
