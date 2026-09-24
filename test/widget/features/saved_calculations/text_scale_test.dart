import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CalculationSnapshot;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';

/// FR-019 for the retained surfaces: a photographer running 200% system text on
/// a small phone must still reach every saved plan and every stored section
/// inside it. The calculator forms are covered next door; these are the screens
/// that hold work already done, and nothing asserted them before.
void main() {
  late AppDatabase database;
  late DriftSnapshotRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftSnapshotRepository(database);
  });
  tearDown(() => database.close());

  Widget scaled(Widget screen) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      snapshotRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: screen),
      ),
    ),
  );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// The longest header the app writes: an observation plan with a window, an
  /// elevation and a zone.
  CalculationSnapshot nightSkyPlan() => CalculationSnapshot(
    id: 'plan-1',
    calculatorId: 'astronomy',
    formulaVersion: 1,
    createdAt: DateTime.utc(2026, 8, 20),
    title: 'Jupiter night-sky plan',
    canonicalInputs: const <String, Object?>{
      'latitudeDegrees': 48.8,
      'longitudeDegrees': 2.3,
      'observerElevationMetres': 35.0,
      'instantUtc': '2026-08-21T20:00:00.000Z',
    },
    canonicalOutputs: const <String, Object?>{
      'altitudeDegrees': 30.0,
      'aboveHorizon': true,
      'fieldChecklist': [
        {'task': 'Focus on a bright star', 'complete': false},
        {'task': 'Check the dew heater', 'complete': true},
      ],
    },
    displayContext: const <String, Object?>{
      'timeZone': 'UTC+02:00',
      'northReference': 'trueNorth',
    },
  );

  /// The alignment hero splits a formatted instant into a clock and a caption,
  /// which is the layout most likely to run out of room at 2x text.
  CalculationSnapshot alignmentPlan() => CalculationSnapshot(
    id: 'plan-2',
    calculatorId: 'sun_moon_alignment',
    formulaVersion: 2,
    createdAt: DateTime.utc(2026, 8, 22),
    title: 'Pier alignment window',
    canonicalInputs: const <String, Object?>{
      'observerLatitudeDegrees': 51.4779,
      'observerLongitudeDegrees': 0.0,
      'startUtc': '2026-08-21T23:00:00.000Z',
      'endUtc': '2026-08-23T22:59:59.999Z',
    },
    canonicalOutputs: const <String, Object?>{
      'desiredAltitudeDegrees': 12.0,
      'candidates': [
        {
          'instantUtc': '2026-08-22T18:40:00.000Z',
          'azimuthDegrees': 180.2,
          'altitudeDegrees': 11.8,
          'aboveHorizon': true,
        },
      ],
    },
    displayContext: const <String, Object?>{
      'timeZone': 'Europe/London',
      'northReference': 'trueNorth',
    },
  );

  testWidgets('the saved list stays usable at 200 percent text scale', (
    tester,
  ) async {
    phone(tester);
    final semantics = tester.ensureSemantics();
    await repository.save(nightSkyPlan());
    await repository.save(alignmentPlan());

    await tester.pumpWidget(scaled(const SavedCalculationsScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel(RegExp('.+')), findsAtLeastNWidgets(2));

    // The second stored row is reachable at 2x text, not just the first: a list
    // that overflows its viewport would still find the first row.
    final second = find.text('Pier alignment window');
    await tester.scrollUntilVisible(
      second,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(second, findsOneWidget, reason: 'the second saved plan is hidden');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('a reopened plan keeps every stored section at 200 percent text', (
    tester,
  ) async {
    phone(tester);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      scaled(SavedCalculationDetailScreen(snapshot: nightSkyPlan())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // A ListView only builds what is on screen, and the header card sits below
    // the fold at 2x text, so reaching it is part of the requirement.
    final header = find.textContaining('Time 2026-08-21 22:00 UTC+02:00');
    await tester.scrollUntilVisible(
      header,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(header, findsOneWidget);
    expect(find.text('Offline observation plan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The collapsed provenance stays reachable and complete when the type is
    // twice as large: nothing is dropped to make the layout fit.
    final section = find.text('Values used');
    await tester.scrollUntilVisible(
      section,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(section);
    await tester.pumpAndSettle();
    final raw = find.text('instantUtc: 2026-08-21T20:00:00.000Z');
    await tester.scrollUntilVisible(
      raw,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(raw, findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    semantics.dispose();
  });

  testWidgets('the alignment hero survives 200 percent text', (tester) async {
    phone(tester);

    await tester.pumpWidget(
      scaled(SavedCalculationDetailScreen(snapshot: alignmentPlan())),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Best window'), findsOneWidget);
    // The window's clock is the hero; the caption beneath it is one line.
    expect(find.text('19:40'), findsOneWidget);
    expect(find.textContaining('Europe/London'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
