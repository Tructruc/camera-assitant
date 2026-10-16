import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';

/// The saved library at scale: the tool filter stays usable when a library holds
/// many tools, and a record that cannot be read offers recovery and nothing
/// invented.
void main() {
  late AppDatabase database;
  late DriftSnapshotRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftSnapshotRepository(database);
  });
  tearDown(() => database.close());

  Widget subject() => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      snapshotRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: SavedCalculationsScreen()),
    ),
  );

  // Five tools, chosen so the alphabetical rail order is known: the first tool
  // chip after "All tools" is Depth of field.
  const manyTools = <String, (String, String)>{
    'depth_of_field': ('saved-1', 'Field depth'),
    'exposure_comparison': ('saved-2', 'Exposure swap'),
    'field_of_view': ('saved-3', 'Scene width'),
    'flash_exposure': ('saved-4', 'Flash setup'),
    'focus_stacking': ('saved-5', 'Stack plan'),
  };

  testWidgets('four stored tools keep the wrapped filter', (tester) async {
    for (final entry in manyTools.entries.take(4)) {
      await repository.save(_saved(entry.value.$1, entry.key, entry.value.$2));
    }
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.byType(CalculatorChipRail), findsNothing);
    expect(find.text('All tools'), findsOneWidget);
    for (final entry in manyTools.entries.take(4)) {
      expect(
        find.text('${_label(entry.key)} (1)'),
        findsOneWidget,
        reason: entry.key,
      );
    }
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('many tools move to the rail without losing a filter or count', (
    tester,
  ) async {
    for (final entry in manyTools.entries) {
      await repository.save(_saved(entry.value.$1, entry.key, entry.value.$2));
    }
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    // The wall of wrapped chips becomes the app's standard sideways rail, but
    // every choice, label and count survives.
    expect(find.byType(CalculatorChipRail), findsOneWidget);
    expect(find.text('All tools'), findsOneWidget);
    for (final entry in manyTools.entries) {
      expect(
        find.text('${_label(entry.key)} (1)'),
        findsOneWidget,
        reason: entry.key,
      );
    }
    for (final entry in manyTools.entries) {
      expect(find.text(entry.value.$2), findsOneWidget, reason: entry.key);
    }

    // The rail filters exactly as the wrapped chips did.
    await tester.tap(find.text('Depth of field (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Field depth'), findsOneWidget);
    expect(find.text('Exposure swap'), findsNothing);

    await tester.tap(find.text('All tools'));
    await tester.pumpAndSettle();
    expect(find.text('Exposure swap'), findsOneWidget);
    expect(find.text('Stack plan'), findsOneWidget);

    // Search and its explicit recovery survive beside the rail.
    await tester.enterText(
      find.widgetWithText(TextField, 'Search saved results'),
      'zzqq',
    );
    await tester.pumpAndSettle();
    expect(find.text('No saved results match this search'), findsOneWidget);
    await tester.tap(find.text('Clear search and filters'));
    await tester.pumpAndSettle();
    expect(find.text('Field depth'), findsOneWidget);
    expect(find.text('Stack plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });

  testWidgets('an unreadable record offers no brief, export or share', (
    tester,
  ) async {
    await database.customStatement('''
      INSERT INTO calculation_snapshots (
        id, calculator_id, formula_version, created_at, title,
        payload_version, input_payload, output_payload, display_context,
        assumptions, warnings, equipment_snapshot
      ) VALUES (
        'broken-1', 'depth_of_field', 1, 1, 'Broken result',
        1, '{broken', '{}', '{}', '[]', '[]', '[]'
      )
    ''');
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    // Recovery stays reachable and honest: the raw payload could not be read,
    // so nothing can be briefed or exported from it.
    expect(find.text('Saved calculation needs recovery'), findsOneWidget);
    expect(
      find.textContaining('original stored data was preserved'),
      findsOneWidget,
    );
    expect(find.text('Copy field brief'), findsNothing);
    expect(find.text('Copy exact JSON'), findsNothing);
    expect(find.byIcon(Icons.copy_all_outlined), findsNothing);
    expect(find.byIcon(Icons.data_object), findsNothing);
    expect(find.byIcon(Icons.ios_share), findsNothing);
    // The only offered control remains the deliberate delete.
    expect(find.byTooltip('Delete this unreadable record'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _unmount(tester);
  });
}

CalculationSnapshot _saved(String id, String calculatorId, String title) =>
    CalculationSnapshot(
      id: id,
      calculatorId: calculatorId,
      formulaVersion: 1,
      createdAt: DateTime.utc(2026, 8, 20),
      title: title,
      canonicalInputs: const <String, Object?>{},
      canonicalOutputs: const <String, Object?>{},
      displayContext: const <String, Object?>{},
    );

/// The same names the library shows, spelled out so a renamed tool fails here
/// rather than silently changing a filter label.
String _label(String calculatorId) => switch (calculatorId) {
  'depth_of_field' => 'Depth of field',
  'exposure_comparison' => 'Exposure comparison',
  'field_of_view' => 'Field of view',
  'flash_exposure' => 'Flash exposure',
  'focus_stacking' => 'Focus stack planner',
  _ => calculatorId,
};

/// A screen watching a database stream leaves a zero-duration timer pending, so
/// the tree is unmounted (and the timer flushed) before the test ends.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
}
