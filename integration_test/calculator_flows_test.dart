import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

import '../test/fixtures/equipment_fixtures.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('calculates manually and from saved equipment offline', (
    tester,
  ) async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftEquipmentRepository(database);
    await repository.createCamera(fullFrameCameraFixture());
    await repository.createLens(standardZoomFixture());
    await repository.createFilter(tenStopFilterFixture());

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesProvider.overrideWith(
            (ref) => Stream<AppPreferences>.value(const AppPreferences()),
          ),
          equipmentRepositoryProvider.overrideWithValue(repository),
        ],
        child: const PhotographyAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Saved camera and lens values remain editable one-off inputs.
    await tester.tap(find.text('Depth of field'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24-70 mm f/2.8').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    expect(find.text('Near limit'), findsOneWidget);
    expect(find.textContaining('From 24-70 mm'), findsWidgets);
    expect(find.textContaining('connect'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    expect(find.text('Result saved on this device.'), findsOneWidget);

    // Manual exposure comparison works without inventory or network access.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exposure comparison'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Compare exposures'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Compare exposures'));
    await tester.pumpAndSettle();
    expect(find.text('Equivalent exposure'), findsOneWidget);

    // A saved ND filter applies its canonical strength to the quickstart case.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long exposure / ND'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved ND filter (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-stop ND').last);
    await tester.enterText(
      find.byKey(const Key('long-base')),
      '0.0333333333333333',
    );
    await tester.scrollUntilVisible(
      find.text('Calculate exposure'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate exposure'));
    await tester.pumpAndSettle();
    expect(find.text('34.1 s'), findsOneWidget);
    expect(find.textContaining('From 10-stop ND'), findsWidgets);

    // The snapshot survives rebuilding the app and retains its original data.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          appDatabaseProvider.overrideWithValue(database),
          preferencesProvider.overrideWith(
            (ref) => Stream<AppPreferences>.value(const AppPreferences()),
          ),
          equipmentRepositoryProvider.overrideWithValue(repository),
        ],
        child: const PhotographyAssistantApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('Depth of field result'), findsOneWidget);
    await tester.tap(find.text('Depth of field result'));
    await tester.pumpAndSettle();
    expect(find.text('focalLengthMm: 70.0'), findsOneWidget);
    expect(find.textContaining('immutable'), findsOneWidget);
  });
}
