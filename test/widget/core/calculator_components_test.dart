import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';

void main() {
  Widget host({
    required (String, String) highlight,
    List<(String, String)> tiles = const [],
    List<(String, String)> details = const [],
    List<(String, String)> inputs = const [],
    List<String> assumptions = const [],
    List<String> warnings = const [],
    String? caption,
    String? guidance,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: CalculationResultView(
          title: 'Depth of field result',
          highlight: highlight,
          highlightCaption: caption,
          tiles: tiles,
          details: details,
          inputs: inputs,
          assumptions: assumptions,
          warnings: warnings,
          guidance: guidance,
          onReset: () {},
          onSave: () {},
        ),
      ),
    ),
  );

  testWidgets('the hero answer is the only value shown before expanding', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        highlight: ('Hyperfocal distance', '10.5 m'),
        caption: 'Sharp from 5.25 m to infinity.',
        tiles: const [('Near limit', '5.25 m'), ('Far limit', 'Infinity')],
        details: const [('Depth in front of focus', '5.25 m')],
        inputs: const [('Focal length', '50 mm')],
        assumptions: const ['Thin-lens model'],
      ),
    );

    // Decision first: the hero and its plain-language caption.
    expect(find.text('Hyperfocal distance'), findsOneWidget);
    expect(find.text('10.5 m'), findsOneWidget);
    expect(find.text('Sharp from 5.25 m to infinity.'), findsOneWidget);

    // Secondary answers are visible as tiles.
    expect(find.text('Near limit'), findsOneWidget);
    expect(find.text('5.25 m'), findsOneWidget);
    expect(find.text('Far limit'), findsOneWidget);

    // The number wall is behind one expander: nothing below is built yet.
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Values used'), findsNothing);
    expect(find.text('Focal length'), findsNothing);
    expect(find.text('Depth in front of focus'), findsNothing);
    expect(find.text('Thin-lens model'), findsNothing);

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(find.text('Values used'), findsOneWidget);
    expect(find.text('Focal length'), findsOneWidget);
    expect(find.text('50 mm'), findsOneWidget);
    expect(find.text('Exact values'), findsOneWidget);
    expect(find.text('Depth in front of focus'), findsOneWidget);
    expect(find.text('Model assumptions'), findsOneWidget);
    expect(find.textContaining('Thin-lens model'), findsOneWidget);
  });

  testWidgets('the result region announces the hero value and warnings', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        highlight: ('Recommended aperture', 'f/5.6'),
        warnings: const ['Close focus reduces accuracy.'],
      ),
    );

    expect(find.text('f/5.6'), findsOneWidget);
    // Warnings must stay visible without expanding anything.
    expect(find.text('Close focus reduces accuracy.'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Depth of field result calculation result: Recommended '
                    'aperture f/5.6. Warnings: Close focus reduces accuracy.',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label ==
                'Warnings: Close focus reduces accuracy.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('secondary inputs stay reachable behind one expander', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: const <Widget>[
              CalculatorAdvancedSection(
                children: <Widget>[Text('Circle of confusion (mm)')],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('More settings'), findsOneWidget);
    expect(find.text('Circle of confusion (mm)'), findsNothing);

    await tester.tap(find.text('More settings'));
    await tester.pumpAndSettle();
    expect(find.text('Circle of confusion (mm)'), findsOneWidget);
  });
}
