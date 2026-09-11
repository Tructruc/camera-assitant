import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'support/journey.dart';

/// SC-006 / FR-012: when the live camera or orientation sensor is unavailable,
/// the AR view must explain itself without concealing the other planning views.
/// A host engine has no camera, which is exactly the unavailable case.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the AR view falls back and the numeric plan stays usable', (
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

    await tapVisible(tester, find.text('Night-sky planner'), delta: 300);
    await tapVisible(tester, find.text('Plan night sky'), delta: 300);
    await tapVisible(tester, find.text('AR'), delta: 300);

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

    // Backgrounding invalidates any in-flight camera initialization. Resuming
    // retries it and must return to an honest fallback on this camera-less
    // host instead of hanging on a spinner or throwing.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    final resumedFallback =
        find.textContaining('AR unavailable').evaluate().isNotEmpty ||
        find.textContaining('Camera unavailable').evaluate().isNotEmpty;
    expect(resumedFallback, isTrue);

    // The equivalent non-AR plan is still reachable and complete.
    await tapVisible(tester, find.text('Numeric'), delta: 300);
    expect(find.textContaining('altitude,'), findsWidgets);
  });
}
