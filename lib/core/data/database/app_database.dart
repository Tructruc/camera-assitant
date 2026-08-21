/// Versioned local SQLite schema for equipment, preferences, and snapshots.
library;

// Drift table constraints intentionally refer to the column getter being
// declared; the generator rewrites those expressions against generated columns.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'app_database.g.dart';

const _sourceTypes = <String>['user', 'bundled', 'user_override'];
const _equipmentTypes = <String>[
  'camera',
  'lens',
  'nd_filter',
  'optical_accessory',
];

abstract class EquipmentTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get normalizedName => text().withLength(min: 1)();
  TextColumn get sourceType => text().check(sourceType.isIn(_sourceTypes))();
  TextColumn get sourceNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class CameraBodies extends EquipmentTable {
  RealColumn get sensorWidthMm =>
      real().check(sensorWidthMm.isBiggerThanValue(0))();
  RealColumn get sensorHeightMm =>
      real().check(sensorHeightMm.isBiggerThanValue(0))();
  RealColumn get defaultCircleOfConfusionMm => real().nullable().check(
    defaultCircleOfConfusionMm.isNull() |
        defaultCircleOfConfusionMm.isBiggerThanValue(0),
  )();
}

class Lenses extends EquipmentTable {
  RealColumn get minimumFocalLengthMm =>
      real().check(minimumFocalLengthMm.isBiggerThanValue(0))();
  RealColumn get maximumFocalLengthMm => real().check(
    maximumFocalLengthMm.isBiggerOrEqual(minimumFocalLengthMm),
  )();
  RealColumn get minimumAperture => real().nullable()();
  RealColumn get maximumFocalLengthMinimumAperture => real().nullable()();
  RealColumn get minimumFocusDistanceMm => real().nullable()();
  TextColumn get notes => text().nullable()();
}

class NdFilters extends EquipmentTable {
  RealColumn get strengthStops =>
      real().check(strengthStops.isBiggerOrEqualValue(0))();
  RealColumn get opticalDensity => real().nullable()();
  RealColumn get filterFactor => real().nullable()();
  TextColumn get notes => text().nullable()();
}

class OpticalAccessories extends EquipmentTable {
  TextColumn get kind => text().check(
    kind.isIn(const <String>['extension_tube', 'teleconverter']),
  )();
  RealColumn get value => real().check(value.isBiggerThanValue(0))();
  TextColumn get notes => text().nullable()();
}

class CalculationSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get calculatorId => text().withLength(min: 1)();
  IntColumn get formulaVersion =>
      integer().check(formulaVersion.isBiggerThanValue(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get title => text().withLength(min: 1)();
  TextColumn get notes => text().nullable()();
  IntColumn get payloadVersion =>
      integer().check(payloadVersion.isBiggerThanValue(0))();
  TextColumn get inputPayload => text()();
  TextColumn get outputPayload => text()();
  TextColumn get displayContext => text()();
  TextColumn get assumptions => text()();
  TextColumn get warnings => text()();
  TextColumn get equipmentSnapshot => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class SnapshotEquipmentReferences extends Table {
  TextColumn get snapshotId => text().references(
    CalculationSnapshots,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get equipmentId => text()();
  TextColumn get equipmentType =>
      text().check(equipmentType.isIn(_equipmentTypes))();
  IntColumn get displayOrder =>
      integer().check(displayOrder.isBiggerOrEqualValue(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    snapshotId,
    equipmentId,
    equipmentType,
  };
}

class UserPreferences extends Table {
  IntColumn get id => integer().withDefault(const Constant<int>(1))();
  TextColumn get lengthDisplay =>
      text().withDefault(const Constant<String>('metric'))();
  TextColumn get shutterDisplay =>
      text().withDefault(const Constant<String>('exact'))();
  TextColumn get fractionStep =>
      text().withDefault(const Constant<String>('third'))();
  TextColumn get themeMode =>
      text().withDefault(const Constant<String>('system'))();
  TextColumn get favoriteToolIds =>
      text().withDefault(const Constant<String>('[]'))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => const <String>['CHECK (id = 1)'];
}

class SavedLocations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1)();
  TextColumn get normalizedName => text().withLength(min: 1)();
  RealColumn get latitudeDegrees => real().check(
    latitudeDegrees.isBiggerOrEqualValue(-90) &
        latitudeDegrees.isSmallerOrEqualValue(90),
  )();
  RealColumn get longitudeDegrees => real().check(
    longitudeDegrees.isBiggerOrEqualValue(-180) &
        longitudeDegrees.isSmallerOrEqualValue(180),
  )();
  RealColumn get elevationMetres => real().nullable()();
  TextColumn get timeZoneId => text().withLength(min: 1)();
  TextColumn get source =>
      text().check(source.isIn(const <String>['manual', 'device']))();
  RealColumn get accuracyMetres => real().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(
  tables: <Type>[
    CameraBodies,
    Lenses,
    NdFilters,
    OpticalAccessories,
    CalculationSnapshots,
    SnapshotEquipmentReferences,
    UserPreferences,
    SavedLocations,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.inMemory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE UNIQUE INDEX active_camera_name '
        'ON camera_bodies(normalized_name) WHERE archived_at IS NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX active_lens_name '
        'ON lenses(normalized_name) WHERE archived_at IS NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX active_nd_filter_name '
        'ON nd_filters(normalized_name) WHERE archived_at IS NULL',
      );
      await customStatement(
        'CREATE UNIQUE INDEX active_optical_accessory_name '
        'ON optical_accessories(normalized_name) WHERE archived_at IS NULL',
      );
      await into(userPreferences).insert(const UserPreferencesCompanion());
      await customStatement(
        'CREATE UNIQUE INDEX saved_location_name ON saved_locations(normalized_name)',
      );
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 1) {
        await migrator.createAll();
      }
      if (from < 2) {
        await migrator.createTable(opticalAccessories);
        await migrator.alterTable(TableMigration(snapshotEquipmentReferences));
        await customStatement(
          'CREATE UNIQUE INDEX active_optical_accessory_name '
          'ON optical_accessories(normalized_name) WHERE archived_at IS NULL',
        );
      }
      if (from < 3) {
        await migrator.createTable(savedLocations);
        await customStatement(
          'CREATE UNIQUE INDEX saved_location_name ON saved_locations(normalized_name)',
        );
      }
    },
  );
}
