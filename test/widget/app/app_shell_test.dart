import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';

void main() {
  Widget buildApp({double textScale = 1}) {
    return ProviderScope(
      overrides: <Override>[
        preferencesProvider.overrideWith(
          (ref) => Stream<AppPreferences>.value(const AppPreferences()),
        ),
      ],
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: const PhotographyAssistantApp(),
      ),
    );
  }

  testWidgets('starts offline with all primary navigation destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Calculators'), findsWidgets);
    expect(find.text('Equipment'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Choose a calculator'), findsOneWidget);
    expect(find.textContaining('connect'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('navigation changes destinations and exposes semantic labels', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Equipment'));
    await tester.pumpAndSettle();

    expect(find.text('Your equipment'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Equipment, primary navigation',
      ),
      findsAtLeastNWidgets(1),
    );
    semantics.dispose();
  });

  testWidgets('shell remains usable at 200 percent text scale', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(textScale: 2));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Choose a calculator'), findsOneWidget);
  });

  testWidgets('error view explains recovery without exposing internals', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppErrorView()));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.textContaining('restart'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Application error',
      ),
      findsOneWidget,
    );
  });
}
