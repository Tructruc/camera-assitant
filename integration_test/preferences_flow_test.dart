import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'support/journey.dart';

/// Quickstart scenarios 4, 22, and 23 end to end: a preference change alters
/// presentation (never canonical values), and an already saved plan keeps the
/// display context it was saved with.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('preference changes alter presentation, saved plans stay frozen', (
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

    // Both planners and calculators are reachable before any preference change.
    await tapVisible(tester, find.text('Depth of field'), delta: 300);
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await scrollToResultActions(tester, extra: 300);
    expect(find.textContaining('mm'), findsWidgets);
    await tester.tap(find.text('Save result'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Switch to imperial presentation and a conventional shutter notation.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Imperial (ft and in)'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Conventional shutter'), delta: 300);

    final preferences = await PreferencesRepository(database).load();
    expect(preferences.lengthDisplay, LengthDisplay.imperial);
    expect(preferences.shutterDisplay, ShutterDisplay.conventional);

    // The same calculation now presents imperial units.
    await tester.tap(find.text('Calculators'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Depth of field'), delta: 300);
    await tester.tap(find.text('Calculate'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining(' ft'), findsWidgets);

    // The plan saved earlier kept its own display context and raw values.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Depth of field result'));
    await tester.pumpAndSettle();
    expect(find.text('distanceUnit: metric'), findsOneWidget);
    final stored = await DriftSnapshotRepository(database).listNewestFirst();
    expect(stored, hasLength(1));
    expect(stored.single.canonicalInputs['focalLengthMm'], 50);
  });
}
