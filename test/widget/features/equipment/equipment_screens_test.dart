import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    as domain;
import 'package:photography_assistant/features/equipment/presentation/equipment_controller.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_editor_screen.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_list_screen.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_picker.dart';

void main() {
  final timestamp = DateTime.utc(2026, 8, 19);
  late AppDatabase database;
  late DriftEquipmentRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftEquipmentRepository(
      database,
      now: () => DateTime.utc(2030),
    );
  });

  tearDown(() => database.close());

  Widget listApp({double textScale = 1}) {
    return ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        equipmentRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const EquipmentListScreen(),
        ),
      ),
    );
  }

  testWidgets('list exposes an accessible empty state and create action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();

    expect(find.text('No equipment yet'), findsOneWidget);
    expect(find.text('Add equipment'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Add equipment',
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('list identifies saved type and provenance', (
    WidgetTester tester,
  ) async {
    await repository.createCamera(
      domain.CameraBody(
        id: 'camera-1',
        name: 'Field Camera',
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        provenance: const domain.EquipmentProvenance(
          source: domain.EquipmentSource.userOverride,
          note: 'Measured',
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();

    expect(find.text('Field Camera'), findsOneWidget);
    expect(find.text('Camera · User override'), findsOneWidget);
    expect(find.text('Measured'), findsOneWidget);
  });

  testWidgets('list remains scrollable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(listApp(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets('camera editor labels units and gives inline recovery guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentEditorScreen(
          kind: EquipmentKind.camera,
          onSave: (_) async {},
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Camera name'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Source note'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'Camera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      '24',
    );
    await tester.tap(find.text('Save camera'));
    await tester.pump();

    expect(find.text('Enter a number greater than zero'), findsOneWidget);
  });

  testWidgets('accessory editor switches between tube and converter values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentEditorScreen(
          kind: EquipmentKind.accessory,
          onSave: (_) async {},
        ),
      ),
    );
    expect(find.text('Extension tube'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Extension length (mm)'),
      findsOneWidget,
    );
    await tester.tap(find.text('Extension tube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teleconverter').last);
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Magnification factor (×)'),
      findsOneWidget,
    );
  });

  testWidgets('editor prefills and updates every value of an existing lens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lens = domain.Lens(
      id: 'lens-edit',
      name: 'Original Lens',
      minimumFocalLengthMm: 24,
      maximumFocalLengthMm: 70,
      minimumAperture: 2.8,
      minimumFocusDistanceMm: 380,
      notes: 'Original notes',
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.userOverride,
        note: 'Measured',
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    domain.EquipmentItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentEditorScreen(
          kind: EquipmentKind.lens,
          item: lens,
          onSave: (item) async => saved = item,
        ),
      ),
    );

    expect(find.widgetWithText(TextFormField, 'Original Lens'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '24.0'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lens name'),
      'Updated Lens',
    );
    await tester.ensureVisible(find.text('Update lens'));
    await tester.tap(find.text('Update lens'));
    await tester.pumpAndSettle();

    expect(saved, isA<domain.Lens>());
    expect(saved!.id, lens.id);
    expect(saved!.createdAt, lens.createdAt);
    expect(saved!.name, 'Updated Lens');
  });

  testWidgets('inventory duplicates equipment with a new identity', (
    WidgetTester tester,
  ) async {
    await repository.createCamera(
      domain.CameraBody(
        id: 'camera-copy-source',
        name: 'Travel Camera',
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
        provenance: const domain.EquipmentProvenance(
          source: domain.EquipmentSource.user,
        ),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for Travel Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextFormField, 'Travel Camera copy'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    final cameras = await repository.listCameras();
    expect(cameras, hasLength(2));
    expect(cameras.map((item) => item.id).toSet(), hasLength(2));
  });

  testWidgets('referenced equipment warns before archival', (
    WidgetTester tester,
  ) async {
    final camera = domain.CameraBody(
      id: 'camera-referenced',
      name: 'Referenced Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.user,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.createCamera(camera);
    await DriftSnapshotRepository(database).save(
      CalculationSnapshot(
        id: 'referencing-plan',
        calculatorId: 'field_of_view',
        formulaVersion: 1,
        createdAt: timestamp,
        title: 'Referenced plan',
        canonicalInputs: const {'sensorWidthMm': 36.0},
        canonicalOutputs: const {'horizontalDegrees': 40.0},
        displayContext: const {'lengthUnit': 'metric'},
        equipment: [
          AppliedEquipmentSnapshot(
            id: 'camera-referenced',
            type: SnapshotEquipmentType.camera,
            name: 'Referenced Camera',
            source: 'user',
            values: {'sensorWidthMm': 36.0, 'sensorHeightMm': 24.0},
          ),
        ],
      ),
    );
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for Referenced Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Archive referenced equipment?'), findsOneWidget);
    expect(find.textContaining('1 saved result or plan'), findsOneWidget);
    expect(find.textContaining('will not be recalculated'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await repository.listCameras(), hasLength(1));
  });

  testWidgets('picker identifies source and supports a one-off override', (
    WidgetTester tester,
  ) async {
    final camera = domain.CameraBody(
      id: 'camera-1',
      name: 'Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.user,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: <Widget>[
              EquipmentPicker<domain.CameraBody>(
                label: 'Camera',
                items: <domain.CameraBody>[camera],
                itemLabel: (item) => item.name,
                onSelected: (_) {},
              ),
              EquipmentOverrideControl(
                label: 'Sensor width',
                equipmentValue: '36 mm',
                onOverrideChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('From saved equipment: 36 mm'), findsOneWidget);
    expect(find.text('Use a one-off Sensor width override'), findsOneWidget);
  });

  testWidgets('create, restart, archive, and restore remain fully offline', (
    tester,
  ) async {
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add equipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add camera'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Camera name'),
      'Restart Camera',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor width (mm)'),
      '36',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Sensor height (mm)'),
      '24',
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsOneWidget);

    await tester.tap(find.byTooltip('Actions for Restart Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsNothing);
    expect(await repository.listCameras(includeArchived: true), hasLength(1));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-800, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsOneWidget);
    await tester.tap(find.byTooltip('Actions for Restart Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsOneWidget);
    expect(find.textContaining('connect'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });
}
