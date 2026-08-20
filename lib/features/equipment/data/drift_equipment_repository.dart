/// Drift-backed mapping and lifecycle operations for all equipment types.
library;

import 'package:drift/drift.dart';

import '../../../core/data/database/app_database.dart' as db;
import '../../../core/domain/repositories/equipment_repository.dart';
import '../domain/equipment.dart' as domain;

typedef UtcNow = DateTime Function();

final class DriftEquipmentRepository {
  DriftEquipmentRepository(this._database, {UtcNow? now})
    : _now = now ?? _systemUtcNow;

  final db.AppDatabase _database;
  final UtcNow _now;

  Stream<List<domain.CameraBody>> watchCameras({bool includeArchived = false}) {
    final query = _database.select(_database.cameraBodies)
      ..orderBy(<OrderingTerm Function(db.$CameraBodiesTable)>[
        (table) => OrderingTerm.asc(table.normalizedName),
      ]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    return query.watch().map(
      (rows) => List<domain.CameraBody>.unmodifiable(rows.map(_cameraFromRow)),
    );
  }

  Future<List<domain.CameraBody>> listCameras({
    bool includeArchived = false,
  }) async {
    final query = _database.select(_database.cameraBodies)
      ..orderBy(<OrderingTerm Function(db.$CameraBodiesTable)>[
        (table) => OrderingTerm.asc(table.normalizedName),
      ]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    return List<domain.CameraBody>.unmodifiable(
      (await query.get()).map(_cameraFromRow),
    );
  }

  Future<domain.CameraBody?> cameraById(String id) async {
    final row = await (_database.select(
      _database.cameraBodies,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _cameraFromRow(row);
  }

  Future<void> createCamera(domain.CameraBody camera) async {
    await _database
        .into(_database.cameraBodies)
        .insert(_cameraCompanion(camera));
  }

  Future<void> updateCamera(domain.CameraBody camera) async {
    final changed =
        await (_database.update(_database.cameraBodies)
              ..where((table) => table.id.equals(camera.id)))
            .write(_cameraCompanion(camera));
    _requireExisting(changed, camera.id);
  }

  Future<void> archiveCamera(String id) => _setCameraArchived(id, _now());
  Future<void> restoreCamera(String id) => _setCameraArchived(id, null);

  Future<void> _setCameraArchived(String id, DateTime? archivedAt) async {
    final changed =
        await (_database.update(
          _database.cameraBodies,
        )..where((table) => table.id.equals(id))).write(
          db.CameraBodiesCompanion(
            archivedAt: Value<DateTime?>(archivedAt),
            updatedAt: Value<DateTime>(_now()),
          ),
        );
    _requireExisting(changed, id);
  }

  Future<List<domain.Lens>> listLenses({bool includeArchived = false}) async {
    final query = _database.select(_database.lenses)
      ..orderBy(<OrderingTerm Function(db.$LensesTable)>[
        (table) => OrderingTerm.asc(table.normalizedName),
      ]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    return List<domain.Lens>.unmodifiable(
      (await query.get()).map(_lensFromRow),
    );
  }

  Future<domain.Lens?> lensById(String id) async {
    final row = await (_database.select(
      _database.lenses,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _lensFromRow(row);
  }

  Future<void> createLens(domain.Lens lens) async {
    await _database.into(_database.lenses).insert(_lensCompanion(lens));
  }

  Future<void> updateLens(domain.Lens lens) async {
    final changed = await (_database.update(
      _database.lenses,
    )..where((table) => table.id.equals(lens.id))).write(_lensCompanion(lens));
    _requireExisting(changed, lens.id);
  }

  Future<void> archiveLens(String id) => _setLensArchived(id, _now());
  Future<void> restoreLens(String id) => _setLensArchived(id, null);

  Future<void> _setLensArchived(String id, DateTime? archivedAt) async {
    final changed =
        await (_database.update(
          _database.lenses,
        )..where((table) => table.id.equals(id))).write(
          db.LensesCompanion(
            archivedAt: Value<DateTime?>(archivedAt),
            updatedAt: Value<DateTime>(_now()),
          ),
        );
    _requireExisting(changed, id);
  }

  Future<List<domain.NdFilter>> listFilters({
    bool includeArchived = false,
  }) async {
    final query = _database.select(_database.ndFilters)
      ..orderBy(<OrderingTerm Function(db.$NdFiltersTable)>[
        (table) => OrderingTerm.asc(table.normalizedName),
      ]);
    if (!includeArchived) {
      query.where((table) => table.archivedAt.isNull());
    }
    return List<domain.NdFilter>.unmodifiable(
      (await query.get()).map(_filterFromRow),
    );
  }

  Future<domain.NdFilter?> filterById(String id) async {
    final row = await (_database.select(
      _database.ndFilters,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : _filterFromRow(row);
  }

  Future<void> createFilter(domain.NdFilter filter) async {
    await _database.into(_database.ndFilters).insert(_filterCompanion(filter));
  }

  Future<void> updateFilter(domain.NdFilter filter) async {
    final changed =
        await (_database.update(_database.ndFilters)
              ..where((table) => table.id.equals(filter.id)))
            .write(_filterCompanion(filter));
    _requireExisting(changed, filter.id);
  }

  Future<void> archiveFilter(String id) => _setFilterArchived(id, _now());
  Future<void> restoreFilter(String id) => _setFilterArchived(id, null);

  Future<void> _setFilterArchived(String id, DateTime? archivedAt) async {
    final changed =
        await (_database.update(
          _database.ndFilters,
        )..where((table) => table.id.equals(id))).write(
          db.NdFiltersCompanion(
            archivedAt: Value<DateTime?>(archivedAt),
            updatedAt: Value<DateTime>(_now()),
          ),
        );
    _requireExisting(changed, id);
  }

  Future<List<domain.OpticalAccessory>> listAccessories({
    bool includeArchived = false,
  }) async {
    final query = _database.select(_database.opticalAccessories)
      ..orderBy(<OrderingTerm Function(db.$OpticalAccessoriesTable)>[
        (table) => OrderingTerm.asc(table.normalizedName),
      ]);
    if (!includeArchived) query.where((table) => table.archivedAt.isNull());
    return List<domain.OpticalAccessory>.unmodifiable(
      (await query.get()).map(_accessoryFromRow),
    );
  }

  Future<void> createAccessory(domain.OpticalAccessory accessory) async {
    await _database
        .into(_database.opticalAccessories)
        .insert(_accessoryCompanion(accessory));
  }

  Future<void> updateAccessory(domain.OpticalAccessory accessory) async {
    final changed =
        await (_database.update(_database.opticalAccessories)
              ..where((table) => table.id.equals(accessory.id)))
            .write(_accessoryCompanion(accessory));
    _requireExisting(changed, accessory.id);
  }

  Future<void> archiveAccessory(String id) => _setAccessoryArchived(id, _now());
  Future<void> restoreAccessory(String id) => _setAccessoryArchived(id, null);

  Future<void> _setAccessoryArchived(String id, DateTime? archivedAt) async {
    final changed =
        await (_database.update(
          _database.opticalAccessories,
        )..where((table) => table.id.equals(id))).write(
          db.OpticalAccessoriesCompanion(
            archivedAt: Value<DateTime?>(archivedAt),
            updatedAt: Value<DateTime>(_now()),
          ),
        );
    _requireExisting(changed, id);
  }

  Future<EquipmentReferenceImpact> referenceImpact(String equipmentId) async {
    final count = _database.snapshotEquipmentReferences.snapshotId.count();
    final query = _database.selectOnly(_database.snapshotEquipmentReferences)
      ..addColumns(<Expression<Object>>[count])
      ..where(
        _database.snapshotEquipmentReferences.equipmentId.equals(equipmentId),
      );
    final row = await query.getSingle();
    return EquipmentReferenceImpact(snapshotCount: row.read(count) ?? 0);
  }

  db.CameraBodiesCompanion _cameraCompanion(domain.CameraBody camera) =>
      db.CameraBodiesCompanion(
        id: Value<String>(camera.id),
        name: Value<String>(camera.name),
        normalizedName: Value<String>(camera.normalizedName),
        sensorWidthMm: Value<double>(camera.sensorWidthMm),
        sensorHeightMm: Value<double>(camera.sensorHeightMm),
        defaultCircleOfConfusionMm: Value<double?>(
          camera.defaultCircleOfConfusionMm,
        ),
        sourceType: Value<String>(_sourceToStorage(camera.provenance.source)),
        sourceNote: Value<String?>(camera.provenance.note),
        createdAt: Value<DateTime>(camera.createdAt),
        updatedAt: Value<DateTime>(camera.updatedAt),
        archivedAt: Value<DateTime?>(camera.archivedAt),
      );

  db.LensesCompanion _lensCompanion(domain.Lens lens) => db.LensesCompanion(
    id: Value<String>(lens.id),
    name: Value<String>(lens.name),
    normalizedName: Value<String>(lens.normalizedName),
    minimumFocalLengthMm: Value<double>(lens.minimumFocalLengthMm),
    maximumFocalLengthMm: Value<double>(lens.maximumFocalLengthMm),
    minimumAperture: Value<double?>(lens.minimumAperture),
    maximumFocalLengthMinimumAperture: Value<double?>(
      lens.maximumFocalLengthMinimumAperture,
    ),
    minimumFocusDistanceMm: Value<double?>(lens.minimumFocusDistanceMm),
    notes: Value<String?>(lens.notes),
    sourceType: Value<String>(_sourceToStorage(lens.provenance.source)),
    sourceNote: Value<String?>(lens.provenance.note),
    createdAt: Value<DateTime>(lens.createdAt),
    updatedAt: Value<DateTime>(lens.updatedAt),
    archivedAt: Value<DateTime?>(lens.archivedAt),
  );

  db.NdFiltersCompanion _filterCompanion(domain.NdFilter filter) =>
      db.NdFiltersCompanion(
        id: Value<String>(filter.id),
        name: Value<String>(filter.name),
        normalizedName: Value<String>(filter.normalizedName),
        strengthStops: Value<double>(filter.strengthStops),
        opticalDensity: Value<double?>(filter.opticalDensity),
        filterFactor: Value<double?>(filter.filterFactor),
        notes: Value<String?>(filter.notes),
        sourceType: Value<String>(_sourceToStorage(filter.provenance.source)),
        sourceNote: Value<String?>(filter.provenance.note),
        createdAt: Value<DateTime>(filter.createdAt),
        updatedAt: Value<DateTime>(filter.updatedAt),
        archivedAt: Value<DateTime?>(filter.archivedAt),
      );

  db.OpticalAccessoriesCompanion _accessoryCompanion(
    domain.OpticalAccessory accessory,
  ) => db.OpticalAccessoriesCompanion(
    id: Value<String>(accessory.id),
    name: Value<String>(accessory.name),
    normalizedName: Value<String>(accessory.normalizedName),
    kind: Value<String>(
      accessory.kind == domain.OpticalAccessoryKind.extensionTube
          ? 'extension_tube'
          : 'teleconverter',
    ),
    value: Value<double>(accessory.value),
    notes: Value<String?>(accessory.notes),
    sourceType: Value<String>(_sourceToStorage(accessory.provenance.source)),
    sourceNote: Value<String?>(accessory.provenance.note),
    createdAt: Value<DateTime>(accessory.createdAt),
    updatedAt: Value<DateTime>(accessory.updatedAt),
    archivedAt: Value<DateTime?>(accessory.archivedAt),
  );
}

domain.CameraBody _cameraFromRow(db.CameraBody row) => domain.CameraBody(
  id: row.id,
  name: row.name,
  sensorWidthMm: row.sensorWidthMm,
  sensorHeightMm: row.sensorHeightMm,
  defaultCircleOfConfusionMm: row.defaultCircleOfConfusionMm,
  provenance: _provenance(row.sourceType, row.sourceNote),
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
  archivedAt: row.archivedAt?.toUtc(),
);

domain.Lens _lensFromRow(db.Lense row) => domain.Lens(
  id: row.id,
  name: row.name,
  minimumFocalLengthMm: row.minimumFocalLengthMm,
  maximumFocalLengthMm: row.maximumFocalLengthMm,
  minimumAperture: row.minimumAperture,
  maximumFocalLengthMinimumAperture: row.maximumFocalLengthMinimumAperture,
  minimumFocusDistanceMm: row.minimumFocusDistanceMm,
  notes: row.notes,
  provenance: _provenance(row.sourceType, row.sourceNote),
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
  archivedAt: row.archivedAt?.toUtc(),
);

domain.NdFilter _filterFromRow(db.NdFilter row) => domain.NdFilter(
  id: row.id,
  name: row.name,
  strengthStops: row.strengthStops,
  opticalDensity: row.opticalDensity,
  filterFactor: row.filterFactor,
  notes: row.notes,
  provenance: _provenance(row.sourceType, row.sourceNote),
  createdAt: row.createdAt.toUtc(),
  updatedAt: row.updatedAt.toUtc(),
  archivedAt: row.archivedAt?.toUtc(),
);

domain.OpticalAccessory _accessoryFromRow(db.OpticalAccessory row) =>
    domain.OpticalAccessory(
      id: row.id,
      name: row.name,
      kind: row.kind == 'extension_tube'
          ? domain.OpticalAccessoryKind.extensionTube
          : domain.OpticalAccessoryKind.teleconverter,
      value: row.value,
      notes: row.notes,
      provenance: _provenance(row.sourceType, row.sourceNote),
      createdAt: row.createdAt.toUtc(),
      updatedAt: row.updatedAt.toUtc(),
      archivedAt: row.archivedAt?.toUtc(),
    );

domain.EquipmentProvenance _provenance(String source, String? note) =>
    domain.EquipmentProvenance(source: _sourceFromStorage(source), note: note);

String _sourceToStorage(domain.EquipmentSource source) => switch (source) {
  domain.EquipmentSource.user => 'user',
  domain.EquipmentSource.bundled => 'bundled',
  domain.EquipmentSource.userOverride => 'user_override',
};

domain.EquipmentSource _sourceFromStorage(String source) => switch (source) {
  'user' => domain.EquipmentSource.user,
  'bundled' => domain.EquipmentSource.bundled,
  'user_override' => domain.EquipmentSource.userOverride,
  _ => throw FormatException('Unsupported equipment source: $source'),
};

void _requireExisting(int changedRows, String id) {
  if (changedRows != 1) {
    throw StateError('Equipment not found: $id');
  }
}

DateTime _systemUtcNow() => DateTime.now().toUtc();
