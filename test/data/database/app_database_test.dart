import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart'
    as domain;
import 'package:photography_assistant/core/domain/repositories/snapshot_repository.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  test('current schema creates every equipment and snapshot table', () async {
    expect(database.schemaVersion, 2);

    final rows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(
      names,
      containsAll(<String>{
        'camera_bodies',
        'lenses',
        'nd_filters',
        'optical_accessories',
        'calculation_snapshots',
        'snapshot_equipment_references',
        'user_preferences',
      }),
    );
  });

  test('stable text enum constraints reject unknown values', () async {
    await expectLater(
      database.customStatement(
        '''INSERT INTO camera_bodies
           (id, name, normalized_name, sensor_width_mm, sensor_height_mm,
            source_type, created_at, updated_at)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        <Object>['c1', 'Camera', 'camera', 36.0, 24.0, 'remote', 1, 1],
      ),
      throwsA(anything),
    );
  });

  test('foreign keys prevent orphan snapshot equipment references', () async {
    await expectLater(
      database.customStatement(
        '''INSERT INTO snapshot_equipment_references
           (snapshot_id, equipment_id, equipment_type, display_order)
           VALUES (?, ?, ?, ?)''',
        <Object>['missing', 'c1', 'camera', 0],
      ),
      throwsA(anything),
    );
  });

  test('transactions roll back all writes after failure', () async {
    await expectLater(
      database.transaction(() async {
        await database.customStatement(
          '''INSERT INTO camera_bodies
             (id, name, normalized_name, sensor_width_mm, sensor_height_mm,
              source_type, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
          <Object>['c1', 'Camera', 'camera', 36.0, 24.0, 'user', 1, 1],
        );
        throw StateError('force rollback');
      }),
      throwsStateError,
    );

    final count = await database
        .customSelect('SELECT COUNT(*) AS count FROM camera_bodies')
        .getSingle();
    expect(count.read<int>('count'), 0);
  });

  test('migration strategy creates schema from an empty database', () async {
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 2);
  });

  test('frozen schema v1 fixture remains readable without data loss', () async {
    final fixture = _object(
      jsonDecode(
        await File('test/fixtures/database/schema_v1.json').readAsString(),
      ),
    );
    expect(
      _integer(fixture, 'schemaVersion'),
      lessThanOrEqualTo(database.schemaVersion),
    );
    final camera = _object(fixture['camera']);
    final preferences = _object(fixture['preferences']);
    final snapshot = _object(fixture['snapshot']);

    await database.customStatement(
      '''INSERT INTO camera_bodies
         (id, name, normalized_name, sensor_width_mm, sensor_height_mm,
          default_circle_of_confusion_mm, source_type, created_at, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      <Object>[
        _string(camera, 'id'),
        _string(camera, 'name'),
        _string(camera, 'normalizedName'),
        _number(camera, 'sensorWidthMm'),
        _number(camera, 'sensorHeightMm'),
        _number(camera, 'circleOfConfusionMm'),
        _string(camera, 'sourceType'),
        _integer(camera, 'createdAt'),
        _integer(camera, 'updatedAt'),
      ],
    );
    await database.customStatement(
      '''UPDATE user_preferences SET
         length_display = ?, shutter_display = ?, fraction_step = ?,
         theme_mode = ?, favorite_tool_ids = ? WHERE id = 1''',
      <Object>[
        _string(preferences, 'lengthDisplay'),
        _string(preferences, 'shutterDisplay'),
        _string(preferences, 'fractionStep'),
        _string(preferences, 'themeMode'),
        _string(preferences, 'favoriteToolIds'),
      ],
    );
    await database.customStatement(
      '''INSERT INTO calculation_snapshots
         (id, calculator_id, formula_version, created_at, title,
          payload_version, input_payload, output_payload, display_context,
          assumptions, warnings, equipment_snapshot)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
      <Object>[
        _string(snapshot, 'id'),
        _string(snapshot, 'calculatorId'),
        _integer(snapshot, 'formulaVersion'),
        _integer(snapshot, 'createdAt'),
        _string(snapshot, 'title'),
        _integer(snapshot, 'payloadVersion'),
        _string(snapshot, 'inputPayload'),
        _string(snapshot, 'outputPayload'),
        _string(snapshot, 'displayContext'),
        _string(snapshot, 'assumptions'),
        _string(snapshot, 'warnings'),
        _string(snapshot, 'equipmentSnapshot'),
      ],
    );
    await database.customStatement(
      '''INSERT INTO snapshot_equipment_references
         (snapshot_id, equipment_id, equipment_type, display_order)
         VALUES (?, ?, ?, ?)''',
      const <Object>['fixture-snapshot-v1', 'fixture-camera-v1', 'camera', 0],
    );

    final loadedPreferences = await PreferencesRepository(database).load();
    expect(loadedPreferences.lengthDisplay, LengthDisplay.imperial);
    expect(loadedPreferences.themeMode, AppThemeMode.lowLight);
    expect(loadedPreferences.favoriteToolIds, <String>['depth_of_field']);

    final loaded = await DriftSnapshotRepository(
      database,
    ).getById('fixture-snapshot-v1');
    final saved =
        (loaded! as SupportedSnapshot<domain.CalculationSnapshot>).snapshot;
    expect(saved.title, 'Fixture depth result');
    expect(saved.canonicalInputs['focalLengthMm'], 50.0);
    expect(saved.equipment.single.name, 'Fixture full frame');

    final references = await database
        .customSelect(
          'SELECT COUNT(*) AS count FROM snapshot_equipment_references',
        )
        .getSingle();
    expect(references.read<int>('count'), 1);
  });

  test('migrates v1 snapshot references for optical accessories', () async {
    await database.close();
    final migrated = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE calculation_snapshots (
              id TEXT NOT NULL PRIMARY KEY,
              calculator_id TEXT NOT NULL,
              formula_version INTEGER NOT NULL,
              created_at INTEGER NOT NULL,
              title TEXT NOT NULL,
              notes TEXT,
              payload_version INTEGER NOT NULL,
              input_payload TEXT NOT NULL,
              output_payload TEXT NOT NULL,
              display_context TEXT NOT NULL,
              assumptions TEXT NOT NULL,
              warnings TEXT NOT NULL,
              equipment_snapshot TEXT NOT NULL
            );
          ''');
          raw.execute('''
            CREATE TABLE snapshot_equipment_references (
              snapshot_id TEXT NOT NULL REFERENCES calculation_snapshots(id) ON DELETE CASCADE,
              equipment_id TEXT NOT NULL,
              equipment_type TEXT NOT NULL CHECK (equipment_type IN ('camera', 'lens', 'nd_filter')),
              display_order INTEGER NOT NULL CHECK (display_order >= 0),
              PRIMARY KEY (snapshot_id, equipment_id, equipment_type)
            );
          ''');
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(migrated.close);

    await migrated.customStatement('''
      INSERT INTO calculation_snapshots
      (id, calculator_id, formula_version, created_at, title, payload_version,
       input_payload, output_payload, display_context, assumptions, warnings,
       equipment_snapshot)
      VALUES ('macro-1', 'macro', 1, 1, 'Macro', 1, '{}', '{}', '{}', '[]', '[]', '[]')
    ''');
    await migrated.customStatement('''
      INSERT INTO snapshot_equipment_references
      (snapshot_id, equipment_id, equipment_type, display_order)
      VALUES ('macro-1', 'tube-1', 'optical_accessory', 0)
    ''');

    final version = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.read<int>('user_version'), 2);
    final tables = await migrated
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    expect(
      tables.map((row) => row.read<String>('name')),
      contains('optical_accessories'),
    );
  });
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) {
    throw const FormatException('Expected object');
  }
  return value;
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String) {
    throw FormatException('Expected string at $key');
  }
  return value;
}

int _integer(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! int) {
    throw FormatException('Expected integer at $key');
  }
  return value;
}

double _number(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! num) {
    throw FormatException('Expected number at $key');
  }
  return value.toDouble();
}
