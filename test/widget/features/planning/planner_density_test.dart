import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';

/// One planner under test: its screen, its explicit action, the canonical keys
/// its saved payload uses, and the elevation its collapsed Site details row
/// states while no site is selected.
typedef _Planner = ({
  String name,
  Widget screen,
  Key action,
  String latitudeKey,
  String longitudeKey,
  String collapsedElevation,
});

/// The density contract of the two field planners.
///
/// An unpopulated saved-site picker costs no row, the explicit search is one tap
/// away at every scroll offset without covering the form, and the elevation
/// disclosure keeps exact entry, exposes a validation error, and leaves the
/// saved canonical values exactly as entered.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  const planners = <_Planner>[
    (
      name: 'Sun & Moon alignment',
      screen: AlignmentScreen(),
      action: Key('alignment-search'),
      latitudeKey: 'observerLatitudeDegrees',
      longitudeKey: 'observerLongitudeDegrees',
      collapsedElevation: 'Elevation 20 m · terrain is not modeled',
    ),
    (
      name: 'night-sky planner',
      screen: AstronomyScreen(),
      action: Key('astronomy-search'),
      latitudeKey: 'latitudeDegrees',
      longitudeKey: 'longitudeDegrees',
      collapsedElevation: 'Elevation 0 m · terrain is not modeled',
    ),
  ];

  const latitudeLabel = 'Observer latitude (degrees)';
  const longitudeLabel = 'Observer longitude, east positive (degrees)';
  const elevationLabel = 'Observer elevation (m)';
  const invalidValueMessage =
      'Enter a finite value within the supported range.';

  final ridgeSite = SavedLocation(
    id: 'ridge-site',
    name: 'Ridge site',
    latitudeDegrees: 45.8326,
    longitudeDegrees: 6.8652,
    elevationMetres: 3842,
    timeZoneId: 'Europe/Paris',
    source: LocationSource.device,
    accuracyMetres: 8,
    createdAt: DateTime.utc(2026, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 10),
  );

  Widget app(
    Widget screen, {
    List<SavedLocation> locations = const <SavedLocation>[],
  }) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      savedLocationsProvider.overrideWith(
        (ref) => Stream<List<SavedLocation>>.value(locations),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

  /// The planner's own ListView: the first vertical scrollable in tree order.
  Finder screenScrollable() => find
      .byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      )
      .first;

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 300,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: screenScrollable(),
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Opens the collapsed Site details row that holds the observer elevation.
  Future<void> openSiteDetails(WidgetTester tester) async {
    final title = find.text('Site details');
    await reveal(tester, title);
    await tester.tap(title);
    await tester.pumpAndSettle();
  }

  for (final planner in planners) {
    testWidgets('${planner.name} omits an empty saved-site picker', (
      tester,
    ) async {
      await tester.pumpWidget(app(planner.screen));
      await tester.pumpAndSettle();

      // Nothing is saved, so the picker spends no row saying so...
      expect(find.text('Saved location (optional)'), findsNothing);
      // ...and the screen reports manual coordinates rather than silently
      // adopting a site or asking for a location fix.
      expect(find.textContaining('Manual coordinates ·'), findsOneWidget);
      // The exact-entry coordinates it does have stay on the screen itself.
      expect(find.widgetWithText(TextField, latitudeLabel), findsOneWidget);
      expect(find.widgetWithText(TextField, longitudeLabel), findsOneWidget);
      // Their bounds are no longer a standing paragraph over each field.
      expect(find.textContaining('Between -90'), findsNothing);
      expect(find.textContaining('Between -180'), findsNothing);
      await unmount(tester);
    });

    testWidgets('${planner.name} keeps the full picker once a site is saved', (
      tester,
    ) async {
      await tester.pumpWidget(app(planner.screen, locations: [ridgeSite]));
      await tester.pumpAndSettle();

      final picker = find.text('Saved location (optional)');
      await reveal(tester, picker);
      expect(picker, findsOneWidget);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ridge site').last);
      await tester.pumpAndSettle();

      // The saved site supplies both coordinates and its own elevation, and the
      // collapsed row states that elevation rather than hiding it. Opening the
      // menu scrolls the form, so the site row above the picker is scrolled back
      // into the built range before it is read.
      await tester.drag(find.byType(ListView).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Ridge site · 45.8326°, 6.8652°'),
        findsOneWidget,
      );
      expect(
        find.text('Elevation 3842.0 m · terrain is not modeled'),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('${planner.name} keeps the explicit search outside the form', (
      tester,
    ) async {
      await tester.pumpWidget(app(planner.screen));
      await tester.pumpAndSettle();

      final action = find.byKey(planner.action);
      expect(action, findsOneWidget);
      // Tappable before the form has been scrolled at all...
      expect(
        action.hitTestable(),
        findsOneWidget,
        reason: '${planner.name} does not offer its action at the top',
      );
      // ...because it is not an item of the scrolling form, so no scroll offset
      // can carry it away and it covers none of the fields.
      expect(
        find.ancestor(of: action, matching: find.byType(ListView)),
        findsNothing,
      );

      await tester.drag(find.byType(ListView).first, const Offset(0, -10000));
      await tester.pumpAndSettle();
      expect(
        action.hitTestable(),
        findsOneWidget,
        reason: '${planner.name} lost its action at the end of the form',
      );
      await unmount(tester);
    });

    testWidgets('${planner.name} saves the disclosed elevation it was given', (
      tester,
    ) async {
      await tester.pumpWidget(app(planner.screen));
      await tester.pumpAndSettle();

      // The elevation field is the disclosure's business; the row it lives in
      // still states the value the screen is using.
      expect(find.widgetWithText(TextField, elevationLabel), findsNothing);
      expect(find.text(planner.collapsedElevation), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, latitudeLabel),
        '47.3769',
      );
      await tester.enterText(
        find.widgetWithText(TextField, longitudeLabel),
        '8.5417',
      );
      await tester.pumpAndSettle();

      await openSiteDetails(tester);
      final elevation = find.widgetWithText(TextField, elevationLabel);
      expect(elevation, findsOneWidget);
      await reveal(tester, elevation);
      await tester.enterText(elevation, '1234');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(planner.action));
      await tester.pumpAndSettle();

      final save = find.widgetWithText(FilledButton, 'Save result');
      await reveal(tester, save);
      await tester.tap(save);
      await tester.pumpAndSettle();

      // Exact coordinates and the disclosed elevation reach the canonical
      // payload unchanged.
      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(snapshot.canonicalInputs[planner.latitudeKey], 47.3769);
      expect(snapshot.canonicalInputs[planner.longitudeKey], 8.5417);
      expect(snapshot.canonicalInputs['observerElevationMetres'], 1234.0);
      await unmount(tester);
    });
  }

  testWidgets('an invalid elevation cannot hide behind the site disclosure', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();

    await openSiteDetails(tester);
    final elevation = find.widgetWithText(TextField, elevationLabel);
    await reveal(tester, elevation);
    await tester.enterText(elevation, 'not a number');
    await tester.pumpAndSettle();

    // Collapsed again, as it is left once the value has been set. Writing the
    // field scrolled the form, so the row is scrolled back to before it is
    // tapped - a tap that misses would leave the group open and prove nothing.
    final disclosure = find.text('Site details');
    await reveal(tester, disclosure);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, elevationLabel), findsNothing);

    await tester.tap(find.byKey(const Key('astronomy-search')));
    await tester.pumpAndSettle();

    // The failed plan opens the group that holds the offending field and states
    // the error in the row itself, so a disclosure is never a place an invalid
    // value can hide.
    expect(find.widgetWithText(TextField, elevationLabel), findsOneWidget);
    expect(find.text(invalidValueMessage), findsWidgets);
    await unmount(tester);
  });
}
