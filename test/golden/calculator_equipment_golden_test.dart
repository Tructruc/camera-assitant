import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody;
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late DriftEquipmentRepository equipment;

  setUp(() async {
    database = AppDatabase.inMemory();
    equipment = DriftEquipmentRepository(database);
  });
  tearDown(() => database.close());

  Widget subject(Widget child) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      preferencesProvider.overrideWith(
        (ref) => Stream<AppPreferences>.value(const AppPreferences()),
      ),
      equipmentRepositoryProvider.overrideWithValue(equipment),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );

  testWidgets('depth-of-field result remains visually stable', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(subject(const DepthOfFieldScreen()));
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/depth_of_field_result.png'),
    );
  });

  testWidgets('populated equipment inventory remains visually stable', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 21);
    await equipment.createCamera(
      CameraBody(
        id: 'golden-camera',
        name: 'Full Frame Field Camera',
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        defaultCircleOfConfusionMm: 0.03,
        provenance: const EquipmentProvenance(
          source: EquipmentSource.userOverride,
          note: 'Verified manufacturer specification',
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(subject(const EquipmentListScreen()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/equipment_inventory.png'),
    );
  });
}
