import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/domain/repositories/snapshot_repository.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';
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
    // The answer leads: the saved hero is readable without expanding anything.
    expect(find.text('Near limit'), findsOneWidget);
    expect(find.text('4.50 m'), findsOneWidget);
    expect(find.textContaining('immutable'), findsOneWidget);
    // Raw provenance is one deliberate step away, not deleted.
    expect(find.text('focalLengthMm: 50.0'), findsNothing);
    await _openSection(tester, 'Values used');
    expect(find.text('focalLengthMm: 50.0'), findsOneWidget);

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

  testWidgets('failed metadata and delete writes remain recoverable', (
    tester,
  ) async {
    repository = _FailingSnapshotRepository(database);
    await repository.save(_snapshot());
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Field depth'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit title and notes'));
    await tester.pumpAndSettle();
    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.labelText == 'Title',
    );
    await tester.enterText(titleField, 'Unsaved portrait setup');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.textContaining('changes are still here'), findsOneWidget);
    expect(find.text('Edit saved calculation'), findsOneWidget);
    expect(
      tester.widget<TextField>(titleField).controller!.text,
      'Unsaved portrait setup',
    );
    final unchanged = await DriftSnapshotRepository(
      database,
    ).getById('snapshot-1');
    expect(
      (unchanged! as SupportedSnapshot<CalculationSnapshot>).snapshot.title,
      'Field depth',
    );
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete saved calculation'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not be deleted'), findsOneWidget);
    expect(find.text('Field depth'), findsOneWidget);
    expect(await repository.getById('snapshot-1'), isNotNull);
    expect(tester.takeException(), isNull);
    await _disposeSubject(tester);
  });

  testWidgets('renders saved observation plans with an actionable checklist', (
    tester,
  ) async {
    await repository.save(
      CalculationSnapshot(
        id: 'plan-1',
        calculatorId: 'astronomy',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026, 8, 20),
        title: 'Jupiter plan',
        canonicalInputs: const {
          'latitudeDegrees': 48.8,
          'longitudeDegrees': 2.3,
          'instantUtc': '2026-08-21T20:00:00.000Z',
        },
        canonicalOutputs: const {
          'altitudeDegrees': 30.0,
          'aboveHorizon': true,
          'fieldChecklist': [
            {'task': 'Focus on a bright star', 'complete': false},
          ],
        },
        displayContext: const {'timeZone': 'UTC+02:00'},
      ),
    );
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jupiter plan'));
    await tester.pumpAndSettle();

    expect(find.text('Target altitude'), findsOneWidget);
    expect(find.text('30° above the horizon'), findsOneWidget);
    expect(find.text('Offline observation plan'), findsOneWidget);
    expect(find.text('Field checklist'), findsOneWidget);
    final checklistItem = find.widgetWithText(
      CheckboxListTile,
      'Focus on a bright star',
    );
    await tester.ensureVisible(checklistItem);
    await tester.pumpAndSettle();
    await tester.tap(checklistItem);
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    // The checklist stays interactive; the raw payload key never becomes text.
    await _openSection(tester, 'Exact values');
    expect(find.text('altitudeDegrees: 30.0'), findsOneWidget);
    expect(find.textContaining('fieldChecklist'), findsNothing);
    await _disposeSubject(tester);
  });

  testWidgets('a reopened plan leads with its answer, not its provenance', (
    tester,
  ) async {
    await repository.save(
      CalculationSnapshot(
        id: 'timelapse-1',
        calculatorId: 'timelapse',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026, 8, 22),
        title: 'Sunset timelapse',
        canonicalInputs: const <String, Object?>{'intervalSeconds': 10.0},
        canonicalOutputs: const <String, Object?>{
          'frameCount': 361,
          'playbackDurationSeconds': 12.033333333333333,
        },
        displayContext: const <String, Object?>{},
      ),
    );
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sunset timelapse'));
    await tester.pumpAndSettle();

    expect(find.text('Frames'), findsOneWidget);
    expect(find.text('361'), findsOneWidget);
    expect(find.textContaining('Playback 12 s'), findsOneWidget);
    expect(find.text('Values used'), findsOneWidget);
    expect(find.text('Exact values'), findsOneWidget);
    expect(find.text('intervalSeconds: 10.0'), findsNothing);
    expect(find.text('frameCount: 361'), findsNothing);

    await _openSection(tester, 'Values used');
    expect(find.text('intervalSeconds: 10.0'), findsOneWidget);
    await _openSection(tester, 'Exact values');
    expect(find.text('frameCount: 361'), findsOneWidget);
    await _disposeSubject(tester);
  });

  testWidgets('nothing stored is lost when the sections collapse', (
    tester,
  ) async {
    await repository.save(
      CalculationSnapshot(
        id: 'macro-1',
        calculatorId: 'macro',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026, 8, 23),
        title: 'Extension tube trial',
        canonicalInputs: const <String, Object?>{'extensionLengthMm': 20.0},
        canonicalOutputs: const <String, Object?>{
          'subjectWidthMm': 120.0,
          'magnification': 0.6,
        },
        displayContext: const <String, Object?>{'lengthUnit': 'imperial'},
        assumptions: const <CalculationAssumption>[
          CalculationAssumption(key: 'optics', value: 'thinLensApproximation'),
        ],
        equipment: <AppliedEquipmentSnapshot>[
          AppliedEquipmentSnapshot(
            id: 'lens-1',
            type: SnapshotEquipmentType.lens,
            name: 'Macro 100mm',
            source: 'bundled',
            values: const <String, Object?>{'focalLengthMm': 100.0},
          ),
        ],
      ),
    );
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Extension tube trial'));
    await tester.pumpAndSettle();

    // Hero uses the stored display unit (imperial) and the saved magnification.
    expect(find.text('Subject width across frame'), findsOneWidget);
    expect(find.textContaining('4.72 in'), findsOneWidget);
    expect(find.textContaining('At 0.60× magnification'), findsOneWidget);

    await _openSection(tester, 'Applied equipment');
    expect(find.textContaining('Macro 100mm: bundled'), findsOneWidget);
    await _openSection(tester, 'Display context');
    expect(find.text('lengthUnit: imperial'), findsOneWidget);
    await _openSection(tester, 'Model assumptions');
    expect(find.text('optics: thinLensApproximation'), findsOneWidget);
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

  testWidgets('renders saved warnings with a readable calculator label', (
    tester,
  ) async {
    await repository.save(
      CalculationSnapshot(
        id: 'snapshot-sun',
        calculatorId: 'sun_moon_alignment',
        formulaVersion: 1,
        createdAt: DateTime.utc(2026, 8, 21),
        title: 'Sun alignment',
        canonicalInputs: const <String, Object?>{'targetBearingDegrees': 180.0},
        canonicalOutputs: const <String, Object?>{'candidateCount': 2},
        displayContext: const <String, Object?>{'northReference': 'trueNorth'},
        warnings: const <CalculationWarning>[
          CalculationWarning(
            code: 'solarSafety',
            messageKey: 'alignment.warning.solarSafety',
          ),
        ],
      ),
    );
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.textContaining('Sun & Moon alignment'), findsOneWidget);
    await tester.tap(find.text('Sun alignment'));
    await tester.pumpAndSettle();

    expect(find.text('Warnings'), findsOneWidget);
    expect(find.textContaining('certified solar filter'), findsOneWidget);
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

/// Opens a collapsed provenance section before its rows are asserted.
Future<void> _openSection(WidgetTester tester, String title) async {
  final tile = find.text(title);
  await tester.scrollUntilVisible(
    tile,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

final class _FailingSnapshotRepository extends DriftSnapshotRepository {
  _FailingSnapshotRepository(super.database);

  @override
  Future<void> updateMetadata(
    String id, {
    required String title,
    String? notes,
  }) async => throw StateError('write failed');

  @override
  Future<void> delete(String id) async => throw StateError('write failed');
}
