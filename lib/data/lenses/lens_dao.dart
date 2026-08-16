import 'package:camera_assistant/data/database/app_database.dart';
import 'package:camera_assistant/data/lenses/lens_mapper.dart';
import 'package:camera_assistant/domain/models/lens.dart';

class LensDao {
  LensDao({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Lens>> getLenses() async {
    final db = await _database.database;
    final rows = await db.query('lenses', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(LensMapper.fromRow).toList();
  }

  Future<Lens> insertLens(Lens lens) async {
    final db = await _database.database;
    final id = await db.insert('lenses', LensMapper.toRow(lens)..remove('id'));
    return lens.copyWith(id: id);
  }

  Future<void> updateLens(Lens lens) async {
    final db = await _database.database;
    await db.update(
      'lenses',
      LensMapper.toRow(lens)..remove('id'),
      where: 'id = ?',
      whereArgs: [lens.id],
    );
  }

  Future<void> deleteLens(int id) async {
    final db = await _database.database;
    await db.delete('lenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> replaceLenses(
    List<Lens> lenses, {
    bool replaceExisting = true,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      if (replaceExisting) {
        await txn.delete('lenses');
      }

      final batch = txn.batch();
      for (final lens in lenses) {
        batch.insert('lenses', LensMapper.toRow(lens)..remove('id'));
      }
      await batch.commit(noResult: true);
    });
  }
}
