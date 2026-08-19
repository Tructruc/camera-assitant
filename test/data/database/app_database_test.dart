import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  test('schema version 1 creates every foundation table', () async {
    expect(database.schemaVersion, 1);

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
    expect(version.read<int>('user_version'), 1);
  });
}
