import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';

/// The numeric field is the one control every calculator shares, and it is the
/// only place where a canonical raw value and a practical display unit meet.
/// These cases pin that seam: exact entry stays exact, the display is a *view*
/// of the canonical value and never a source for it, the keyboard-free controls
/// rebuild themselves from the one controller, and every parameter stays one
/// compact block.
void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController(text: '50'));
  tearDown(() => controller.dispose());

  Widget host(Widget field, {double textScale = 1}) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: Builder(
        // Only the text scale is overridden: the ambient size and pixel ratio
        // stay real, so these gates measure the field, not an artificial
        // window.
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: SingleChildScrollView(child: field),
        ),
      ),
    ),
  );

  /// The controller the *visible* text field is bound to. When an adapter is in
  /// play this is the display controller, not the canonical one.
  TextEditingController visible(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!;

  bool selectedPreset(WidgetTester tester, String label) => tester
      .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
      .selected;

  Finder railFinder() => find.descendant(
    of: find.byType(CalculatorNumberField),
    matching: find.byType(SingleChildScrollView),
  );

  Finder railFade() => find.descendant(
    of: find.byType(CalculatorNumberField),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient != null,
      description: 'preset rail edge fade',
    ),
  );

  /// Pins a phone-sized viewport for the layout gates.
  void useViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('the display/raw adapter', () {
    testWidgets('converted edits retain full canonical double precision', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Distance (m)',
            controller: controller,
            displayDivisor: 1000,
          ),
        ),
      );
      const typed = '1.234567890123456';
      await tester.enterText(find.byType(TextField), typed);
      await tester.pump();
      expect(double.parse(controller.text), double.parse(typed) * 1000);
    });

    test('the adapter converts between displayed units and raw values', () {
      expect(canonicalValueFromText('1.5', displayDivisor: 1000), 1500);
      expect(canonicalValueFromText('0.25'), 0.25);
      expect(canonicalValueFromText('-2', displayDivisor: 1000), -2000);
      expect(canonicalValueFromText('-0.5'), -0.5);
      expect(canonicalValueFromText('500'), 500);

      expect(canonicalValueFromText(''), isNull);
      expect(canonicalValueFromText('   '), isNull);
      expect(canonicalValueFromText('abc'), isNull);
      expect(canonicalValueFromText('1.2.3'), isNull);
      expect(canonicalValueFromText('1,5'), isNull);
      expect(canonicalValueFromText('Infinity'), isNull);
      expect(canonicalValueFromText('-Infinity'), isNull);
      expect(canonicalValueFromText('NaN'), isNull);
      expect(canonicalValueFromText('1e400'), isNull);
      expect(canonicalValueFromText('1', displayDivisor: 0), isNull);

      expect(textFromCanonicalValue(1500, displayDivisor: 1000), '1.5');
      expect(textFromCanonicalValue(50), '50');
      expect(textFromCanonicalValue(-1500, displayDivisor: 1000), '-1.5');
      expect(textFromCanonicalValue(0.1 + 0.2), '0.3');
      expect(double.parse(textFromCanonicalValue(1.23e-10)), 1.23e-10);
      expect(double.parse(textFromCanonicalValue(1.23e20)), 1.23e20);
      expect(
        textFromCanonicalValue(1500, displayDivisor: 1000, decimalPlaces: 2),
        '1.50',
      );
      expect(textFromCanonicalValue(double.nan), '');
    });

    test(
      'the parse the field accepts is the parse the calculators perform',
      () {
        // The field must not accept a number whose canonical text the domain's
        // own double.tryParse cannot read back.
        const accepted = <String>[
          '85',
          ' 85 ',
          '-2.5',
          '+3',
          '1500',
          '0',
          '1e3',
          '1E-3',
          '0.000125',
          '1234.56789',
        ];
        for (final text in accepted) {
          final viaAdapter = canonicalValueFromText(text);
          expect(viaAdapter, isNotNull, reason: text);
          expect(viaAdapter, double.tryParse(text.trim()), reason: text);
        }

        const refused = <String>[
          '',
          '   ',
          'abc',
          '1.2.3',
          '1,5',
          'Infinity',
          '-Infinity',
          'NaN',
          '1e400',
          '--1',
          '5mm',
        ];
        for (final text in refused) {
          expect(canonicalValueFromText(text), isNull, reason: text);
          final direct = double.tryParse(text.trim());
          expect(
            direct == null || !direct.isFinite,
            isTrue,
            reason: 'only a non-finite parse may be stricter downstream: $text',
          );
        }
      },
    );

    test('every canonical text the field can store is readable downstream', () {
      const values = <double>[
        0,
        1,
        -1,
        0.5,
        -0.5,
        1500,
        1234.56789,
        1 / 3,
        0.1 + 0.2,
        1e-7,
        1e21,
        1e300,
        5e-324,
        86400,
        0.000125,
      ];
      for (final value in values) {
        final text = textFromCanonicalValue(value);
        expect(text, isNotEmpty, reason: '$value');
        expect(text.contains(','), isFalse, reason: text);
        // Text that is not a `double.tryParse` literal at all reads as NaN here
        // and fails with the text that produced it.
        final parsed = double.tryParse(text) ?? double.nan;
        expect(parsed.isFinite, isTrue, reason: '$value -> $text');
        // The field's adapter reads the same number the calculator will.
        expect(canonicalValueFromText(text), parsed, reason: '$value -> $text');
        // Formatting never hides more than the documented twelve significant
        // digits of the value.
        expect(
          (parsed - value).abs(),
          lessThanOrEqualTo(value.abs() * 1e-11 + 1e-12),
          reason: '$value -> $text',
        );
      }
    });
  });

  group('exact entry', () {
    testWidgets('an exact field edits the canonical controller directly', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focal length (mm)',
            controller: controller,
            fieldKey: const Key('focal'),
          ),
        ),
      );

      expect(find.byKey(const Key('focal')), findsOneWidget);
      await tester.enterText(find.byKey(const Key('focal')), '85');
      await tester.pump();
      expect(controller.text, '85');

      // No bounds, no presets, no step: no keyboard-free controls are invented.
      expect(find.byType(Slider), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.byTooltip('Increase Focal length (mm)'), findsNothing);
      // Without an adapter the field is bound to the canonical controller.
      expect(visible(tester), same(controller));
    });

    testWidgets('presets write their canonical raw value', (tester) async {
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Interval (s)',
            controller: controller,
            presets: const <double>[1, 2, 4, 8],
          ),
        ),
      );

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      await tester.tap(find.widgetWithText(ChoiceChip, '4'));
      await tester.pump();
      expect(controller.text, '4');
      expect(find.byTooltip('Set Interval (s) to 4'), findsOneWidget);
      expect(selectedPreset(tester, '4'), isTrue);
      expect(selectedPreset(tester, '1'), isFalse);
    });

    testWidgets('the display divisor shows and accepts practical units', (
      tester,
    ) async {
      controller.text = '1500';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: 1000,
            displayUnit: 'm',
            decimalPlaces: 2,
          ),
        ),
      );

      // Displayed in metres, canonical in millimetres.
      expect(find.text('1.50'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '2.25');
      await tester.pump();
      expect(controller.text, '2250');

      // A negative value is a value, not an error.
      await tester.enterText(find.byType(TextField), '-1.5');
      await tester.pump();
      expect(controller.text, '-1500');

      // Empty and unparsable text clear the canonical value instead of leaving a
      // stale number the calculator would keep using.
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(controller.text, '');

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(controller.text, '');
      expect(tester.takeException(), isNull);
    });

    testWidgets('an external change resyncs the display without a loop', (
      tester,
    ) async {
      controller.text = '1500';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: 1000,
            displayUnit: 'm',
            decimalPlaces: 2,
          ),
        ),
      );
      expect(find.text('1.50'), findsOneWidget);

      // Applied equipment, or the screen's own Reset, rewrites the canonical
      // controller; the field must follow it.
      controller.text = '3000';
      await tester.pump();
      expect(find.text('3.00'), findsOneWidget);

      controller.text = '0';
      await tester.pump();
      expect(find.text('0.00'), findsOneWidget);
      expect(controller.text, '0');
      expect(tester.takeException(), isNull);
    });
  });

  group('the display never writes back over canonical', () {
    testWidgets('a precise canonical value survives init and every sync', (
      tester,
    ) async {
      controller.text = '1234.56789';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: 1000,
            displayUnit: 'm',
            decimalPlaces: 2,
          ),
        ),
      );

      // The display is the rounded, human-scaled view...
      expect(find.text('1.23'), findsOneWidget);
      // ...and it must not have been parsed back over the precise value.
      expect(controller.text, '1234.56789');

      // A screen rewriting the controller (applied equipment, Reset) still
      // syncs the display without touching the value it just wrote.
      controller.text = '3000';
      await tester.pump();
      expect(find.text('3.00'), findsOneWidget);
      expect(controller.text, '3000');

      controller.text = '0';
      await tester.pump();
      expect(find.text('0.00'), findsOneWidget);
      expect(controller.text, '0');

      controller.text = '987.654321';
      await tester.pump();
      expect(find.text('0.99'), findsOneWidget);
      expect(controller.text, '987.654321');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a cursor or composing change in the display leaves canonical '
        'alone', (tester) async {
      controller.text = '1234.56789';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: 1000,
            displayUnit: 'm',
            decimalPlaces: 2,
          ),
        ),
      );
      final display = visible(tester);
      expect(display.text, '1.23');

      // Moving the cursor re-notifies the controller with the same text; it is
      // not an edit of the number.
      display.selection = const TextSelection.collapsed(offset: 1);
      await tester.pump();
      expect(controller.text, '1234.56789');

      // An IME composition update is not a committed number either.
      display.value = display.value.copyWith(
        composing: const TextRange(start: 0, end: 2),
      );
      await tester.pump();
      expect(controller.text, '1234.56789');

      // Tapping the field just places the cursor.
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(controller.text, '1234.56789');
      expect(tester.takeException(), isNull);
    });

    testWidgets('typing in the display writes canonical, and is not '
        'reformatted under the cursor', (tester) async {
      controller.text = '1500';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: 1000,
            displayUnit: 'm',
            decimalPlaces: 2,
          ),
        ),
      );
      expect(find.text('1.50'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '2.256');
      await tester.pump();

      // Canonical in millimetres: exactly what was typed times the divisor.
      expect(controller.text, '2256');
      // The fixed decimals are a display convenience; a real edit is not
      // rounded or rewritten while the user is in the field.
      expect(find.text('2.256'), findsOneWidget);
      expect(find.text('2.26'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'removing the adapter hands the field back to canonical entry',
      (tester) async {
        Widget field({double displayDivisor = 1, int? decimalPlaces}) =>
            CalculatorNumberField(
              label: 'Focus distance',
              controller: controller,
              displayDivisor: displayDivisor,
              decimalPlaces: decimalPlaces,
            );

        controller.text = '1500';
        await tester.pumpWidget(
          host(field(displayDivisor: 1000, decimalPlaces: 2)),
        );
        expect(visible(tester).text, '1.50');

        // The screen drops the adapter (a preference change, a different unit):
        // the visible field has to be the canonical controller again, or typing
        // would land in a controller nobody reads.
        await tester.pumpWidget(host(field()));
        expect(visible(tester), same(controller));
        expect(visible(tester).text, '1500');

        await tester.enterText(find.byType(TextField), '85');
        await tester.pump();
        expect(controller.text, '85');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('adding or retuning the adapter re-seeds the display from '
        'canonical', (tester) async {
      Widget field({double displayDivisor = 1, int? decimalPlaces}) =>
          CalculatorNumberField(
            label: 'Focus distance',
            controller: controller,
            displayDivisor: displayDivisor,
            decimalPlaces: decimalPlaces,
          );

      controller.text = '1500';
      await tester.pumpWidget(host(field()));
      expect(find.text('1500'), findsOneWidget);

      await tester.pumpWidget(
        host(field(displayDivisor: 1000, decimalPlaces: 2)),
      );
      expect(find.text('1.50'), findsOneWidget);
      expect(controller.text, '1500');

      // The same canonical value, a different practical unit.
      await tester.pumpWidget(
        host(field(displayDivisor: 100, decimalPlaces: 1)),
      );
      expect(find.text('15.0'), findsOneWidget);
      expect(controller.text, '1500');
      expect(tester.takeException(), isNull);
    });
  });

  group('keyboard-free controls rebuild from the one controller', () {
    testWidgets('repeated steps advance without the screen rebuilding', (
      tester,
    ) async {
      controller.text = '1000';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Distance',
            controller: controller,
            step: 100,
            min: 1000,
            max: 2000,
          ),
        ),
      );

      // Nothing here rebuilds the field, so each tap has to leave the next one
      // pointing at the value it just produced.
      for (final expected in <String>['1100', '1200', '1300']) {
        await tester.tap(find.byTooltip('Increase Distance'));
        await tester.pump();
        expect(controller.text, expected);
      }

      for (final expected in <String>['1200', '1100', '1000']) {
        await tester.tap(find.byTooltip('Decrease Distance'));
        await tester.pump();
        expect(controller.text, expected);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a stepper disables itself the moment it reaches its bound', (
      tester,
    ) async {
      controller.text = '900';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Distance',
            controller: controller,
            step: 100,
            min: 500,
            max: 1000,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Increase Distance'));
      await tester.pump();
      expect(controller.text, '1000');

      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
        reason: 'the bound is a bound and the button says so',
      );
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
      'an external raw edit moves the slider and the selected preset',
      (tester) async {
        controller.text = '1';
        await tester.pumpWidget(
          host(
            CalculatorNumberField(
              label: 'Interval (s)',
              controller: controller,
              presets: const <double>[1, 2, 4, 8],
              min: 1,
              max: 8,
              step: 1,
            ),
          ),
        );

        expect(selectedPreset(tester, '1'), isTrue);
        expect(tester.widget<Slider>(find.byType(Slider)).value, 1);

        // Applied equipment, or another screen, writes the controller directly.
        controller.text = '4';
        await tester.pump();

        expect(selectedPreset(tester, '4'), isTrue);
        expect(selectedPreset(tester, '1'), isFalse);
        expect(tester.widget<Slider>(find.byType(Slider)).value, 4);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('compact layout', () {
    testWidgets('nine presets are one horizontal rail, never a stack of rows', (
      tester,
    ) async {
      useViewport(tester, const Size(360, 800));
      controller.text = '30';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Interval (seconds)',
            controller: controller,
            presets: const <double>[1, 2, 5, 10, 15, 30, 60, 120, 300],
            displayUnit: 's',
          ),
        ),
      );

      final rail = railFinder();
      expect(rail, findsOneWidget);
      expect(
        tester.widget<SingleChildScrollView>(rail).scrollDirection,
        Axis.horizontal,
      );
      expect(find.byType(ChoiceChip), findsNWidgets(9));

      // One row: nine chips could never fit side by side, and wrapping them is
      // exactly the clutter this rail replaces.
      expect(tester.getSize(rail).height, lessThan(64));

      // The far end of the rail is still reachable by scrolling.
      await tester.drag(rail, const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ChoiceChip, '300 s').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail fades its trailing edge only while more chips are '
        'reachable', (tester) async {
      useViewport(tester, const Size(360, 800));

      // Two presets fit: no overflow, so no hint is invented.
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Interval (seconds)',
            controller: controller,
            presets: const <double>[1, 2],
            displayUnit: 's',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(railFade(), findsNothing);

      // Nine do not: the edge fades while there is more to scroll to.
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Interval (seconds)',
            controller: controller,
            presets: const <double>[1, 2, 5, 10, 15, 30, 60, 120, 300],
            displayUnit: 's',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(railFade(), findsOneWidget);

      // Reaching the end removes the hint.
      await tester.drag(railFinder(), const Offset(-600, 0));
      await tester.pumpAndSettle();
      expect(railFade(), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the exact field keeps its 48dp steppers beside it, and they '
        'drop to their own line at large text', (tester) async {
      useViewport(tester, const Size(320, 800));
      controller.text = '1000';
      Widget field() => CalculatorNumberField(
        label: 'Distance (mm)',
        controller: controller,
        step: 100,
        min: 0,
        max: 100000,
      );

      await tester.pumpWidget(host(field()));

      final fieldRect = tester.getRect(find.byType(TextField));
      final increaseRect = tester.getRect(
        find.byTooltip('Increase Distance (mm)'),
      );
      expect(increaseRect.left, greaterThanOrEqualTo(fieldRect.right - 1));
      expect(increaseRect.width, greaterThanOrEqualTo(48));
      expect(increaseRect.height, greaterThanOrEqualTo(48));

      // At 200 percent text the same row cannot hold both without squeezing the
      // field, so the steppers take their own line rather than shrinking.
      await tester.pumpWidget(host(field(), textScale: 2));
      await tester.pump();

      final scaledField = tester.getRect(find.byType(TextField));
      final scaledIncrease = tester.getRect(
        find.byTooltip('Increase Distance (mm)'),
      );
      expect(scaledIncrease.top, greaterThanOrEqualTo(scaledField.bottom - 1));
      expect(scaledIncrease.width, greaterThanOrEqualTo(48));
      expect(scaledField.width, greaterThanOrEqualTo(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long label, nine presets and a slider stay unclipped at 200 '
        'percent text', (tester) async {
      useViewport(tester, const Size(320, 640));
      final semantics = tester.ensureSemantics();
      controller.text = '30';

      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Interval between exposures (seconds)',
            controller: controller,
            presets: const <double>[1, 2, 5, 10, 15, 30, 60, 120, 300],
            displayUnit: 's',
            min: 1,
            max: 300,
            step: 1,
            helperText: 'Shorter intervals fill the card faster',
          ),
          textScale: 2,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ChoiceChip), findsNWidgets(9));
      expect(
        find.text('Shorter intervals fill the card faster'),
        findsOneWidget,
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(
        find.bySemanticsLabel('Interval between exposures (seconds) slider'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  });

  group('stepping and bounds', () {
    testWidgets('steppers move by one canonical step and stop at the bounds', (
      tester,
    ) async {
      controller.text = '1000';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Distance',
            controller: controller,
            step: 100,
            min: 1000,
            max: 1200,
          ),
        ),
      );

      await tester.tap(find.byTooltip('Increase Distance'));
      await tester.pump();
      expect(controller.text, '1100');

      await tester.tap(find.byTooltip('Increase Distance'));
      await tester.pump();
      expect(controller.text, '1200');

      // The bound is a bound: the button refuses rather than clamping.
      final increase = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(increase.onPressed, isNull);

      await tester.tap(find.byTooltip('Decrease Distance'));
      await tester.pump();
      expect(controller.text, '1100');
    });

    testWidgets('an out-of-range value can still be stepped back toward the '
        'bounds', (tester) async {
      controller.text = '250';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Frames',
            controller: controller,
            step: 1,
            min: 0,
            max: 10,
          ),
        ),
      );

      // Exact entry was allowed to leave the range, so the steppers must not
      // strand the value there: the step back is offered, the step further out
      // is not.
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull,
      );
      await tester.tap(find.byTooltip('Decrease Frames'));
      await tester.pump();
      expect(controller.text, '249');
    });

    testWidgets('single presets alone offer no stepper', (tester) async {
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Count',
            controller: controller,
            presets: const <double>[10],
          ),
        ),
      );

      expect(find.byType(ChoiceChip), findsOneWidget);
      expect(find.byTooltip('Increase Count'), findsNothing);
    });

    testWidgets('exact out-of-range input is preserved, never clamped', (
      tester,
    ) async {
      controller.text = '50';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Frames',
            controller: controller,
            min: 0,
            max: 10,
            step: 1,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '250');
      await tester.pump();

      // The slider's position is bounded; the value the calculator reads is not.
      expect(controller.text, '250');
      expect(tester.takeException(), isNull);

      await tester.enterText(find.byType(TextField), '-40');
      await tester.pump();
      expect(controller.text, '-40');
      expect(tester.takeException(), isNull);
    });
  });

  group('the slider', () {
    testWidgets('a bounded field offers an accessible slider that writes raw '
        'values', (tester) async {
      final semantics = tester.ensureSemantics();
      controller.text = '50';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Aperture',
            controller: controller,
            min: 1.4,
            max: 22,
            step: 0.1,
            decimalPlaces: 1,
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.bySemanticsLabel('Aperture slider'), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(40, 0));
      await tester.pump();
      final moved = double.parse(controller.text);
      expect(moved, greaterThan(1.4));
      expect(moved, lessThanOrEqualTo(22));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('logarithmic bounds become a log slider, non-positive ones do '
        'not', (tester) async {
      controller.text = '100';
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Exposure',
            controller: controller,
            min: 1,
            max: 10000,
            logarithmic: true,
          ),
        ),
      );

      var slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, closeTo(math.log(1), 1e-9));
      expect(slider.max, closeTo(math.log(10000), 1e-9));

      // A range that reaches zero or below is presented linearly: a log slider
      // there would be a lie about the scale.
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Exposure',
            controller: controller,
            min: -10,
            max: 10,
            logarithmic: true,
          ),
        ),
      );
      slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, -10);
      expect(slider.max, 10);
    });

    testWidgets('the helper line and unit label render without an error', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          CalculatorNumberField(
            label: 'Elevation',
            controller: controller,
            displayUnit: 'm',
            helperText: 'Metres above sea level',
          ),
        ),
      );

      expect(find.text('Metres above sea level'), findsOneWidget);
      expect(find.text('m'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
