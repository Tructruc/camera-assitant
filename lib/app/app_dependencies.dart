import 'package:camera_assistant/data/database/app_database.dart';
import 'package:camera_assistant/data/lenses/lens_dao.dart';
import 'package:camera_assistant/data/lenses/lens_repository.dart';
import 'package:camera_assistant/data/lenses/sqlite_lens_repository.dart';
import 'package:camera_assistant/data/settings/settings_dao.dart';
import 'package:camera_assistant/data/settings/settings_repository.dart';
import 'package:camera_assistant/data/settings/sqlite_settings_repository.dart';
import 'package:flutter/widgets.dart';

class AppDependencies {
  const AppDependencies({
    required this.lenses,
    required this.settings,
  });

  factory AppDependencies.sqlite() {
    final database = AppDatabase.instance;
    return AppDependencies(
      lenses: SqliteLensRepository(lensDao: LensDao(database: database)),
      settings: SqliteSettingsRepository(
        settingsDao: SettingsDao(database: database),
      ),
    );
  }

  final LensRepository lenses;
  final SettingsRepository settings;
}

class AppDependenciesScope extends InheritedWidget {
  const AppDependenciesScope({
    super.key,
    required this.dependencies,
    required super.child,
  });

  final AppDependencies dependencies;

  static AppDependencies of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppDependenciesScope>();
    assert(scope != null, 'No AppDependenciesScope found in context.');
    return scope!.dependencies;
  }

  static AppDependencies? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppDependenciesScope>()
        ?.dependencies;
  }

  @override
  bool updateShouldNotify(AppDependenciesScope oldWidget) {
    return dependencies != oldWidget.dependencies;
  }
}
