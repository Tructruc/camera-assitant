import 'package:camera_assistant/data/database/app_database.dart';
import 'package:camera_assistant/data/database/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('creates current schema tables', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: AppDatabase.version,
      onCreate: (db, version) => DatabaseMigrations.createSchema(db),
    );
    addTearDown(db.close);

    final tables = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ?',
      whereArgs: ['table'],
    );
    final tableNames = tables.map((row) => row['name']).toSet();

    expect(tableNames, contains('lenses'));
    expect(tableNames, contains('app_settings'));
  });
}
