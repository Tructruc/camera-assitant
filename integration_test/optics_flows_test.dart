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
    bool save = false,
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
    if (save) {
      // Nudge the list so the action row is fully inside the viewport before
      // tapping; a partially visible button swallows the tap.
      await tester.drag(find.byType(ListView).first, const Offset(0, -200));
      await tester.pumpAndSettle();
      final saveButton = find.widgetWithText(FilledButton, 'Save result');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(find.text('Result saved on this device.'), findsOneWidget);
    }
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
    await calculateAndExpect(tester, action: 'Calculate', expected: '500.0 mm');

    await openTool(tester, 'Macro planner');
    await calculateAndExpect(
      tester,
      action: 'Calculate macro setup',
      expected: '0.70×',
    );

    await openTool(tester, 'Panorama planner');
    await calculateAndExpect(
      tester,
      action: 'Plan panorama',
      expected: '3 columns × 2 rows',
      save: true,
    );

    // The saved panorama survives the whole offline journey.
    final snapshots = await DriftSnapshotRepository(database).listNewestFirst();
    expect(snapshots, hasLength(1));
    expect(snapshots.single.calculatorId, 'panorama');
    expect(snapshots.single.canonicalInputs['focalLengthMm'], 50);
  });
}
