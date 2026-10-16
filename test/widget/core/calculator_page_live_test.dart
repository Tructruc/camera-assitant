import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';

/// `CalculatorPage` owns two contracts a calculator screen depends on:
/// `onInputsChanged` still fires on every edit so a stale result can be
/// invalidated, and the optional `onCalculate` runs live but only once per
/// settled edit - never twice for one change, never after disposal, and never
/// because the screen rebuilt itself.
void main() {
  late TextEditingController input;

  setUp(() => input = TextEditingController(text: '10'));
  tearDown(() => input.dispose());

  Widget host({
    VoidCallback? onCalculate,
    Object? calculationKey,
    VoidCallback? onInputsChanged,
  }) => MaterialApp(
    home: CalculatorPage(
      inputControllers: <TextEditingController>[input],
      onInputsChanged: onInputsChanged ?? () {},
      onCalculate: onCalculate,
      calculationKey: calculationKey,
      children: const <Widget>[Text('calculator body')],
    ),
  );

  testWidgets('a live calculation runs once initially and once per settled '
      'edit', (tester) async {
    var runs = 0;
    await tester.pumpWidget(host(onCalculate: () => runs++));

    // Debounced: nothing before the delay elapses.
    expect(runs, 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    input.text = '20';
    await tester.pump();
    expect(runs, 1, reason: 'an edit must not calculate synchronously');
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 2);
  });

  testWidgets('rapid edits collapse into a single calculation', (tester) async {
    var runs = 0;
    await tester.pumpWidget(host(onCalculate: () => runs++));
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    input.text = '11';
    await tester.pump(const Duration(milliseconds: 50));
    input.text = '12';
    await tester.pump(const Duration(milliseconds: 50));
    input.text = '13';
    await tester.pump(const Duration(milliseconds: 250));

    expect(runs, 2, reason: 'three keystrokes are one recalculation');
  });

  testWidgets('an ordinary rebuild never re-schedules a calculation', (
    tester,
  ) async {
    var runs = 0;
    await tester.pumpWidget(host(onCalculate: () => runs++));
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    // A screen that rebuilds from its own result passes a fresh closure every
    // time; treating that as a change would recalculate forever.
    for (var rebuild = 0; rebuild < 3; rebuild++) {
      await tester.pumpWidget(host(onCalculate: () => runs++));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(runs, 1);
  });

  testWidgets('a changed calculation key recalculates, an unchanged one does '
      'not', (tester) async {
    var runs = 0;
    await tester.pumpWidget(
      host(onCalculate: () => runs++, calculationKey: 'location-a'),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    await tester.pumpWidget(
      host(onCalculate: () => runs++, calculationKey: 'location-b'),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 2);

    await tester.pumpWidget(
      host(onCalculate: () => runs++, calculationKey: 'location-b'),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 2);
  });

  testWidgets('a value-equal collection key never recalculates on a rebuild', (
    tester,
  ) async {
    var runs = 0;
    await tester.pumpWidget(
      host(
        onCalculate: () => runs++,
        calculationKey: <String>['metric', 'lens-1'],
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    // A screen that rebuilds also rebuilds its key list; identity is not the
    // contract, the contents are.
    for (var rebuild = 0; rebuild < 3; rebuild++) {
      await tester.pumpWidget(
        host(
          onCalculate: () => runs++,
          calculationKey: <String>['metric', 'lens-1'],
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(runs, 1);

    await tester.pumpWidget(
      host(
        onCalculate: () => runs++,
        calculationKey: <String>['imperial', 'lens-1'],
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 2);
  });

  testWidgets('disposal cancels a pending calculation', (tester) async {
    var runs = 0;
    await tester.pumpWidget(host(onCalculate: () => runs++, calculationKey: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    input.text = '99';
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));

    // A timer left behind would both run after disposal and fail this test with
    // "A Timer is still pending".
    expect(runs, 1);
  });

  testWidgets('input changes still invalidate results without a live '
      'calculation', (tester) async {
    var invalidations = 0;
    await tester.pumpWidget(host(onInputsChanged: () => invalidations++));

    input.text = '20';
    await tester.pump();
    expect(invalidations, 1);

    // No callback passed means no timer at all: the screen's explicit action is
    // the only way a heavy calculation runs.
    await tester.pump(const Duration(seconds: 1));
    expect(invalidations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection changes alone do not count as input changes', (
    tester,
  ) async {
    var invalidations = 0;
    var runs = 0;
    await tester.pumpWidget(
      host(onCalculate: () => runs++, onInputsChanged: () => invalidations++),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    input.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump(const Duration(milliseconds: 250));

    expect(invalidations, 0);
    expect(runs, 1);
  });

  testWidgets('a keyboard-free adjustment is an input change like typing', (
    tester,
  ) async {
    final interval = TextEditingController(text: '1');
    addTearDown(interval.dispose);
    var invalidations = 0;
    var runs = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculatorPage(
            inputControllers: <TextEditingController>[interval],
            onInputsChanged: () => invalidations++,
            onCalculate: () => runs++,
            children: <Widget>[
              CalculatorNumberField(
                label: 'Interval (s)',
                controller: interval,
                step: 1,
                min: 1,
                max: 10,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 1);

    // The stepper writes the same controller typing does, so the page's live
    // path - and its stale-result invalidation - has to see it too.
    await tester.tap(find.byTooltip('Increase Interval (s)'));
    await tester.pump();

    expect(interval.text, '2');
    expect(invalidations, 1);
    expect(runs, 1, reason: 'a cheap edit is debounced, not synchronous');
    await tester.pump(const Duration(milliseconds: 250));
    expect(runs, 2);
  });

  testWidgets('the page still lays out its children inside a scroll view', (
    tester,
  ) async {
    await tester.pumpWidget(host());
    expect(find.text('calculator body'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
