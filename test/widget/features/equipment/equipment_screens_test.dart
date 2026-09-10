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
    expect(find.widgetWithText(TextFormField, 'Notes'), findsOneWidget);

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
    await tester.scrollUntilVisible(
      find.text('Save camera'),
      300,
      scrollable: find.byType(Scrollable).first,
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

  testWidgets('editor preserves a legacy bundled source', (
    WidgetTester tester,
  ) async {
    // Rows saved before the bundled catalog was withdrawn still carry this
    // source. The dropdown must offer their current value, or Flutter asserts
    // and the editor would silently rewrite the provenance.
    final camera = domain.CameraBody(
      id: 'camera-bundled',
      name: 'Bundled Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.bundled,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    domain.EquipmentItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentEditorScreen(
          kind: EquipmentKind.camera,
          item: camera,
          onSave: (item) async => saved = item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Bundled specification'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Update camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Update camera'));
    await tester.pumpAndSettle();
    expect(saved!.provenance.source, domain.EquipmentSource.bundled);
  });

  testWidgets('editor preserves an existing teleconverter kind', (
    WidgetTester tester,
  ) async {
    final converter = domain.OpticalAccessory(
      id: 'converter-1',
      name: '1.4× Converter',
      kind: domain.OpticalAccessoryKind.teleconverter,
      value: 1.4,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.user,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    domain.EquipmentItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EquipmentEditorScreen(
          kind: EquipmentKind.accessory,
          item: converter,
          onSave: (item) async => saved = item,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The dropdown must reflect the edited item, not the first menu entry.
    expect(
      find.widgetWithText(TextFormField, 'Magnification factor (×)'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Extension length (mm)'),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.text('Update optical accessory'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Update optical accessory'));
    await tester.pumpAndSettle();
    expect(
      (saved! as domain.OpticalAccessory).kind,
      domain.OpticalAccessoryKind.teleconverter,
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
        notes: 'Keep on duplicate',
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
    await tester.scrollUntilVisible(
      find.text('Save camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save camera'));
    await tester.pumpAndSettle();

    final cameras = await repository.listCameras();
    expect(cameras, hasLength(2));
    expect(cameras.map((item) => item.id).toSet(), hasLength(2));
    expect(
      cameras.where((item) => item.id != 'camera-copy-source').single.notes,
      'Keep on duplicate',
    );
  });

  testWidgets('referenced equipment is archived instead of deleted', (
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
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Archive referenced equipment?'), findsOneWidget);
    expect(find.textContaining('1 saved result or plan'), findsOneWidget);
    expect(find.textContaining('will not be recalculated'), findsOneWidget);
    await tester.tap(find.text('Archive anyway'));
    await tester.pumpAndSettle();
    expect(await repository.listCameras(), isEmpty);
    expect(await repository.listCameras(includeArchived: true), hasLength(1));
    expect(
      await DriftSnapshotRepository(database).getById('referencing-plan'),
      isNotNull,
    );
  });

  testWidgets('archive action retires active equipment from the inventory', (
    WidgetTester tester,
  ) async {
    final camera = domain.CameraBody(
      id: 'camera-archivable',
      name: 'Archivable Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.user,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.createCamera(camera);
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Actions for Archivable Camera'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(await repository.listCameras(), isEmpty);
    expect(await repository.listCameras(includeArchived: true), hasLength(1));

    // The archived inventory offers restore, never a second archive.
    final archivedChip = find.widgetWithText(FilterChip, 'Include archived');
    await tester.ensureVisible(archivedChip);
    await tester.pumpAndSettle();
    await tester.tap(archivedChip);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Actions for Archivable Camera'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('Actions for Archivable Camera'));
    await tester.pumpAndSettle();
    expect(find.text('Restore'), findsOneWidget);
    expect(find.text('Archive'), findsNothing);
    // The archived state is stated in words, not conveyed by colour alone.
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('picker returns the selected saved equipment', (
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
    domain.CameraBody? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: <Widget>[
              EquipmentPicker<domain.CameraBody>(
                label: 'Saved camera (optional)',
                items: <domain.CameraBody>[camera],
                itemLabel: (item) => item.name,
                onSelected: (item) => selected = item,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera').last);
    await tester.pumpAndSettle();
    expect(selected?.id, 'camera-1');
  });

  testWidgets('create, restart, and permanent delete remain fully offline', (
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
    await tester.scrollUntilVisible(
      find.text('Save camera'),
      300,
      scrollable: find.byType(Scrollable).first,
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
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete equipment?'), findsOneWidget);
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsNothing);
    expect(await repository.listCameras(includeArchived: true), isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(listApp());
    await tester.pumpAndSettle();
    expect(find.text('Restart Camera'), findsNothing);
    expect(find.textContaining('connect'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('a failed mutation is reported and changes nothing', (
    WidgetTester tester,
  ) async {
    final camera = domain.CameraBody(
      id: 'camera-failing',
      name: 'Stubborn Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: const domain.EquipmentProvenance(
        source: domain.EquipmentSource.user,
      ),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
    await repository.createCamera(camera);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          equipmentRepositoryProvider.overrideWithValue(
            _FailingEquipmentRepository(database),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: EquipmentListScreen())),
      ),
    );
    await tester.pumpAndSettle();

    // Delete: the confirmation is accepted, the write fails, the row stays.
    await tester.tap(find.byTooltip('Actions for Stubborn Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete permanently'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsOneWidget);
    expect(find.text('Stubborn Camera'), findsOneWidget);
    expect(await repository.listCameras(), hasLength(1));

    // Archive fails the same way and leaves the inventory active.
    await tester.tap(find.byTooltip('Actions for Stubborn Camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be saved'), findsWidgets);
    expect(await repository.listCameras(), hasLength(1));
    expect(await repository.listCameras(includeArchived: true), hasLength(1));
  });
}

/// Fails every equipment write, standing in for a locked or full database.
final class _FailingEquipmentRepository extends DriftEquipmentRepository {
  _FailingEquipmentRepository(super.database);

  @override
  Future<void> deleteCamera(String id) async =>
      throw StateError('write failed');

  @override
  Future<void> archiveCamera(String id) async =>
      throw StateError('write failed');
}
