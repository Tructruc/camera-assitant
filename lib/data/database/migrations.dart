import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  DatabaseMigrations._();

  static Future<void> createSchema(Database db) async {
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
  }

  static Future<void> upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
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
      await db.execute('ALTER TABLE lenses ADD COLUMN filter_thread_mm REAL');
      await db.execute('ALTER TABLE lenses ADD COLUMN aperture_blades INTEGER');
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
  }
}
