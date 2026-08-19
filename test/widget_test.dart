import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';

void main() {
  testWidgets('shows the offline toolkit shell', (WidgetTester tester) async {
    await tester.pumpWidget(const PhotographyAssistantApp());

    expect(find.text('Photography Assistant'), findsOneWidget);
    expect(find.text('Your offline field toolkit'), findsOneWidget);
  });
}
