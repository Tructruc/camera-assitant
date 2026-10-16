import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';

/// Covers the field-workbench workflow of the two planners: the stages are
/// grouped and named, the common choices are one tap away, and the heavy sky
/// search still runs only when the user asks for it.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

  /// The screen's own ListView: the first vertical scrollable in tree order.
  Finder screenScrollable() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 300,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: screenScrollable(),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the alignment workflow is grouped and searches only on request',
    (tester) async {
      await tester.pumpWidget(app(const AlignmentScreen()));
      await tester.pumpAndSettle();

      // Site, time, aim and geometry each name their own stage, in field order.
      for (final title in <String>[
        'Site and horizon',
        'When to look',
        'What to align',
        'Sight line',
      ]) {
        final header = find.text(title);
        await reveal(tester, header);
        expect(header, findsOneWidget, reason: '$title is missing');
      }

      // Nothing has been calculated, and editing an input does not start one.
      expect(find.byType(CalculationResultView), findsNothing);
      final latitude = find.widgetWithText(
        TextField,
        'Observer latitude (degrees)',
      );
      await reveal(tester, latitude, delta: -300);
      await tester.enterText(latitude, '40');
      await tester.pumpAndSettle();
      expect(
        find.byType(CalculationResultView),
        findsNothing,
        reason: 'a slider or keystroke must not start the alignment search',
      );

      final search = find.byKey(const Key('alignment-search'));
      await reveal(tester, search);
      expect(
        find.widgetWithText(FilledButton, 'Find alignment'),
        findsOneWidget,
      );
      await tester.tap(search);
      await tester.pumpAndSettle();
      final result = find.byType(CalculationResultView);
      await reveal(tester, result);
      expect(result, findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('a quick range chip sets the range without opening the picker', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AlignmentScreen()));
    await tester.pumpAndSettle();

    final oneDay = find.text('1 day · UTC');
    await reveal(tester, oneDay);
    expect(oneDay, findsOneWidget);

    final week = find.widgetWithText(ChoiceChip, 'Next 7 days');
    await reveal(tester, week);
    await tester.tap(week);
    await tester.pumpAndSettle();

    // The section summary sits above the chips, so it is scrolled back into
    // view before it is read.
    await reveal(tester, find.text('7 days · UTC'), delta: -300);
    expect(find.text('7 days · UTC'), findsOneWidget);
    expect(find.byType(DateRangePickerDialog), findsNothing);
    await unmount(tester);
  });

  testWidgets('editing an input clears the result and explains why', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AlignmentScreen()));
    await tester.pumpAndSettle();

    final search = find.byKey(const Key('alignment-search'));
    await reveal(tester, search);
    await tester.tap(search);
    await tester.pumpAndSettle();
    final result = find.byType(CalculationResultView);
    await reveal(tester, result);
    expect(result, findsOneWidget);

    final latitude = find.widgetWithText(
      TextField,
      'Observer latitude (degrees)',
    );
    await reveal(tester, latitude, delta: -300);
    await tester.enterText(latitude, '40');
    await tester.pumpAndSettle();

    expect(find.byType(CalculationResultView), findsNothing);
    final note = find.textContaining('Inputs changed since the last search');
    await reveal(tester, note);
    expect(note, findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'common targets are visible chips and the catalog stays searchable',
    (tester) async {
      await tester.pumpWidget(app(const AstronomyScreen()));
      await tester.pumpAndSettle();

      // Every common target is a visible, one-tap choice.
      for (final label in <String>[
        'Milky Way core',
        'Polaris',
        'Orion Nebula',
        'Andromeda (M31)',
        'Pleiades (M45)',
        'Jupiter',
        'Moon',
        'Sun',
      ]) {
        final chip = find.widgetWithText(ChoiceChip, label);
        await reveal(tester, chip);
        expect(chip, findsOneWidget, reason: '$label is not a visible choice');
      }

      // The searchable full catalogue is still there beside the shortcuts.
      expect(find.byType(DropdownMenu<CelestialTarget>), findsOneWidget);
      expect(find.text('Search celestial targets'), findsOneWidget);

      expect(find.textContaining('Solar safety:'), findsNothing);
      final sun = find.widgetWithText(ChoiceChip, 'Sun');
      await reveal(tester, sun);
      await tester.tap(sun);
      await tester.pumpAndSettle();
      final safety = find.textContaining('Solar safety:');
      await reveal(tester, safety);
      expect(safety, findsOneWidget);

      final moon = find.widgetWithText(ChoiceChip, 'Moon');
      await reveal(tester, moon, delta: -300);
      await tester.tap(moon);
      await tester.pumpAndSettle();
      expect(find.textContaining('Solar safety:'), findsNothing);
      await unmount(tester);
    },
  );

  testWidgets('a common time shortcut sets the planning instant', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();

    final chip = find.widgetWithText(ChoiceChip, 'Tonight 22:00');
    await reveal(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();

    // The shortcut means the next local 22:00, so either today's or tomorrow's
    // is correct depending on the minute the test runs in.
    final nowUtc = DateTime.now().toUtc();
    final stamp = DateFormat("yyyy-MM-dd HH:mm 'UTC'");
    final today2200 = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 22);
    final expected = <String>{
      stamp.format(today2200),
      stamp.format(today2200.add(const Duration(days: 1))),
    };
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            expected.contains(widget.data),
      ),
      findsOneWidget,
      reason: 'the displayed instant is not the next 22:00',
    );
    await unmount(tester);
  });
}
