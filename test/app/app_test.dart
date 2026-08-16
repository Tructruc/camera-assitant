import 'package:camera_assistant/app/app.dart';
import 'package:camera_assistant/app/app_dependencies.dart';
import 'package:camera_assistant/data/lenses/lens_repository.dart';
import 'package:camera_assistant/data/settings/settings_repository.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app loads settings through injected repository', (tester) async {
    await tester.pumpWidget(
      CameraAssistantApp(
        dependencies: AppDependencies(
          lenses: _FakeLensRepository(),
          settings: _FakeSettingsRepository(
            const AppSettings(
              homeToolOrder: [
                'long_exposure',
                'exposure',
                'dof',
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Photography toolkit'), findsOneWidget);
    expect(find.text('Long Exposure'), findsOneWidget);
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  final AppSettings settings;

  @override
  Future<AppSettings> getAppSettings() async => settings;

  @override
  Future<void> saveAppSettings(AppSettings settings) async {}
}

class _FakeLensRepository implements LensRepository {
  @override
  Future<void> deleteLens(int id) {
    throw UnimplementedError();
  }

  @override
  Future<String> exportLensLibrary() {
    throw UnimplementedError();
  }

  @override
  Future<List<Lens>> getLenses() {
    throw UnimplementedError();
  }

  @override
  Future<int> importLensLibrary(
    String raw, {
    bool replaceExisting = true,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Lens> insertLens(Lens lens) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateLens(Lens lens) {
    throw UnimplementedError();
  }
}
