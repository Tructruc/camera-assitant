import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

/// Quickstart scenarios 8 and 26 end to end: the whole journey — navigate,
/// calculate, read the labelled input summary, and save — must complete at 200%
/// system text scale on a phone-sized viewport.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the calculator journey completes at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final semantics = tester.ensureSemantics();
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
      find.text('Depth of field'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Depth of field'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    // 200% text must not overflow or clip any frame.
    expect(tester.takeException(), isNull);

    // The labelled input summary is present and exposed to assistive tech.
    await tester.scrollUntilVisible(
      find.text('Input summary'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Input summary'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Input summary')), findsWidgets);
    expect(tester.takeException(), isNull);

    // The whole action row is still reachable and usable at this scale.
    final save = find.widgetWithText(FilledButton, 'Save result');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Result saved on this device.'), findsOneWidget);
    expect(
      await DriftSnapshotRepository(database).listNewestFirst(),
      hasLength(1),
    );

    semantics.dispose();
  });
}
