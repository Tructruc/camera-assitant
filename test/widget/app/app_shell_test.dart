import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.inMemory();
  });

  tearDown(() => database.close());

  Widget buildApp({double textScale = 1}) {
    return ProviderScope(
      overrides: <Override>[
        preferencesProvider.overrideWith(
          (ref) => Stream<AppPreferences>.value(const AppPreferences()),
        ),
        equipmentRepositoryProvider.overrideWithValue(
          DriftEquipmentRepository(database),
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

    expect(find.text('No equipment yet'), findsOneWidget);
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

  testWidgets('calculator catalog opens each offline calculator screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Depth of field'), findsOneWidget);
    expect(find.text('Exposure comparison'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Long exposure / ND'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Long exposure / ND'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Depth of field'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Depth of field'));
    await tester.pumpAndSettle();
    expect(find.text('Focal length (mm)'), findsOneWidget);
    expect(find.textContaining('connect'), findsNothing);
  });

  testWidgets('settings exposes units, shutter, theme, and privacy guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Distance units'), findsOneWidget);
    expect(find.text('Shutter display'), findsOneWidget);
    expect(find.textContaining('Canonical calculation values'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theme'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Theme'), findsOneWidget);
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
