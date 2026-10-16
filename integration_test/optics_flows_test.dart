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
import 'support/journey.dart';

/// FR-022 / SC-012: the expanded optics and capture planners need the same
/// offline acceptance journey as the first-release calculators.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Opens a tool from the Plan hub, checks its answer, and goes back.
  ///
  /// These tools seed their answer and keep it live, so no Calculate action is
  /// pressed; a heavy planner would pass its own [action] instead.
  Future<void> openToolAndCheck(
    WidgetTester tester, {
    required String tool,
    String? action,
    required String expected,
    bool save = false,
  }) async {
    await tapVisibleFromTop(tester, find.text(tool), delta: 300);
    if (action != null) {
      await tapVisible(tester, find.text(action), delta: 300);
    }
    await reveal(tester, find.text('Save result'));
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
    configureJourneyView(tester);
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

    await openToolAndCheck(tester, tool: 'Field of view', expected: '39.6°');

    await openToolAndCheck(
      tester,
      tool: 'Diffraction guidance',
      expected: '10.74',
    );

    await openToolAndCheck(
      tester,
      tool: 'Focus stack planner',
      expected: '500.0 mm',
    );

    await openToolAndCheck(tester, tool: 'Macro planner', expected: '0.70×');

    await openToolAndCheck(
      tester,
      tool: 'Panorama planner',
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
