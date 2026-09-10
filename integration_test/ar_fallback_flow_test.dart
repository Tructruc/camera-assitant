import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

/// SC-006 / FR-012: when the live camera or orientation sensor is unavailable,
/// the AR view must explain itself without concealing the other planning views.
/// A host engine has no camera, which is exactly the unavailable case.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the AR view falls back and the numeric plan stays usable', (
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

    await tester.scrollUntilVisible(
      find.text('Night-sky planner'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Night-sky planner'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Plan night sky'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan night sky'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('AR'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('AR'));
    await tester.pumpAndSettle();

    // Either the pre-emptive capability card or the live view's own camera
    // fallback must explain the situation; never a silent blank or a crash.
    final explained =
        find.textContaining('AR unavailable').evaluate().isNotEmpty ||
        find.textContaining('Camera unavailable').evaluate().isNotEmpty;
    expect(
      explained,
      isTrue,
      reason: 'the AR view must explain an unavailable camera or sensor',
    );

    // The equivalent non-AR plan is still reachable and complete.
    await tester.scrollUntilVisible(
      find.text('Numeric'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Numeric'));
    await tester.pumpAndSettle();
    expect(find.textContaining('altitude,'), findsWidgets);
  });
}
