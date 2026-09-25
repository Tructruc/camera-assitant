import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'support/journey.dart';

/// Quickstart scenarios 8 and 26 end to end: the whole journey — navigate,
/// calculate, read the labelled hero answer and its collapsed values, and save —
/// must complete at 200% system text scale on a phone-sized viewport.
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

    // Filter the catalog with its own search instead of scrolling a 200%-text
    // list down to the tile: on a phone-sized emulator viewport the tile is
    // several screens down and `scrollUntilVisible` could not reach it.
    await tester.enterText(find.byType(SearchBar), 'Depth of field');
    await tester.pumpAndSettle();
    // Reveal the row first. A `ListTile` is ~200 logical pixels tall at this
    // scale, so the row the search leaves at the bottom of the list is only
    // partly inside the scrollable: its centre - the point `tap` targets - can
    // sit below the navigation bar, and the tap lands on the bar instead. This
    // went unnoticed while the journey only ever ran on the desktop host, where
    // the row happened to fit; the first emulator run failed on exactly this
    // tap (Offset(200.0, 641.0) would not hit test on the specified widget).
    await tapVisible(tester, find.widgetWithText(ListTile, 'Depth of field'));
    await tapVisible(tester, find.text('Calculate'), delta: 300);
    // 200% text must not overflow or clip any frame.
    expect(tester.takeException(), isNull);

    // The hero answer is the first thing assistive tech receives, without
    // expanding anything.
    expect(find.text('Hyperfocal distance'), findsWidgets);
    expect(
      find.bySemanticsLabel(RegExp('Depth of field result calculation result')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);

    // The collapsed provenance stays reachable and labelled at this scale.
    await openSection(tester, 'Details');
    await reveal(tester, find.text('Values used'));
    expect(find.text('Values used'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Values used')), findsWidgets);
    expect(find.text('Focal length'), findsWidgets);
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
