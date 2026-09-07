import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';

void main() {
  testWidgets('result exposes the exact calculation inputs accessibly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalculationResultView(
            title: 'Depth of field result',
            inputs: const [('Focal length', '50 mm'), ('Aperture', 'f/8')],
            rows: const [('Near limit', '4.72 m')],
            assumptions: const ['Thin-lens model'],
            onReset: () {},
            onSave: () {},
          ),
        ),
      ),
    );

    expect(find.text('Input summary'), findsOneWidget);
    expect(find.text('Focal length'), findsOneWidget);
    expect(find.text('50 mm'), findsOneWidget);
    expect(find.text('Aperture'), findsOneWidget);
    expect(find.text('f/8'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Input summary: Focal length 50 mm; Aperture f/8',
      ),
      findsOneWidget,
    );
  });
}
