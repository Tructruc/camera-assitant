import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

import 'support/journey.dart';

/// Quickstart scenario 24 end to end: the Milky Way core reports its projected
/// orientation with the declared convention, and a saved plan keeps both the
/// value and the convention when it is reopened.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Milky Way plan keeps its orientation and convention', (
    tester,
  ) async {
    configureJourneyView(tester);
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

    await tapVisible(tester, find.text('Night-sky planner'), delta: 300);
    await tapVisible(tester, find.text('Plan night sky'), delta: 300);

    // The core preset is the default target, so the orientation row is present
    // without changing the target list. It now lives in the collapsed Details
    // section of the result card.
    await openSection(tester, 'Details');
    await reveal(tester, find.text('Milky Way orientation'));
    expect(find.text('Milky Way orientation'), findsOneWidget);
    expect(find.textContaining('relative to horizon'), findsWidgets);
    expect(
      find.textContaining(AstronomyCalculator.milkyWayOrientationConvention),
      findsWidgets,
    );

    await scrollToResultActions(tester, extra: 500);
    await tester.tap(find.widgetWithText(FilledButton, 'Save result'));
    await tester.pumpAndSettle();

    final stored = await DriftSnapshotRepository(database).listNewestFirst();
    expect(stored, hasLength(1));
    final saved = stored.single;
    expect(saved.calculatorId, 'astronomy');
    expect(saved.canonicalOutputs['milkyWayOrientationDegrees'], isNotNull);
    expect(
      saved.displayContext['milkyWayOrientationConvention'],
      AstronomyCalculator.milkyWayOrientationConvention,
    );

    // Reopening from Saved shows the same convention, not a recomputation.
    await tester.pageBack();
    await tester.pumpAndSettle();
    // Navigation destinations are always on screen, so they need no scroll.
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.text('Milky Way core night-sky plan'),
      delta: 300,
    );
    await reveal(tester, find.textContaining('milkyWayOrientationConvention'));
    expect(
      find.textContaining('milkyWayOrientationConvention:'),
      findsOneWidget,
    );
  });
}
