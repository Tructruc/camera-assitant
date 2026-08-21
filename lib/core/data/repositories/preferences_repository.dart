/// Typed local user preferences backed by the singleton Drift record.
library;

import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

enum LengthDisplay { metric, imperial }

enum ShutterDisplay { exact, conventional }

enum FractionStep { whole, half, third }

enum AppThemeMode { system, light, dark, lowLight }

enum NorthReference { trueNorth, magneticNorth }

extension on AppThemeMode {
  String get storageId => switch (this) {
    AppThemeMode.system => 'system',
    AppThemeMode.light => 'light',
    AppThemeMode.dark => 'dark',
    AppThemeMode.lowLight => 'low_light',
  };
}

T _enumByName<T extends Enum>(Iterable<T> values, String id, String field) {
  for (final value in values) {
    final storageId = value is AppThemeMode ? value.storageId : value.name;
    if (storageId == id) {
      return value;
    }
  }
  throw FormatException('Unsupported $field preference: $id');
}

/// Immutable display preferences; canonical calculation values are unaffected.
final class AppPreferences {
  const AppPreferences({
    this.lengthDisplay = LengthDisplay.metric,
    this.shutterDisplay = ShutterDisplay.exact,
    this.fractionStep = FractionStep.third,
    this.themeMode = AppThemeMode.system,
    this.favoriteToolIds = const <String>[],
    this.northReference = NorthReference.trueNorth,
  });

  final LengthDisplay lengthDisplay;
  final ShutterDisplay shutterDisplay;
  final FractionStep fractionStep;
  final AppThemeMode themeMode;
  final List<String> favoriteToolIds;
  final NorthReference northReference;

  AppPreferences copyWith({
    LengthDisplay? lengthDisplay,
    ShutterDisplay? shutterDisplay,
    FractionStep? fractionStep,
    AppThemeMode? themeMode,
    List<String>? favoriteToolIds,
    NorthReference? northReference,
  }) => AppPreferences(
    lengthDisplay: lengthDisplay ?? this.lengthDisplay,
    shutterDisplay: shutterDisplay ?? this.shutterDisplay,
    fractionStep: fractionStep ?? this.fractionStep,
    themeMode: themeMode ?? this.themeMode,
    favoriteToolIds: favoriteToolIds ?? this.favoriteToolIds,
    northReference: northReference ?? this.northReference,
  );

  AppPreferences immutable() => AppPreferences(
    lengthDisplay: lengthDisplay,
    shutterDisplay: shutterDisplay,
    fractionStep: fractionStep,
    themeMode: themeMode,
    favoriteToolIds: List.unmodifiable(favoriteToolIds),
    northReference: northReference,
  );

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.lengthDisplay == lengthDisplay &&
      other.shutterDisplay == shutterDisplay &&
      other.fractionStep == fractionStep &&
      other.themeMode == themeMode &&
      _listEquals(other.favoriteToolIds, favoriteToolIds) &&
      other.northReference == northReference;

  @override
  int get hashCode => Object.hash(
    lengthDisplay,
    shutterDisplay,
    fractionStep,
    themeMode,
    Object.hashAll(favoriteToolIds),
    northReference,
  );
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

/// Reads and atomically replaces the single on-device preferences record.
final class PreferencesRepository {
  const PreferencesRepository(this._database);

  final AppDatabase _database;

  Future<AppPreferences> load() async {
    final row = await _database.select(_database.userPreferences).getSingle();
    return _fromRow(row);
  }

  Stream<AppPreferences> watch() {
    return _database
        .select(_database.userPreferences)
        .watchSingle()
        .map(_fromRow);
  }

  Future<void> save(AppPreferences preferences) async {
    final immutable = preferences.immutable();
    await _database.transaction(() async {
      await _database
          .into(_database.userPreferences)
          .insertOnConflictUpdate(
            UserPreferencesCompanion(
              id: const Value<int>(1),
              lengthDisplay: Value<String>(immutable.lengthDisplay.name),
              shutterDisplay: Value<String>(immutable.shutterDisplay.name),
              fractionStep: Value<String>(immutable.fractionStep.name),
              themeMode: Value<String>(immutable.themeMode.storageId),
              favoriteToolIds: Value<String>(
                jsonEncode(immutable.favoriteToolIds),
              ),
              northReference: Value<String>(immutable.northReference.name),
            ),
          );
    });
  }

  AppPreferences _fromRow(UserPreference row) {
    final decodedFavorites = jsonDecode(row.favoriteToolIds);
    if (decodedFavorites is! List<Object?>) {
      throw const FormatException('favoriteToolIds must be a JSON list');
    }
    return AppPreferences(
      lengthDisplay: _enumByName(
        LengthDisplay.values,
        row.lengthDisplay,
        'lengthDisplay',
      ),
      shutterDisplay: _enumByName(
        ShutterDisplay.values,
        row.shutterDisplay,
        'shutterDisplay',
      ),
      fractionStep: _enumByName(
        FractionStep.values,
        row.fractionStep,
        'fractionStep',
      ),
      themeMode: _enumByName(AppThemeMode.values, row.themeMode, 'themeMode'),
      favoriteToolIds: List<String>.unmodifiable(
        decodedFavorites.map((value) {
          if (value is! String) {
            throw const FormatException('favorite tool IDs must be strings');
          }
          return value;
        }),
      ),
      northReference: _enumByName(
        NorthReference.values,
        row.northReference,
        'northReference',
      ),
    );
  }
}
