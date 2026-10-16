import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';

/// Copying a saved plan: the readable field brief near the answer, the exact
/// stored JSON inside the details disclosure, and what each one honestly does.
///
/// No test writes the machine's real clipboard. The widget takes an injectable
/// writer, and the one test of the production path intercepts the platform
/// channel instead.
void main() {
  late AppDatabase database;
  late DriftSnapshotRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftSnapshotRepository(database);
  });
  tearDown(() => database.close());

  /// A frame tall enough that the whole detail screen is laid out at once, so a
  /// tap target is never off screen by accident.
  void tall(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget subject(
    CalculationSnapshot snapshot, {
    Future<void> Function(String text)? copyText,
  }) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      snapshotRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: SavedCalculationDetailScreen(
        snapshot: snapshot,
        copyText: copyText,
      ),
    ),
  );

  testWidgets('the brief copy sits with the answer, above the exact values', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(subject(_snapshot()));
    await tester.pumpAndSettle();

    // The shareable form is offered where the answer is; the raw-payload action
    // stays inside the disclosure it duplicates.
    expect(find.text('Copy field brief'), findsOneWidget);
    expect(find.text('Copy exact JSON'), findsNothing);
    expect(find.textContaining('site coordinates'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Copy field brief')).dy,
      lessThan(tester.getTopLeft(find.text('Exact values')).dy),
    );
    expect(tester.takeException(), isNull);
    await _disposeSubject(tester);
  });

  testWidgets('the copied brief carries the saved plan in human words', (
    tester,
  ) async {
    tall(tester);
    final copied = <String>[];
    await tester.pumpWidget(
      subject(_snapshot(), copyText: (text) async => copied.add(text)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy field brief'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    final brief = copied.single;
    expect(brief, startsWith('Field brief — Field depth\n'));
    expect(brief, contains('Depth of field · saved 2026-08-20'));
    expect(brief, contains('Near limit: 4.50 m'));
    expect(brief, contains('Notes\nUse at sunset'));
    expect(brief, contains('Recorded inputs\n- Focal length: 50 mm'));
    // A user-initiated copy destroys nothing and asks nothing.
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Field brief copied to the clipboard.'), findsOneWidget);
    await _disposeSubject(tester);
  });

  testWidgets('a clipboard failure is reported without claiming success', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      subject(
        _snapshot(),
        copyText: (text) async => throw StateError('no clipboard'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy field brief'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The field brief could not be copied. Nothing was written to the clipboard.',
      ),
      findsOneWidget,
    );
    expect(find.text('Field brief copied to the clipboard.'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeSubject(tester);
  });

  testWidgets('the exact JSON is offered inside the details disclosure', (
    tester,
  ) async {
    tall(tester);
    final copied = <String>[];
    final record = _snapshot();
    await tester.pumpWidget(
      subject(record, copyText: (text) async => copied.add(text)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Copy exact JSON'), findsNothing);
    await _openSection(tester, 'Exact values');
    expect(find.text('Copy exact JSON'), findsOneWidget);
    expect(
      find.byTooltip(RegExp('site coordinates')),
      findsWidgets,
      reason: 'the JSON action carries the same privacy note',
    );
    // The rows the JSON mirrors are still there; the action is additive.
    expect(find.text('nearLimitMm: 4500.0'), findsOneWidget);

    await tester.tap(find.text('Copy exact JSON'));
    await tester.pumpAndSettle();

    expect(copied, hasLength(1));
    expect(jsonDecode(copied.single), record.toJson());
    expect(find.text('Exact JSON copied to the clipboard.'), findsOneWidget);
    await _disposeSubject(tester);
  });

  testWidgets('a failed JSON copy reports the failure, not a success', (
    tester,
  ) async {
    tall(tester);
    await tester.pumpWidget(
      subject(
        _snapshot(),
        copyText: (text) async => throw StateError('no clipboard'),
      ),
    );
    await tester.pumpAndSettle();
    await _openSection(tester, 'Exact values');
    await tester.tap(find.text('Copy exact JSON'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'The exact JSON could not be copied. Nothing was written to the clipboard.',
      ),
      findsOneWidget,
    );
    expect(find.text('Exact JSON copied to the clipboard.'), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeSubject(tester);
  });

  testWidgets('a session checklist tick is never copied as stored state', (
    tester,
  ) async {
    tall(tester);
    final copied = <String>[];
    await tester.pumpWidget(
      subject(_nightSkyPlan(), copyText: (text) async => copied.add(text)),
    );
    await tester.pumpAndSettle();

    // The tick is real on screen: it is session progress on an immutable record.
    final item = find.widgetWithText(
      CheckboxListTile,
      'Focus on a bright star',
    );
    await tester.tap(item);
    await tester.pump();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);

    await _openSection(tester, 'Exact values');
    await tester.tap(find.text('Copy exact JSON'));
    await tester.pumpAndSettle();

    final decoded = jsonDecode(copied.single) as Map<String, Object?>;
    final outputs = decoded['canonicalOutputs'] as Map<String, Object?>;
    final checklist = outputs['fieldChecklist'] as List<Object?>;
    expect(
      (checklist.single as Map<String, Object?>)['complete'],
      isFalse,
      reason: 'the stored record, not the on-screen progress, is exported',
    );
    expect(copied.single, contains('"complete": false'));
    await _disposeSubject(tester);
  });

  testWidgets('a plan copies with its own recorded zone, site and answer', (
    tester,
  ) async {
    tall(tester);
    final copied = <String>[];
    await tester.pumpWidget(
      subject(_nightSkyPlan(), copyText: (text) async => copied.add(text)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy field brief'));
    await tester.pumpAndSettle();

    final brief = copied.single;
    expect(brief, contains('Night-sky planner · saved 2026-08-20'));
    expect(brief, contains('Target altitude: 30° above the horizon'));
    expect(brief, contains('Site: 48.8, 2.3 · elevation 35 m'));
    expect(brief, contains('Time: 2026-08-21 22:00 UTC+02:00'));
    expect(brief, contains('Zone: UTC+02:00'));
    // The recorded reference token is copied as it was stored, not translated
    // into today's global preference.
    expect(brief, contains('Reference: trueNorth'));
    // The site the observation block already names is not repeated as a raw
    // input line.
    expect(brief, isNot(contains('Latitude:')));
    await _disposeSubject(tester);
  });

  testWidgets(
    'an unknown tool id is copied honestly, with no invented section',
    (tester) async {
      tall(tester);
      final copied = <String>[];
      await tester.pumpWidget(
        subject(
          CalculationSnapshot(
            id: 'future-1',
            calculatorId: 'future_tool',
            formulaVersion: 1,
            createdAt: DateTime.utc(2026, 8, 20),
            title: 'Untitled trial',
            canonicalInputs: const <String, Object?>{},
            canonicalOutputs: const <String, Object?>{},
            displayContext: const <String, Object?>{},
          ),
          copyText: (text) async => copied.add(text),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy field brief'));
      await tester.pumpAndSettle();

      expect(copied.single, '''
Field brief — Untitled trial
future_tool · saved 2026-08-20
Saved result: future_tool
''');
      await _disposeSubject(tester);
    },
  );

  testWidgets('an edit is what the next copy carries', (tester) async {
    tall(tester);
    await repository.save(_snapshot());
    final copied = <String>[];
    await tester.pumpWidget(
      subject(_snapshot(), copyText: (text) async => copied.add(text)),
    );
    await tester.pumpAndSettle();

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

    await tester.tap(find.text('Copy field brief'));
    await tester.pumpAndSettle();
    expect(copied.single, startsWith('Field brief — Portrait setup\n'));
    expect(copied.single, contains('Notes\nUse at sunset'));

    await _openSection(tester, 'Exact values');
    await tester.tap(find.text('Copy exact JSON'));
    await tester.pumpAndSettle();
    final decoded = jsonDecode(copied.last) as Map<String, Object?>;
    expect(decoded['title'], 'Portrait setup');
    expect(decoded['notes'], 'Use at sunset');
    await _disposeSubject(tester);
  });

  testWidgets('the production path writes through the platform clipboard', (
    tester,
  ) async {
    tall(tester);
    // No injected writer: the widget uses Clipboard.setData, and the platform
    // channel is intercepted so nothing reaches a real clipboard.
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );

    await tester.pumpWidget(subject(_snapshot()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy field brief'));
    await tester.pumpAndSettle();

    final setData = calls
        .where((call) => call.method == 'Clipboard.setData')
        .toList();
    expect(setData, hasLength(1));
    final arguments = setData.single.arguments as Map<Object?, Object?>;
    expect(arguments['text'], startsWith('Field brief — Field depth\n'));
    expect(find.text('Field brief copied to the clipboard.'), findsOneWidget);
    await _disposeSubject(tester);
  });
}

CalculationSnapshot _snapshot() => CalculationSnapshot(
  id: 'snapshot-1',
  calculatorId: 'depth_of_field',
  formulaVersion: 1,
  createdAt: DateTime.utc(2026, 8, 20),
  title: 'Field depth',
  notes: 'Use at sunset',
  canonicalInputs: const <String, Object?>{'focalLengthMm': 50.0},
  canonicalOutputs: const <String, Object?>{'nearLimitMm': 4500.0},
  displayContext: const <String, Object?>{'distanceUnit': 'metric'},
);

CalculationSnapshot _nightSkyPlan() => CalculationSnapshot(
  id: 'plan-1',
  calculatorId: 'astronomy',
  formulaVersion: 1,
  createdAt: DateTime.utc(2026, 8, 20),
  title: 'Jupiter plan',
  canonicalInputs: const <String, Object?>{
    'latitudeDegrees': 48.8,
    'longitudeDegrees': 2.3,
    'observerElevationMetres': 35.0,
    'instantUtc': '2026-08-21T20:00:00.000Z',
  },
  canonicalOutputs: const <String, Object?>{
    'altitudeDegrees': 30.0,
    'aboveHorizon': true,
    'fieldChecklist': <Object?>[
      <String, Object?>{'task': 'Focus on a bright star', 'complete': false},
    ],
  },
  displayContext: const <String, Object?>{
    'timeZone': 'UTC+02:00',
    'northReference': 'trueNorth',
  },
);

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

Future<void> _disposeSubject(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump();
}
