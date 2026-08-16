import 'package:camera_assistant/data/database/migrations.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static const version = 5;
  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final opened = await _open();
    _database = opened;
    return opened;
  }

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'camera_assistant.db');
    return openDatabase(
      path,
      version: version,
      onCreate: (db, version) => DatabaseMigrations.createSchema(db),
      onUpgrade: DatabaseMigrations.upgradeSchema,
    );
  }
}
