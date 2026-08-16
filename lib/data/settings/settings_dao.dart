import 'dart:convert';

import 'package:camera_assistant/data/database/app_database.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:sqflite/sqflite.dart';

class SettingsDao {
  SettingsDao({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<AppSettings> getAppSettings() async {
    final db = await _database.database;
    final rows = await db.query('app_settings');
    if (rows.isEmpty) {
      return const AppSettings();
    }

    final values = <String, String>{};
    for (final row in rows) {
      final key = row['key'];
      final value = row['value'];
      if (key is String && value is String) {
        values[key] = value;
      }
    }

    final mountIds = _decodeStringList(values['enabled_mount_ids']);
    final sensorIds = _decodeStringList(values['enabled_sensor_ids']);
    final homeToolOrder = _decodeStringList(values['home_tool_order']);
    final homeFolders = _decodeHomeFolders(values['home_folders']);
    return AppSettings(
      distanceUnit: values['distance_unit'] ?? 'm',
      timeUnit: values['time_unit'] ?? '24h',
      darkMode: values['dark_mode'] == 'true',
      enabledMountIds:
          mountIds.isEmpty ? AppSettings.defaultMountIds : mountIds,
      enabledSensorIds:
          sensorIds.isEmpty ? AppSettings.defaultSensorIds : sensorIds,
      homeToolOrder: homeToolOrder.isEmpty
          ? AppSettings.defaultHomeToolOrder
          : homeToolOrder,
      homeFolders: homeFolders,
    );
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    final db = await _database.database;
    final entries = <String, String>{
      'distance_unit': settings.distanceUnit,
      'time_unit': settings.timeUnit,
      'dark_mode': settings.darkMode.toString(),
      'enabled_mount_ids': jsonEncode(settings.enabledMountIds),
      'enabled_sensor_ids': jsonEncode(settings.enabledSensorIds),
      'home_tool_order': jsonEncode(settings.homeToolOrder),
      'home_folders': jsonEncode(
        settings.homeFolders.map((folder) => folder.toMap()).toList(),
      ),
    };

    final batch = db.batch();
    for (final entry in entries.entries) {
      batch.insert(
        'app_settings',
        {'key': entry.key, 'value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded.whereType<String>().toList();
  }

  List<HomeFolder> _decodeHomeFolders(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .map(HomeFolder.fromMap)
        .whereType<HomeFolder>()
        .toList(growable: false);
  }
}
