import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';

void main() {
  late AppDatabase database;
  late PreferencesRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = PreferencesRepository(database);
  });

  tearDown(() => database.close());

  test('loads deterministic local-only defaults', () async {
    final preferences = await repository.load();

    expect(preferences.lengthDisplay, LengthDisplay.metric);
    expect(preferences.shutterDisplay, ShutterDisplay.exact);
    expect(preferences.fractionStep, FractionStep.third);
    expect(preferences.themeMode, AppThemeMode.system);
    expect(preferences.favoriteToolIds, isEmpty);
  });

  test(
    'saves and reloads stable enum identifiers and ordered favorites',
    () async {
      const updated = AppPreferences(
        lengthDisplay: LengthDisplay.imperial,
        shutterDisplay: ShutterDisplay.conventional,
        fractionStep: FractionStep.half,
        themeMode: AppThemeMode.lowLight,
        favoriteToolIds: <String>['long-exposure', 'depth-of-field'],
      );

      await repository.save(updated);
      final loaded = await repository.load();

      expect(loaded, updated);
      expect(loaded.favoriteToolIds, <String>[
        'long-exposure',
        'depth-of-field',
      ]);
    },
  );

  test('returned favorites cannot be mutated', () async {
    final preferences = await repository.load();

    expect(
      () => preferences.favoriteToolIds.add('exposure-comparison'),
      throwsUnsupportedError,
    );
  });

  test('watch emits changes after an atomic save', () async {
    final darkPreference = repository.watch().firstWhere(
      (value) => value.themeMode == AppThemeMode.dark,
    );

    await repository.save(const AppPreferences(themeMode: AppThemeMode.dark));
    expect((await darkPreference).themeMode, AppThemeMode.dark);
  });
}
