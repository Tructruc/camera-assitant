import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

/// FR-022 / SC-012: the expanded optics and capture planners need the same
/// offline acceptance journey as the first-release calculators.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> openTool(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> calculateAndExpect(
    WidgetTester tester, {
    required String action,
    required String expected,
  }) async {
    await tester.scrollUntilVisible(
      find.text(action),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(CalculationResultView), findsOneWidget);
    expect(find.textContaining(expected), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
  }

  testWidgets('expanded planners complete their offline journeys', (
    tester,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          equipmentRepositoryProvider.overrideWithValue(
            DriftEquipmentRepository(database),
          ),
        ],
        child: const PhotographyAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();

    await openTool(tester, 'Field of view');
    await calculateAndExpect(tester, action: 'Calculate', expected: '39.6°');

    await openTool(tester, 'Diffraction guidance');
    await calculateAndExpect(tester, action: 'Calculate', expected: '10.74');

    await openTool(tester, 'Focus stack planner');
    await calculateAndExpect(
      tester,
      action: 'Calculate',
      expected: 'Frame count',
    );

    await openTool(tester, 'Macro planner');
    await calculateAndExpect(
      tester,
      action: 'Calculate macro setup',
      expected: 'Magnification',
    );

    await openTool(tester, 'Panorama planner');
    await calculateAndExpect(
      tester,
      action: 'Plan panorama',
      expected: 'Total frames',
    );

    // The journeys saved nothing above, so the store stays empty offline.
    expect(await DriftSnapshotRepository(database).listNewestFirst(), isEmpty);
  });
}
