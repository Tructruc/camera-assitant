/// Transactional Drift persistence for immutable calculation snapshots.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/calculation_snapshot.dart';
import '../../domain/repositories/snapshot_repository.dart';
import '../database/app_database.dart' as db;

final class DriftSnapshotRepository
    implements SnapshotRepository<CalculationSnapshot> {
  const DriftSnapshotRepository(this._database);

  final db.AppDatabase _database;

  Stream<List<SnapshotReadResult<CalculationSnapshot>>>
  watchReadResultsNewestFirst() {
    final query = _database.select(_database.calculationSnapshots)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.watch().map(
      (rows) => List<SnapshotReadResult<CalculationSnapshot>>.unmodifiable(
        rows.map(_readRow),
      ),
    );
  }

  @override
  Stream<List<CalculationSnapshot>> watchNewestFirst() {
    final query = _database.select(_database.calculationSnapshots)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return query.watch().map((rows) => List.unmodifiable(rows.map(_decodeRow)));
  }

  @override
  Future<List<CalculationSnapshot>> listNewestFirst() async {
    final query = _database.select(_database.calculationSnapshots)
      ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]);
    return List.unmodifiable((await query.get()).map(_decodeRow));
  }

  @override
  Future<SnapshotReadResult<CalculationSnapshot>?> getById(String id) async {
    final row = await (_database.select(
      _database.calculationSnapshots,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    if (row.payloadVersion != CalculationSnapshot.currentPayloadVersion) {
      return UnreadableSnapshot(
        id: row.id,
        rawPayload: row.inputPayload,
        reason: 'Unsupported snapshot payload version ${row.payloadVersion}',
      );
    }
    try {
      return SupportedSnapshot(_decodeRow(row));
    } on Object catch (error) {
      return UnreadableSnapshot(
        id: row.id,
        rawPayload: row.inputPayload,
        reason: 'Snapshot payload is corrupt: $error',
      );
    }
  }

  @override
  Future<void> save(CalculationSnapshot snapshot) async {
    await _database.transaction(() async {
      await _database
          .into(_database.calculationSnapshots)
          .insert(
            db.CalculationSnapshotsCompanion.insert(
              id: snapshot.id,
              calculatorId: snapshot.calculatorId,
              formulaVersion: snapshot.formulaVersion,
              createdAt: snapshot.createdAt,
              title: snapshot.title,
              notes: Value(snapshot.notes),
              payloadVersion: snapshot.payloadVersion,
              inputPayload: jsonEncode(snapshot.canonicalInputs),
              outputPayload: jsonEncode(snapshot.canonicalOutputs),
              displayContext: jsonEncode(snapshot.displayContext),
              assumptions: jsonEncode([
                for (final item in snapshot.assumptions)
                  {'key': item.key, 'value': item.value},
              ]),
              warnings: jsonEncode([
                for (final item in snapshot.warnings)
                  {'code': item.code, 'messageKey': item.messageKey},
              ]),
              equipmentSnapshot: jsonEncode([
                for (final item in snapshot.equipment) item.toJson(),
              ]),
            ),
          );
      for (var index = 0; index < snapshot.equipment.length; index++) {
        final equipment = snapshot.equipment[index];
        await _database
            .into(_database.snapshotEquipmentReferences)
            .insert(
              db.SnapshotEquipmentReferencesCompanion.insert(
                snapshotId: snapshot.id,
                equipmentId: equipment.id,
                equipmentType: _equipmentStorageId(equipment.type),
                displayOrder: index,
              ),
            );
      }
    });
  }

  @override
  Future<void> updateMetadata(
    String id, {
    required String title,
    String? notes,
  }) async {
    if (title.trim().isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be blank');
    }
    await (_database.update(
      _database.calculationSnapshots,
    )..where((row) => row.id.equals(id))).write(
      db.CalculationSnapshotsCompanion(
        title: Value(title.trim()),
        notes: Value(notes),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.calculationSnapshots,
      )..where((row) => row.id.equals(id))).go();
    });
  }

  CalculationSnapshot _decodeRow(db.CalculationSnapshot row) {
    return CalculationSnapshot.fromJson(<String, Object?>{
      'id': row.id,
      'calculatorId': row.calculatorId,
      'formulaVersion': row.formulaVersion,
      'createdAt': row.createdAt.toUtc().toIso8601String(),
      'title': row.title,
      'notes': row.notes,
      'payloadVersion': row.payloadVersion,
      'canonicalInputs': _decodeObject(row.inputPayload),
      'canonicalOutputs': _decodeObject(row.outputPayload),
      'displayContext': _decodeObject(row.displayContext),
      'assumptions': _decodeList(row.assumptions),
      'warnings': _decodeList(row.warnings),
      'equipment': _decodeList(row.equipmentSnapshot),
    });
  }

  SnapshotReadResult<CalculationSnapshot> _readRow(db.CalculationSnapshot row) {
    if (row.payloadVersion != CalculationSnapshot.currentPayloadVersion) {
      return UnreadableSnapshot(
        id: row.id,
        rawPayload: row.inputPayload,
        reason: 'Unsupported snapshot payload version ${row.payloadVersion}',
      );
    }
    try {
      return SupportedSnapshot(_decodeRow(row));
    } on Object catch (error) {
      return UnreadableSnapshot(
        id: row.id,
        rawPayload: row.inputPayload,
        reason: 'Snapshot payload is corrupt: $error',
      );
    }
  }

  Map<String, Object?> _decodeObject(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected JSON object');
    }
    return decoded;
  }

  List<Object?> _decodeList(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List<Object?>) {
      throw const FormatException('Expected JSON list');
    }
    return decoded;
  }

  String _equipmentStorageId(SnapshotEquipmentType type) => switch (type) {
    SnapshotEquipmentType.camera => 'camera',
    SnapshotEquipmentType.lens => 'lens',
    SnapshotEquipmentType.filter => 'nd_filter',
    SnapshotEquipmentType.opticalAccessory => 'optical_accessory',
  };
}
