import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/navigation.dart';
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
    EdgeInsets deviceInsets = EdgeInsets.zero,
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
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          padding: deviceInsets,
          viewPadding: deviceInsets,
        ),
        child: const PhotographyAssistantApp(),
      ),
    );
  }

  /// The shell shows a navigation rail when the window is wide enough for one
  /// and the bottom bar on a phone, so a destination is addressed through
  /// whichever navigator is actually on screen. Addressing it by descendant
  /// keeps the app-bar title - which carries the same word - out of the match.
  Finder primaryDestination(String label) {
    final bar = find.byType(NavigationBar);
    final navigator = bar.evaluate().isNotEmpty
        ? bar
        : find.byType(NavigationRail);
    return find.descendant(of: navigator, matching: find.text(label));
  }

  Future<void> openDestination(
    WidgetTester tester,
    AppDestination destination,
  ) async {
    await tester.tap(primaryDestination(destination.label));
    await tester.pumpAndSettle();
  }

  /// Settings is an app-bar action now, not a primary destination.
  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byTooltip(AppBarActions.settingsLabel));
    await tester.pumpAndSettle();
  }

  void phoneViewport(WidgetTester tester, {Size size = const Size(400, 800)}) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('starts offline on the plan hub with four primary destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Plan leads: the field launchpad, not a catalog.
    expect(find.text('Plan a shot'), findsOneWidget);
    expect(find.text('Choose a calculator'), findsNothing);
    // The planning tools that carry a decision lead the hub as full rows.
    expect(find.text('When & where'), findsOneWidget);
    expect(find.text('Saved locations'), findsOneWidget);

    for (final destination in AppDestination.values) {
      expect(
        primaryDestination(destination.label),
        findsOneWidget,
        reason: '${destination.label} is missing from primary navigation',
      );
    }
    // Settings is deliberately not a destination: it is an app-bar action.
    expect(find.text('Settings'), findsNothing);
    expect(find.byTooltip(AppBarActions.settingsLabel), findsOneWidget);

    expect(find.textContaining('connect'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
  });

  testWidgets('navigation changes destinations and exposes semantic labels', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openDestination(tester, AppDestination.kit);

    expect(find.text('No equipment yet'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Kit, primary navigation',
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

    // The searchable catalog is the Tools destination; Plan is the launchpad.
    await openDestination(tester, AppDestination.tools);
    expect(find.text('Choose a calculator'), findsOneWidget);

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

    // Every tool is also directly reachable from the Plan hub, without going
    // through the searchable catalog.
    await openDestination(tester, AppDestination.plan);
    final hubShortcut = find.widgetWithText(ActionChip, 'Depth of field');
    await tester.scrollUntilVisible(
      hubShortcut,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(hubShortcut);
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

    await openDestination(tester, AppDestination.tools);

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
    await openDestination(tester, AppDestination.tools);

    const favoriteTooltip = 'Add Saved locations to favorites';
    await tester.tap(find.byTooltip(favoriteTooltip));
    await tester.pumpAndSettle();

    expect(find.textContaining('favorite could not be saved'), findsOneWidget);
    expect(find.byTooltip(favoriteTooltip), findsOneWidget);
    expect(find.text('Saved locations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings opens as an app-bar action and returns to the hub', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await openSettings(tester);

    expect(find.text('Distance units'), findsOneWidget);
    expect(find.text('Shutter display'), findsOneWidget);
    expect(find.textContaining('Canonical calculation values'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theme'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Theme'), findsOneWidget);

    // Back navigation, not a destination switch: the hub is where the
    // photographer was, and its state is still there.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Plan a shot'), findsOneWidget);
  });

  testWidgets('switching destinations preserves each screen local state', (
    WidgetTester tester,
  ) async {
    phoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Later destinations are built lazily: the catalog does not exist until it
    // is opened.
    expect(find.byType(SearchBar), findsNothing);

    await openDestination(tester, AppDestination.tools);
    await tester.enterText(find.byType(SearchBar), 'bokeh');
    await tester.pumpAndSettle();
    expect(find.text('Depth of field'), findsOneWidget);
    expect(find.text('Night-sky planner'), findsNothing);

    // A round trip through every other destination must not reset the query,
    // the filtered list, or where the photographer had scrolled to.
    await openDestination(tester, AppDestination.plan);
    expect(find.text('Plan a shot'), findsOneWidget);
    await openDestination(tester, AppDestination.kit);
    expect(find.text('No equipment yet'), findsOneWidget);
    await openDestination(tester, AppDestination.saved);
    expect(find.text('No saved calculations yet'), findsOneWidget);
    await openDestination(tester, AppDestination.tools);

    expect(find.text('Depth of field'), findsOneWidget);
    expect(find.text('Night-sky planner'), findsNothing);
    expect(tester.takeException(), isNull);

    // Kit and Saved watch the database as streams. Unmounting inside the test
    // lets Riverpod cancel them and the store's deferred close run, instead of
    // leaving a zero-duration timer pending once the tree is torn down.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
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
    expect(find.text('Plan a shot'), findsOneWidget);

    // The launchpad is the first destination and must itself survive 2x text.
    for (var step = 0; step < 8; step++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);

    await openDestination(tester, AppDestination.tools);
    expect(find.text('Choose a calculator'), findsOneWidget);

    // A lazily built catalog only lays out what is on screen, so the group
    // headers further down - the longest labels in the app - stay unexercised
    // until the list is walked to its end.
    final lastGroup = find.text('Macro');
    await tester.scrollUntilVisible(
      lastGroup,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(lastGroup, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// A status bar plus a gesture bar, i.e. a normal modern Android phone. The
  /// shell reserves those insets and the navigation bar, so no destination may
  /// put content underneath either - the failure this guards against is the
  /// silent one, where a row is simply unreachable at the bottom of the screen.
  for (final scale in <double>[1, 2]) {
    testWidgets(
      'every destination stays inside the device insets at ${scale}x text',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          buildApp(
            textScale: scale,
            deviceInsets: const EdgeInsets.only(top: 24, bottom: 34),
          ),
        );
        await tester.pumpAndSettle();

        final navigationBar = find.byType(NavigationBar);
        expect(navigationBar, findsOneWidget);
        final barTop = tester.getRect(navigationBar).top;

        Future<void> assertScrollAreaClear(String name) async {
          expect(
            tester.takeException(),
            isNull,
            reason: '$name threw at ${scale}x text with device insets',
          );

          final vertical = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          if (vertical.evaluate().isEmpty) return;
          final viewportBottom = tester.getRect(vertical.first).bottom;
          expect(
            viewportBottom,
            lessThanOrEqualTo(barTop + 0.5),
            reason:
                '$name\'s scroll area ends at '
                '${viewportBottom.toStringAsFixed(1)}, behind the navigation '
                'bar at $barTop',
          );

          for (var step = 0; step < 8; step++) {
            await tester.drag(vertical.first, const Offset(0, -200));
            await tester.pumpAndSettle();
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$name overflowed while scrolled at ${scale}x',
          );
        }

        for (final destination in AppDestination.values) {
          await openDestination(tester, destination);
          await assertScrollAreaClear(destination.label);
        }

        // Settings is a pushed route with its own app bar, so it has no bottom
        // navigation to clear - but its content still has to end above the
        // gesture bar, and returning must land back on the hub.
        await openSettings(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Settings threw at ${scale}x text with device insets',
        );
        final settingsList = find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        );
        if (settingsList.evaluate().isNotEmpty) {
          final settingsBottom = tester.getRect(settingsList.first).bottom;
          expect(
            settingsBottom,
            lessThanOrEqualTo(800 - 34 + 0.5),
            reason:
                'Settings\'s scroll area ends at '
                '${settingsBottom.toStringAsFixed(1)}, inside the gesture bar',
          );
        }
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

  /// The rail is the other half of the breakpoint contract: a wide window gets
  /// a rail, no bottom bar, and the same destinations.
  testWidgets('a wide window uses a navigation rail instead of a bottom bar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    for (final destination in AppDestination.values) {
      expect(primaryDestination(destination.label), findsOneWidget);
    }

    await openDestination(tester, AppDestination.tools);
    expect(find.text('Choose a calculator'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
  Future<AppPreferences> update(
    AppPreferences Function(AppPreferences current) transform,
  ) async => throw StateError('write failed');
}
