/// Application-level dependency providers.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/database/app_database.dart';
import '../core/data/database/database_factory.dart';
import '../core/data/repositories/preferences_repository.dart';
import '../features/equipment/data/drift_equipment_repository.dart';

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

final StreamProvider<AppPreferences> preferencesProvider =
    StreamProvider<AppPreferences>((ref) {
      return ref.watch(preferencesRepositoryProvider).watch();
    });
