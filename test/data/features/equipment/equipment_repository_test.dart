import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    as db;
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 19, 10);
  final changedAt = DateTime.utc(2026, 8, 19, 11);
  const provenance = EquipmentProvenance(
    source: EquipmentSource.userOverride,
    note: 'Manufacturer specification',
  );
  late db.AppDatabase database;
  late DriftEquipmentRepository repository;

  setUp(() {
    database = db.AppDatabase.inMemory();
    repository = DriftEquipmentRepository(database, now: () => changedAt);
  });

  tearDown(() => database.close());

  CameraBody camera({String id = 'camera-1', String name = 'Camera'}) {
    return CameraBody(
      id: id,
      name: name,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      defaultCircleOfConfusionMm: 0.03,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  test('creates and maps cameras, lenses, and filters without loss', () async {
    final lens = Lens(
      id: 'lens-1',
      name: '24-70 mm',
      minimumFocalLengthMm: 24,
      maximumFocalLengthMm: 70,
      minimumAperture: 2.8,
      maximumFocalLengthMinimumAperture: 2.8,
      minimumFocusDistanceMm: 380,
      notes: 'Adapted lens',
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final filter = NdFilter(
      id: 'filter-1',
      name: 'ND 3',
      strengthStops: 3,
      opticalDensity: 0.9,
      filterFactor: 8,
      notes: 'Square filter',
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await repository.createCamera(camera());
    await repository.createLens(lens);
    await repository.createFilter(filter);

    final storedCamera = await repository.cameraById('camera-1');
    final storedLens = await repository.lensById('lens-1');
    final storedFilter = await repository.filterById('filter-1');
    expect(storedCamera?.sensorWidthMm, 36);
    expect(storedCamera?.provenance, provenance);
    expect(storedLens?.notes, 'Adapted lens');
    expect(storedLens?.minimumFocusDistanceMm, 380);
    expect(storedFilter?.filterFactor, 8);
    expect(storedFilter?.notes, 'Square filter');
  });

  test('updates, archives, restores, and filters active cameras', () async {
    await repository.createCamera(camera());
    final edited = CameraBody(
      id: 'camera-1',
      name: 'Renamed Camera',
      sensorWidthMm: 35.9,
      sensorHeightMm: 23.9,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: changedAt,
    );

    await repository.updateCamera(edited);
    expect((await repository.cameraById('camera-1'))?.name, 'Renamed Camera');

    await repository.archiveCamera('camera-1');
    expect(await repository.listCameras(), isEmpty);
    expect(await repository.listCameras(includeArchived: true), hasLength(1));

    await repository.restoreCamera('camera-1');
    expect(await repository.listCameras(), hasLength(1));
    expect((await repository.cameraById('camera-1'))?.archivedAt, isNull);
  });

  test('normalization enforces unique names among active items', () async {
    await repository.createCamera(camera(name: 'Full   Frame'));

    await expectLater(
      repository.createCamera(camera(id: 'camera-2', name: ' full frame ')),
      throwsA(anything),
    );

    await repository.archiveCamera('camera-1');
    await repository.createCamera(camera(id: 'camera-2', name: ' full frame '));
    expect(await repository.listCameras(), hasLength(1));
  });

  test('lens and filter update and lifecycle operations are atomic', () async {
    final lens = Lens(
      id: 'lens-1',
      name: 'Prime',
      minimumFocalLengthMm: 50,
      maximumFocalLengthMm: 50,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final filter = NdFilter(
      id: 'filter-1',
      name: 'ND 1',
      strengthStops: 1,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    await repository.createLens(lens);
    await repository.createFilter(filter);

    await repository.updateLens(
      Lens(
        id: lens.id,
        name: 'Prime updated',
        minimumFocalLengthMm: 50,
        maximumFocalLengthMm: 50,
        notes: 'Updated',
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: changedAt,
      ),
    );
    await repository.updateFilter(
      NdFilter(
        id: filter.id,
        name: 'ND 2',
        strengthStops: 2,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: changedAt,
      ),
    );
    await repository.archiveLens(lens.id);
    await repository.archiveFilter(filter.id);

    expect(await repository.listLenses(), isEmpty);
    expect(await repository.listFilters(), isEmpty);
    await repository.restoreLens(lens.id);
    await repository.restoreFilter(filter.id);
    expect((await repository.listLenses()).single.notes, 'Updated');
    expect((await repository.listFilters()).single.strengthStops, 2);
  });

  test('watch emits active inventory changes', () async {
    final populated = repository.watchCameras().firstWhere(
      (items) => items.length == 1,
    );

    await repository.createCamera(camera());

    expect((await populated).single.id, 'camera-1');
  });

  test('reference impact counts immutable snapshot links', () async {
    await repository.createCamera(camera());
    await database.customStatement(
      '''INSERT INTO calculation_snapshots
         (id, calculator_id, formula_version, created_at, title,
          payload_version, input_payload, output_payload, display_context,
          assumptions, warnings, equipment_snapshot)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      <Object>[
        'snapshot-1',
        'depth-of-field',
        1,
        createdAt.millisecondsSinceEpoch ~/ 1000,
        'Result',
        1,
        '{}',
        '{}',
        '{}',
        '[]',
        '[]',
        '{}',
      ],
    );
    await database.customStatement(
      '''INSERT INTO snapshot_equipment_references
         (snapshot_id, equipment_id, equipment_type, display_order)
         VALUES (?, ?, ?, ?)''',
      <Object>['snapshot-1', 'camera-1', 'camera', 0],
    );

    final impact = await repository.referenceImpact('camera-1');
    expect(impact.snapshotCount, 1);
    expect(impact.isReferenced, isTrue);
  });
}
