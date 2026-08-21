/// Application-level dependency providers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/database/app_database.dart'
    hide CalculationSnapshot, SavedLocation;
import '../core/data/database/database_factory.dart';
import '../core/data/repositories/drift_snapshot_repository.dart';
import '../core/data/repositories/preferences_repository.dart';
import '../core/domain/calculation_snapshot.dart';
import '../core/domain/repositories/snapshot_repository.dart';
import '../features/equipment/data/drift_equipment_repository.dart';
import '../features/planning/data/saved_location_repository.dart';
import '../features/planning/domain/saved_location.dart';

final Provider<AppDatabase> appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = openAppDatabase();
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

final Provider<PreferencesRepository> preferencesRepositoryProvider =
    Provider<PreferencesRepository>((ref) {
      return PreferencesRepository(ref.watch(appDatabaseProvider));
    });

final Provider<DriftEquipmentRepository> equipmentRepositoryProvider =
    Provider<DriftEquipmentRepository>((ref) {
      return DriftEquipmentRepository(ref.watch(appDatabaseProvider));
    });

final Provider<DriftSnapshotRepository> snapshotRepositoryProvider =
    Provider<DriftSnapshotRepository>((ref) {
      return DriftSnapshotRepository(ref.watch(appDatabaseProvider));
    });

final savedLocationRepositoryProvider = Provider<SavedLocationRepository>(
  (ref) => SavedLocationRepository(ref.watch(appDatabaseProvider)),
);
final savedLocationsProvider = StreamProvider<List<SavedLocation>>(
  (ref) => ref.watch(savedLocationRepositoryProvider).watchAll(),
);

final StreamProvider<List<SnapshotReadResult<CalculationSnapshot>>>
savedSnapshotsProvider =
    StreamProvider<List<SnapshotReadResult<CalculationSnapshot>>>((ref) {
      return ref
          .watch(snapshotRepositoryProvider)
          .watchReadResultsNewestFirst();
    });

final StreamProvider<AppPreferences> preferencesProvider =
    StreamProvider<AppPreferences>((ref) {
      return ref.watch(preferencesRepositoryProvider).watch();
    });
