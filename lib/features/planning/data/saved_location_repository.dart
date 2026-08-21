import 'package:drift/drift.dart';

import '../../../core/data/database/app_database.dart' as db;
import '../domain/saved_location.dart';

final class SavedLocationRepository {
  const SavedLocationRepository(this.database);
  final db.AppDatabase database;
  Stream<List<SavedLocation>> watchAll() =>
      (database.select(database.savedLocations)
            ..orderBy([(row) => OrderingTerm.asc(row.normalizedName)]))
          .watch()
          .map((rows) => List.unmodifiable(rows.map(_map)));
  Future<List<SavedLocation>> listAll() async => List.unmodifiable(
    (await (database.select(
      database.savedLocations,
    )..orderBy([(row) => OrderingTerm.asc(row.normalizedName)])).get()).map(
      _map,
    ),
  );
  Future<void> save(SavedLocation location) => database
      .into(database.savedLocations)
      .insertOnConflictUpdate(
        db.SavedLocationsCompanion.insert(
          id: location.id,
          name: location.name,
          normalizedName: location.normalizedName,
          latitudeDegrees: location.latitudeDegrees,
          longitudeDegrees: location.longitudeDegrees,
          elevationMetres: Value(location.elevationMetres),
          timeZoneId: location.timeZoneId,
          source: location.source.name,
          accuracyMetres: Value(location.accuracyMetres),
          createdAt: location.createdAt,
          updatedAt: location.updatedAt,
        ),
      );
  Future<void> delete(String id) => (database.delete(
    database.savedLocations,
  )..where((row) => row.id.equals(id))).go();
  SavedLocation _map(db.SavedLocation row) => SavedLocation(
    id: row.id,
    name: row.name,
    latitudeDegrees: row.latitudeDegrees,
    longitudeDegrees: row.longitudeDegrees,
    elevationMetres: row.elevationMetres,
    timeZoneId: row.timeZoneId,
    source: LocationSource.values.byName(row.source),
    accuracyMetres: row.accuracyMetres,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}
