import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    as db;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/repositories/snapshot_repository.dart';

void main() {
  late db.AppDatabase database;
  late DriftSnapshotRepository repository;

  setUp(() {
    database = db.AppDatabase.inMemory();
    repository = DriftSnapshotRepository(database);
  });
  tearDown(() => database.close());

  CalculationSnapshot snapshot(String id, DateTime createdAt) =>
      CalculationSnapshot(
        id: id,
        calculatorId: 'long_exposure_nd',
        formulaVersion: 1,
        createdAt: createdAt,
        title: 'Ten stop exposure',
        canonicalInputs: const {'baseTimeSeconds': 1 / 30},
        canonicalOutputs: const {'filteredTimeSeconds': 34.13333333333333},
        displayContext: const {'shutter': 'conventional'},
        equipment: [
          AppliedEquipmentSnapshot(
            id: 'filter-1',
            type: SnapshotEquipmentType.filter,
            name: '10-stop ND',
            source: 'user',
            values: {'strengthStops': 10.0},
          ),
        ],
      );

  test(
    'saves transactionally and lists immutable snapshots newest first',
    () async {
      await repository.save(snapshot('older', DateTime.utc(2026, 8, 19)));
      await repository.save(snapshot('newer', DateTime.utc(2026, 8, 20)));

      final stored = await repository.listNewestFirst();
      expect(stored.map((item) => item.id), ['newer', 'older']);
      expect(
        stored.first.canonicalOutputs['filteredTimeSeconds'],
        34.13333333333333,
      );
      final references = await database
          .select(database.snapshotEquipmentReferences)
          .get();
      expect(references, hasLength(2));
    },
  );

  test('metadata update never rewrites calculation payload columns', () async {
    await repository.save(snapshot('snapshot-1', DateTime.utc(2026, 8, 20)));
    final before = await (database.select(
      database.calculationSnapshots,
    )..where((row) => row.id.equals('snapshot-1'))).getSingle();

    await repository.updateMetadata(
      'snapshot-1',
      title: 'Renamed',
      notes: 'Field note',
    );
    final after = await (database.select(
      database.calculationSnapshots,
    )..where((row) => row.id.equals('snapshot-1'))).getSingle();

    expect(after.title, 'Renamed');
    expect(after.notes, 'Field note');
    expect(after.inputPayload, before.inputPayload);
    expect(after.outputPayload, before.outputPayload);
    expect(after.equipmentSnapshot, before.equipmentSnapshot);
  });

  test('delete removes snapshot and reference rows atomically', () async {
    await repository.save(snapshot('snapshot-1', DateTime.utc(2026, 8, 20)));
    await repository.delete('snapshot-1');

    expect(await repository.listNewestFirst(), isEmpty);
    expect(
      await database.select(database.snapshotEquipmentReferences).get(),
      isEmpty,
    );
  });

  test(
    'corrupt JSON returns recovery result and preserves raw bytes',
    () async {
      await repository.save(snapshot('snapshot-1', DateTime.utc(2026, 8, 20)));
      await database.customStatement(
        'UPDATE calculation_snapshots SET input_payload = ? WHERE id = ?',
        ['{not-json', 'snapshot-1'],
      );

      final result = await repository.getById('snapshot-1');
      expect(result, isA<UnreadableSnapshot<CalculationSnapshot>>());
      final unreadable = result! as UnreadableSnapshot<CalculationSnapshot>;
      expect(unreadable.rawPayload, '{not-json');
      expect(unreadable.reason, contains('corrupt'));
      final row = await database
          .select(database.calculationSnapshots)
          .getSingle();
      expect(row.inputPayload, '{not-json');
    },
  );

  test(
    'unsupported legacy payload version is explicit and preserved',
    () async {
      await repository.save(snapshot('snapshot-1', DateTime.utc(2026, 8, 20)));
      await database.customStatement(
        'UPDATE calculation_snapshots SET payload_version = 99 WHERE id = ?',
        ['snapshot-1'],
      );

      final result = await repository.getById('snapshot-1');
      expect(result, isA<UnreadableSnapshot<CalculationSnapshot>>());
      expect(
        (result! as UnreadableSnapshot<CalculationSnapshot>).reason,
        contains('Unsupported snapshot payload version 99'),
      );
    },
  );

  test('watch emits newest-first changes', () async {
    final populated = repository.watchNewestFirst().firstWhere(
      (items) => items.isNotEmpty,
    );
    await repository.save(snapshot('snapshot-1', DateTime.utc(2026, 8, 20)));
    expect((await populated).single.id, 'snapshot-1');
  });
}
