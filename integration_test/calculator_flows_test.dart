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

    await tapVisible(tester, find.text('Timelapse planner'), delta: 300);
    await tapVisible(tester, find.text('Plan timelapse'), delta: 300);
    expect(find.text('361'), findsOneWidget);
    await scrollToResultActions(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Save result'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Flash exposure'), delta: -300);
    await tester.tap(find.text('Calculate flash exposure'));
    await tester.pumpAndSettle();
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

    // Saved camera and lens values remain editable one-off inputs. The camera
    // picker now lives behind the result-first "More settings" section.
    await tapVisible(tester, find.text('Depth of field'), delta: 300);
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24-70 mm f/2.8').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('More settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Calculate'), delta: 300);
    expect(find.text('Near limit'), findsOneWidget);
    expect(find.textContaining('From 24-70 mm'), findsWidgets);
    expect(find.textContaining('connect'), findsNothing);
    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    expect(find.text('Result saved on this device.'), findsOneWidget);

    // Manual exposure comparison works without inventory or network access.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Exposure comparison'), delta: 300);
    await tapVisible(tester, find.text('Compare exposures'), delta: 300);
    expect(find.text('Equivalent exposure'), findsOneWidget);
    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();

    // A saved ND filter applies its canonical strength to the quickstart case.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Long exposure / ND'), delta: 300);
    await tester.tap(find.text('Saved ND filter (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-stop ND').last);
    await tester.enterText(
      find.byKey(const Key('long-base')),
      '0.0333333333333333',
    );
    await tapVisible(tester, find.text('Calculate exposure'), delta: 300);
    // The hero carries the human-readable time; the conventional label rounds
    // to the selected stop increment and the exact value lives in Details.
    expect(find.text('34.1 s'), findsOneWidget);
    expect(find.textContaining('32 s'), findsWidgets);
    expect(find.textContaining('From 10-stop ND'), findsWidgets);
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
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
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

  testWidgets(
    'editing an input blocks saving until the result is recalculated',
    (tester) async {
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

      await tapVisible(tester, find.text('Depth of field'), delta: 300);
      await tester.tap(find.text('Calculate'));
      await tester.pumpAndSettle();
      expect(find.text('Save result'), findsOneWidget);

      // Editing an input invalidates the displayed result and its save action.
      await tester.scrollUntilVisible(
        find.text('Focal length (mm)'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Focal length (mm)'),
        '85',
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(find.text('Save result'), findsNothing);

      // Recalculation restores a savable result and the journey completes.
      await tapVisible(tester, find.text('Calculate'), delta: -300);
      await scrollToResultActions(tester, extra: 500);
      await tester.tap(find.text('Save result'));
      await tester.pumpAndSettle();

      final snapshots = await DriftSnapshotRepository(
        database,
      ).listNewestFirst();
      expect(snapshots, hasLength(1));
      expect(snapshots.single.canonicalInputs['focalLengthMm'], 85);
    },
  );
}
