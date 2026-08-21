import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide SavedLocation;
import 'package:photography_assistant/features/planning/data/saved_location_repository.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';

void main() {
  late AppDatabase database;
  late SavedLocationRepository repository;
  setUp(() {
    database = AppDatabase.inMemory();
    repository = SavedLocationRepository(database);
  });
  tearDown(() => database.close());

  test('creates, updates, watches, and deletes local locations', () async {
    final now = DateTime.utc(2026, 8, 21);
    final firstEmission = repository.watchAll().first;
    await repository.save(
      SavedLocation(
        id: 'greenwich',
        name: 'Greenwich',
        latitudeDegrees: 51.4779,
        longitudeDegrees: 0,
        elevationMetres: 46,
        timeZoneId: 'Europe/London',
        source: LocationSource.manual,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect(await firstEmission, hasLength(1));
    var saved = (await repository.listAll()).single;
    expect(saved.name, 'Greenwich');
    await repository.save(
      SavedLocation(
        id: saved.id,
        name: 'Royal Observatory',
        latitudeDegrees: saved.latitudeDegrees,
        longitudeDegrees: saved.longitudeDegrees,
        elevationMetres: saved.elevationMetres,
        timeZoneId: saved.timeZoneId,
        source: saved.source,
        createdAt: saved.createdAt,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    saved = (await repository.listAll()).single;
    expect(saved.name, 'Royal Observatory');
    await repository.delete(saved.id);
    expect(await repository.listAll(), isEmpty);
  });

  test('database rejects duplicate normalized names', () async {
    final now = DateTime.utc(2026, 8, 21);
    SavedLocation location(String id, String name) => SavedLocation(
      id: id,
      name: name,
      latitudeDegrees: 0,
      longitudeDegrees: 0,
      timeZoneId: 'UTC',
      source: LocationSource.manual,
      createdAt: now,
      updatedAt: now,
    );
    await repository.save(location('one', 'Field'));
    await expectLater(
      repository.save(location('two', ' field ')),
      throwsA(anything),
    );
  });
}
