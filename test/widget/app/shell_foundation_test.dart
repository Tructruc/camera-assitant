import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/app.dart';
import 'package:photography_assistant/app/navigation.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';

/// The shell contract of the field workbench: four primary destinations
/// (Plan / Tools / Kit / Saved), Settings as an app-bar action, every tool
/// reachable, and local state preserved across a destination switch.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget buildApp({
    double textScale = 1,
    bool boldText = false,
    EdgeInsets deviceInsets = EdgeInsets.zero,
    bool stubPreferences = true,
  }) {
    return ProviderScope(
      overrides: <Override>[
        appDatabaseProvider.overrideWithValue(database),
        if (stubPreferences)
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
          boldText: boldText,
          padding: deviceInsets,
          viewPadding: deviceInsets,
        ),
        child: const PhotographyAssistantApp(),
      ),
    );
  }

  void pinPhoneViewport(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// The destination's tab in whichever navigator the current width uses.
  Finder destinationTab(AppDestination destination) {
    final bar = find.byType(NavigationBar);
    final host = bar.evaluate().isNotEmpty ? bar : find.byType(NavigationRail);
    return find.descendant(of: host, matching: find.text(destination.label));
  }

  Future<void> tapDestination(
    WidgetTester tester,
    AppDestination destination,
  ) async {
    await tester.tap(destinationTab(destination));
    await tester.pumpAndSettle();
  }

  /// A destination that opens a database stream keeps a zero-duration timer
  /// pending when the last subscription is cancelled, so the tree is unmounted
  /// before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('the shell offers four destinations and Settings as an app-bar '
      'action', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (final destination in AppDestination.values) {
      expect(
        find.text(destination.label),
        findsWidgets,
        reason: '${destination.label} is missing from the primary navigation',
      );
    }
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.byTooltip(AppBarActions.settingsLabel), findsOneWidget);

    // The first destination is the planning hub, not a wall of tools.
    expect(find.text('Plan a shot'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Plan'), findsOneWidget);

    // No invented connectivity state anywhere in the shell.
    expect(find.textContaining('connect'), findsNothing);
    expect(find.textContaining('sign in'), findsNothing);
    expect(find.textContaining('syncing'), findsNothing);

    await unmount(tester);
  });

  testWidgets('Settings opens from every destination', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    for (final destination in AppDestination.values) {
      await tapDestination(tester, destination);
      expect(find.widgetWithText(AppBar, destination.label), findsOneWidget);

      await tester.tap(find.byTooltip(AppBarActions.settingsLabel));
      await tester.pumpAndSettle();
      expect(find.text('Distance units'), findsOneWidget);
      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, destination.label), findsOneWidget);
    }

    await unmount(tester);
  });

  testWidgets('destinations are built lazily and kept alive', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Kit has never been opened, so it is not in the tree at all.
    expect(find.text('No equipment yet'), findsNothing);

    await tapDestination(tester, AppDestination.kit);
    expect(find.text('No equipment yet'), findsOneWidget);

    // Leaving Kit keeps it alive but hidden: its widgets are not reachable from
    // another destination.
    await tapDestination(tester, AppDestination.plan);
    expect(find.text('No equipment yet'), findsNothing);
    await tapDestination(tester, AppDestination.kit);
    expect(find.text('No equipment yet'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('the Tools destination keeps its search query and scroll '
      'position across a switch', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tapDestination(tester, AppDestination.tools);

    await tester.enterText(find.byType(SearchBar), 'bokeh');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Depth of field'), findsOneWidget);

    await tapDestination(tester, AppDestination.saved);
    await tapDestination(tester, AppDestination.tools);
    expect(find.text('bokeh'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Depth of field'), findsOneWidget);

    // With the query cleared the whole catalog is scrollable again, and its
    // scroll position survives a round trip too.
    await tester.enterText(find.byType(SearchBar), '');
    await tester.pumpAndSettle();
    final list = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.drag(list.first, const Offset(0, -220));
    await tester.pumpAndSettle();
    final scrolled = tester.state<ScrollableState>(list.first).position.pixels;
    expect(scrolled, greaterThan(0));

    await tapDestination(tester, AppDestination.plan);
    await tapDestination(tester, AppDestination.tools);
    expect(tester.state<ScrollableState>(list.first).position.pixels, scrolled);

    await unmount(tester);
  });

  testWidgets('every calculator is reachable from the Plan hub and from the '
      'Tools catalog', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Plan: exactly one direct route per tool, in document order.
    final planList = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    for (final destination in CalculatorDestination.values) {
      final shortcut = find.text(destination.label);
      if (shortcut.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          shortcut,
          200,
          scrollable: planList.first,
        );
      }
      expect(
        shortcut,
        findsOneWidget,
        reason: '${destination.label} has no route on the Plan hub',
      );
    }

    // A planning row and a shot-workflow shortcut both open their own screen.
    for (final destination in <CalculatorDestination>[
      CalculatorDestination.alignment,
      CalculatorDestination.depthOfField,
    ]) {
      await tester.ensureVisible(find.text(destination.label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(destination.label));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AppBar, destination.label),
        findsOneWidget,
        reason: '${destination.label} did not open its own screen',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    // Tools: the same tools, searchable and grouped, each opening its screen.
    await tapDestination(tester, AppDestination.tools);
    for (final destination in CalculatorDestination.values) {
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
      expect(find.widgetWithText(AppBar, destination.label), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: '${destination.label} threw while building',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await unmount(tester);
  });

  testWidgets('the catalog answers photographic synonyms', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tapDestination(tester, AppDestination.tools);

    for (final (query, expected) in <(String, String)>[
      ('bokeh', 'Depth of field'),
      ('hyperfocal', 'Depth of field'),
      ('nd', 'Long exposure / ND'),
      ('guide number', 'Flash exposure'),
      ('close-up', 'Macro planner'),
      ('star trails', 'Night-sky planner'),
      ('coordinates', 'Saved locations'),
      ('pano', 'Panorama planner'),
    ]) {
      await tester.enterText(find.byType(SearchBar), query);
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(ListTile, expected),
        findsOneWidget,
        reason: '"$query" should find $expected',
      );
    }

    // A short query is matched on whole words, not as a fragment.
    await tester.enterText(find.byType(SearchBar), 'nd');
    await tester.pumpAndSettle();
    expect(find.text('No matching tools'), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('No matching tools'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('favorites are persisted and shown as shortcuts', (tester) async {
    pinPhoneViewport(tester);
    await tester.pumpWidget(buildApp(stubPreferences: false));
    await tester.pumpAndSettle();
    await tapDestination(tester, AppDestination.tools);

    final favorite = find.byTooltip('Add Depth of field to favorites');
    await tester.ensureVisible(favorite);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.ancestor(of: favorite, matching: find.byType(IconButton)),
          )
          .onPressed,
      isNotNull,
      reason: 'the favorite action is disabled until preferences have loaded',
    );
    await tester.tap(favorite);
    await tester.pumpAndSettle();

    final stored = await PreferencesRepository(database).load();
    expect(stored.favoriteToolIds, contains('depth_of_field'));
    expect(
      find.byTooltip('Remove Depth of field from favorites'),
      findsOneWidget,
    );
    // The shortcuts rail sits above the rows, and bringing the depth-of-field
    // row into view scrolled it off the top of the lazy list: scroll back to
    // the top before looking for it.
    await tester.drag(find.byType(ListView).first, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text('Your favorites'), findsOneWidget);

    // Removing it again is remembered too. The row has to be brought back into
    // the viewport first: the shortcuts rail above it pushed it under the
    // navigation bar.
    final removeFavorite = find.byTooltip(
      'Remove Depth of field from favorites',
    );
    await tester.ensureVisible(removeFavorite);
    await tester.pumpAndSettle();
    await tester.tap(removeFavorite);
    await tester.pumpAndSettle();
    expect(
      (await PreferencesRepository(database).load()).favoriteToolIds,
      isNot(contains('depth_of_field')),
    );

    await unmount(tester);
  });

  testWidgets('a wide window gets a labelled navigation rail', (tester) async {
    pinPhoneViewport(tester, size: const Size(1000, 800));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    for (final destination in AppDestination.values) {
      expect(find.text(destination.label), findsWidgets);
    }

    await tapDestination(tester, AppDestination.kit);
    expect(find.widgetWithText(AppBar, 'Kit'), findsOneWidget);
    expect(find.text('No equipment yet'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('every destination stays usable on a 320px phone at 200 percent '
      'text and bold text', (tester) async {
    pinPhoneViewport(tester, size: const Size(320, 568));
    await tester.pumpWidget(
      buildApp(
        textScale: 2,
        boldText: true,
        deviceInsets: const EdgeInsets.only(top: 24, bottom: 34),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (final destination in AppDestination.values) {
      await tapDestination(tester, destination);
      expect(
        tester.takeException(),
        isNull,
        reason: '${destination.label} overflowed at 200% text',
      );

      // Walk the whole surface: a row that only overflows below the fold is
      // otherwise never laid out.
      final vertical = find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      );
      if (vertical.evaluate().isNotEmpty) {
        for (var step = 0; step < 10; step++) {
          await tester.drag(vertical.first, const Offset(0, -200));
          await tester.pumpAndSettle();
        }
      }
      expect(
        tester.takeException(),
        isNull,
        reason: '${destination.label} overflowed while scrolled',
      );
    }

    await unmount(tester);
  });

  testWidgets('the app-bar settings action opens on a narrow phone too', (
    tester,
  ) async {
    pinPhoneViewport(tester, size: const Size(320, 568));
    await tester.pumpWidget(buildApp(textScale: 2));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.byTooltip(AppBarActions.settingsLabel));
    await tester.pumpAndSettle();

    // The pushed route, not a scrolled-to row, is what has to survive 200% text
    // at this width.
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await unmount(tester);
  });
}
