import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/calculator_catalog.dart';
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

  Widget buildApp({
    double textScale = 1,
    PreferencesRepository? preferencesRepository,
  }) {
    return ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        if (preferencesRepository != null)
          preferencesRepositoryProvider.overrideWithValue(
            preferencesRepository,
          ),
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

  testWidgets('calculator catalog opens every offline calculator screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Driven by the catalog enum, so a destination that is added without a
    // working route or a screen that fails to build cannot slip through.
    for (final destination in CalculatorDestination.values) {
      // Filtering with the catalog's own search keeps each tile on screen, so
      // the loop does not depend on the scroll position of a long list.
      await tester.enterText(find.byType(SearchBar), destination.label);
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(ListTile, destination.label);
      expect(
        tile,
        findsOneWidget,
        reason: '${destination.label} is missing from the catalog',
      );
      await tester.tap(tile);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, destination.label),
        findsOneWidget,
        reason: '${destination.label} did not open its own screen',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: '${destination.label} threw while building',
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byType(SearchBar), 'Depth of field');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Depth of field'));
    await tester.pumpAndSettle();
    expect(find.text('Focal length (mm)'), findsOneWidget);
    expect(find.textContaining('connect'), findsNothing);

    // Opening every destination starts Drift streams; unmount before the
    // framework checks that no timer outlives the widget tree.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('catalog searches and groups tools by photographic purpose', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Location & sky planning'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Focus & optics'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Focus & optics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(SearchBar),
      -250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(SearchBar), 'star trails');
    await tester.pump();

    expect(find.text('Night-sky planner'), findsOneWidget);
    expect(find.text('Depth of field'), findsNothing);
  });

  testWidgets('a failed favorite write is reported without changing the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildApp(preferencesRepository: _FailingPreferencesRepository(database)),
    );
    await tester.pumpAndSettle();

    const favoriteTooltip = 'Add Saved locations to favorites';
    await tester.tap(find.byTooltip(favoriteTooltip));
    await tester.pumpAndSettle();

    expect(find.textContaining('favorite could not be saved'), findsOneWidget);
    expect(find.byTooltip(favoriteTooltip), findsOneWidget);
    expect(find.text('Saved locations'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

final class _FailingPreferencesRepository extends PreferencesRepository {
  _FailingPreferencesRepository(super.database);

  @override
  Future<void> save(AppPreferences preferences) async =>
      throw StateError('write failed');
}
