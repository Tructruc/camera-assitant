import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';

void main() {
  testWidgets('an incomplete live edit retains the field and keyboard focus', (
    tester,
  ) async {
    final controller = TextEditingController(text: '50');
    addTearDown(controller.dispose);
    var valid = true;
    const inputKey = Key('live-focus-input');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => CalculatorPage(
              inputControllers: [controller],
              onInputsChanged: () => setState(() {
                valid = double.tryParse(controller.text) != null;
              }),
              onCalculate: () {},
              children: [
                CalculatorNumberField(
                  label: 'Focal length',
                  controller: controller,
                  fieldKey: inputKey,
                ),
                if (valid)
                  CalculationResultView(
                    title: 'Live result',
                    highlight: ('Value', controller.text),
                    onSave: () {},
                    onReset: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(inputKey));
    await tester.pump();
    final focus = tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode;
    expect(focus.hasFocus, isTrue);
    expect(find.byType(CalculatorLiveAnswerBar), findsOneWidget);

    await tester.enterText(find.byKey(inputKey), '');
    await tester.pump();
    expect(find.byType(CalculatorLiveAnswerBar), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode,
      same(focus),
    );
    expect(focus.hasFocus, isTrue);

    await tester.enterText(find.byKey(inputKey), '85');
    await tester.pump();
    expect(find.byType(CalculatorLiveAnswerBar), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode,
      same(focus),
    );
    expect(focus.hasFocus, isTrue);
    expect(controller.text, '85');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
