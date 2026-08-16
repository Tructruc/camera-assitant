import 'package:camera_assistant/domain/models/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> getAppSettings();

  Future<void> saveAppSettings(AppSettings settings);
}
