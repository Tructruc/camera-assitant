import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/repositories/snapshot_repository.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';

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
    child: const MaterialApp(home: Scaffold(body: SavedCalculationsScreen())),
  );

  testWidgets('shows an actionable empty state', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('No saved calculations yet'), findsOneWidget);
    expect(find.textContaining('choose Save result'), findsOneWidget);
    await _disposeSubject(tester);
  });

  testWidgets('opens immutable details and edits metadata only', (
    tester,
  ) async {
    await repository.save(_snapshot());
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Field depth'));
    await tester.pumpAndSettle();
    expect(find.text('Original inputs'), findsOneWidget);
    expect(find.text('focalLengthMm: 50.0'), findsOneWidget);
    expect(find.textContaining('immutable'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit title and notes'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Field depth'),
      'Portrait setup',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Notes'),
      'Use at sunset',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = await repository.getById('snapshot-1');
    final snapshot =
        (saved! as SupportedSnapshot<CalculationSnapshot>).snapshot;
    expect(snapshot.title, 'Portrait setup');
    expect(snapshot.notes, 'Use at sunset');
    expect(snapshot.canonicalInputs['focalLengthMm'], 50.0);
    await _disposeSubject(tester);
  });

  testWidgets('requires confirmation before deletion', (tester) async {
    await repository.save(_snapshot());
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Field depth'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete saved calculation'));
    await tester.pumpAndSettle();
    expect(find.text('This cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(await repository.getById('snapshot-1'), isNull);
    await _disposeSubject(tester);
  });

  testWidgets('keeps corrupt records visible for recovery', (tester) async {
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

    expect(find.text('Saved calculation needs recovery'), findsOneWidget);
    expect(
      find.textContaining('original stored data was preserved'),
      findsOneWidget,
    );
    await _disposeSubject(tester);
  });
}

CalculationSnapshot _snapshot() => CalculationSnapshot(
  id: 'snapshot-1',
  calculatorId: 'depth_of_field',
  formulaVersion: 1,
  createdAt: DateTime.utc(2026, 8, 20),
  title: 'Field depth',
  canonicalInputs: const <String, Object?>{'focalLengthMm': 50.0},
  canonicalOutputs: const <String, Object?>{'nearLimitMm': 4500.0},
  displayContext: const <String, Object?>{'distanceUnit': 'metric'},
);

Future<void> _disposeSubject(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
}
