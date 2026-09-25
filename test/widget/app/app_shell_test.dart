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

        for (final destination in <String>[
          'Calculators',
          'Equipment',
          'Saved',
          'Settings',
        ]) {
          await tester.tap(
            find.descendant(
              of: navigationBar,
              matching: find.text(destination),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: '$destination threw at ${scale}x text with device insets',
          );

          final vertical = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          if (vertical.evaluate().isNotEmpty) {
            final viewportBottom = tester.getRect(vertical.first).bottom;
            expect(
              viewportBottom,
              lessThanOrEqualTo(barTop + 0.5),
              reason:
                  '$destination\'s scroll area ends at ${viewportBottom.toStringAsFixed(1)}, '
                  'behind the navigation bar at $barTop',
            );

            for (var step = 0; step < 8; step++) {
              await tester.drag(vertical.first, const Offset(0, -200));
              await tester.pumpAndSettle();
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$destination overflowed while scrolled at ${scale}x',
            );
          }
        }

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  }

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

  testWidgets('a filtered catalog row is tappable above a real bottom inset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The phone-shaped frame and the gesture bar are the emulator conditions
    // the Android journey runs under; on the desktop host there is no bottom
    // inset, which is what hid the failure until the first emulator run.
    await tester.pumpWidget(
      buildApp(textScale: 2, deviceInsets: const EdgeInsets.only(bottom: 34)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'Depth of field');
    await tester.pumpAndSettle();

    final row = find.widgetWithText(ListTile, 'Depth of field');
    expect(row, findsOneWidget);
    final barTop = tester.getRect(find.byType(NavigationBar)).top;

    // A ListTile is about 200 logical pixels tall at this scale, so the row the
    // search leaves at the end of the list is only partly inside the scrollable
    // and its centre - the point a tap targets - can sit behind the navigation
    // bar. The Android run tapped exactly that point and hit the bar instead:
    // `derived an Offset (Offset(200.0, 641.0)) that would not hit test on the
    // specified widget`. The row has to be revealable inside what is left.
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();

    final centre = tester.getCenter(row);
    expect(
      centre.dy,
      lessThan(barTop),
      reason:
          'the filtered row is still under the navigation bar '
          '(centre ${centre.dy}, bar top $barTop)',
    );
    expect(row.hitTestable(), findsOneWidget);

    await tester.tap(row);
    await tester.pumpAndSettle();
    // The row opened the calculator, not the navigation bar.
    expect(find.text('Calculate'), findsWidgets);
  });
}

final class _FailingPreferencesRepository extends PreferencesRepository {
  _FailingPreferencesRepository(super.database);

  @override
  Future<AppPreferences> update(
    AppPreferences Function(AppPreferences current) transform,
  ) async => throw StateError('write failed');
}
