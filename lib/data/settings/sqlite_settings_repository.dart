import 'package:camera_assistant/data/settings/settings_dao.dart';
import 'package:camera_assistant/data/settings/settings_repository.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';

class SqliteSettingsRepository implements SettingsRepository {
  SqliteSettingsRepository({
    SettingsDao? settingsDao,
  }) : _settingsDao = settingsDao ?? SettingsDao();

  final SettingsDao _settingsDao;

  @override
  Future<AppSettings> getAppSettings() {
    return _settingsDao.getAppSettings();
  }

  @override
  Future<void> saveAppSettings(AppSettings settings) {
    return _settingsDao.saveAppSettings(settings);
  }
}
