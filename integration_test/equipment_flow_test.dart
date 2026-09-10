import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    show AppDatabase;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/repositories/snapshot_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates, restarts, archives, and restores equipment offline', (
    WidgetTester tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftEquipmentRepository(database);

    Widget app() => ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWith(
          (ref) => Stream<AppPreferences>.value(const AppPreferences()),
        ),
        equipmentRepositoryProvider.overrideWithValue(repository),
      ],
      child: const PhotographyAssistantApp(),
    );

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add camera'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'Integration Camera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      '36',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      '24',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Source note'),
      'Offline integration test',
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    expect(find.text('Integration Camera'), findsOneWidget);
    expect(find.text('Offline integration test'), findsOneWidget);

    // Referenced equipment is archived through Delete; unreferenced equipment
    // is permanently deleted by the current UI.
    final camera = (await repository.listCameras()).single;
    final snapshot = CalculationSnapshot(
      id: 'integration-camera-plan',
      calculatorId: 'field_of_view',
      formulaVersion: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      title: 'Integration camera plan',
      canonicalInputs: const {'sensorWidthMm': 36.0},
      canonicalOutputs: const {'horizontalDegrees': 40.0},
      displayContext: const {'lengthUnit': 'metric'},
      equipment: [
        AppliedEquipmentSnapshot(
          id: camera.id,
          type: SnapshotEquipmentType.camera,
          name: camera.name,
          source: 'user',
          values: const {'sensorWidthMm': 36.0, 'sensorHeightMm': 24.0},
        ),
      ],
    );
    final snapshots = DriftSnapshotRepository(database);
    await snapshots.save(snapshot);

    // Rebuild the provider tree against the same in-memory store.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);

    await tester.tap(find.byTooltip('Actions for Integration Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Archive referenced equipment?'), findsOneWidget);
    await tester.tap(find.text('Archive anyway'));
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsNothing);
    expect(
      (await repository.listCameras(includeArchived: true)).single.isArchived,
      isTrue,
    );
    final stored = await snapshots.getById(snapshot.id);
    expect(stored, isA<SupportedSnapshot<CalculationSnapshot>>());
    expect(
      (stored! as SupportedSnapshot<CalculationSnapshot>).snapshot.toJson(),
      snapshot.toJson(),
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Include archived'));
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);
    expect(find.textContaining('Archived'), findsWidgets);

    await tester.tap(find.byTooltip('Actions for Integration Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore').last);
    await tester.pumpAndSettle();
    expect(find.text('Integration Camera'), findsOneWidget);
    expect((await repository.listCameras()).single.isArchived, isFalse);
  });
}
