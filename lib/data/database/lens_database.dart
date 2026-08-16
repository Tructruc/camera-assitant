import 'package:camera_assistant/data/database/app_database.dart';
import 'package:camera_assistant/data/database/lens_library_transfer.dart';
import 'package:camera_assistant/data/lenses/lens_dao.dart';
import 'package:camera_assistant/data/settings/settings_dao.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:sqflite/sqflite.dart';

/// Compatibility facade for legacy screens that still access the old database
/// service directly. New code should depend on repositories instead.
class LensDatabase {
  LensDatabase._({
    AppDatabase? database,
  })  : _database = database ?? AppDatabase.instance,
        _lensDao = LensDao(database: database ?? AppDatabase.instance),
        _settingsDao = SettingsDao(database: database ?? AppDatabase.instance);

  static final LensDatabase instance = LensDatabase._();

  final AppDatabase _database;
  final LensDao _lensDao;
  final SettingsDao _settingsDao;

  Future<Database> get database => _database.database;

  Future<List<Lens>> getLenses() {
    return _lensDao.getLenses();
  }

  Future<Lens> insertLens(Lens lens) {
    return _lensDao.insertLens(lens);
  }

  Future<void> updateLens(Lens lens) {
    return _lensDao.updateLens(lens);
  }

  Future<void> deleteLens(int id) {
    return _lensDao.deleteLens(id);
  }

  Future<String> exportLensLibrary() async {
    final lenses = await _lensDao.getLenses();
    return LensLibraryTransfer.encode(lenses);
  }

  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  }) async {
    final lenses = LensLibraryTransfer.decode(raw);
    await _lensDao.replaceLenses(lenses, replaceExisting: replaceExisting);
    return lenses.length;
  }

  Future<AppSettings> getAppSettings() {
    return _settingsDao.getAppSettings();
  }

  Future<void> saveAppSettings(AppSettings settings) {
    return _settingsDao.saveAppSettings(settings);
  }
}
