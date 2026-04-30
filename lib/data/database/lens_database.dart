import 'dart:convert';

import 'package:camera_assistant/data/database/lens_library_transfer.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LensDatabase {
  LensDatabase._();

  static final LensDatabase instance = LensDatabase._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'camera_assistant.db');
    return openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE lenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            brand TEXT,
            model TEXT,
            serial_number TEXT,
            mount TEXT,
            min_aperture REAL NOT NULL,
            min_aperture_tele REAL NOT NULL,
            max_aperture REAL NOT NULL,
            variable_aperture INTEGER NOT NULL DEFAULT 0,
            min_focal_mm REAL NOT NULL,
            max_focal_mm REAL NOT NULL,
            default_focal_mm REAL NOT NULL,
            min_focus_m REAL NOT NULL DEFAULT 0.3,
            filter_thread_mm REAL,
            aperture_blades INTEGER,
            focus_type TEXT NOT NULL DEFAULT 'manual',
            stabilization TEXT NOT NULL DEFAULT 'none',
            weight_g REAL,
            length_mm REAL,
            diameter_mm REAL,
            notes TEXT,
            purchase_date TEXT,
            purchase_price REAL,
            condition TEXT,
            ownership_status TEXT NOT NULL DEFAULT 'owned'
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE lenses ADD COLUMN min_focus_m REAL NOT NULL DEFAULT 0.3',
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE lenses ADD COLUMN min_aperture_tele REAL NOT NULL DEFAULT 2.8',
          );
          await db.execute(
            'ALTER TABLE lenses ADD COLUMN variable_aperture INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'UPDATE lenses SET min_aperture_tele = min_aperture WHERE min_aperture_tele IS NULL OR min_aperture_tele = 2.8',
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE lenses ADD COLUMN brand TEXT');
          await db.execute('ALTER TABLE lenses ADD COLUMN model TEXT');
          await db.execute('ALTER TABLE lenses ADD COLUMN serial_number TEXT');
          await db.execute('ALTER TABLE lenses ADD COLUMN mount TEXT');
          await db
              .execute('ALTER TABLE lenses ADD COLUMN filter_thread_mm REAL');
          await db
              .execute('ALTER TABLE lenses ADD COLUMN aperture_blades INTEGER');
          await db.execute(
            "ALTER TABLE lenses ADD COLUMN focus_type TEXT NOT NULL DEFAULT 'manual'",
          );
          await db.execute(
            "ALTER TABLE lenses ADD COLUMN stabilization TEXT NOT NULL DEFAULT 'none'",
          );
          await db.execute('ALTER TABLE lenses ADD COLUMN weight_g REAL');
          await db.execute('ALTER TABLE lenses ADD COLUMN length_mm REAL');
          await db.execute('ALTER TABLE lenses ADD COLUMN diameter_mm REAL');
          await db.execute('ALTER TABLE lenses ADD COLUMN notes TEXT');
          await db.execute('ALTER TABLE lenses ADD COLUMN purchase_date TEXT');
          await db.execute('ALTER TABLE lenses ADD COLUMN purchase_price REAL');
          await db.execute('ALTER TABLE lenses ADD COLUMN condition TEXT');
          await db.execute(
            "ALTER TABLE lenses ADD COLUMN ownership_status TEXT NOT NULL DEFAULT 'owned'",
          );
        }
      },
    );
  }

  Future<List<Lens>> getLenses() async {
    final db = await database;
    final rows = await db.query('lenses', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Lens.fromMap).toList();
  }

  Future<Lens> insertLens(Lens lens) async {
    final db = await database;
    final id = await db.insert('lenses', lens.toMap()..remove('id'));
    return lens.copyWith(id: id);
  }

  Future<void> updateLens(Lens lens) async {
    final db = await database;
    await db.update(
      'lenses',
      lens.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [lens.id],
    );
  }

  Future<void> deleteLens(int id) async {
    final db = await database;
    await db.delete('lenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> exportLensLibrary() async {
    final lenses = await getLenses();
    return LensLibraryTransfer.encode(lenses);
  }

  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  }) async {
    final lenses = LensLibraryTransfer.decode(raw);
    final db = await database;

    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('lenses');
      }

      final batch = txn.batch();
      for (final lens in lenses) {
        batch.insert('lenses', lens.toMap()..remove('id'));
      }
      await batch.commit(noResult: true);
    });

    return lenses.length;
  }

  Future<AppSettings> getAppSettings() async {
    final db = await database;
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
    final db = await database;
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
