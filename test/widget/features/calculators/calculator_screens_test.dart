import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, CalculationSnapshot, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_timeline.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

/// Expands a collapsed [ExpansionTile] before its contents are asserted.
///
/// A collapsed tile does not build its children, so targets inside the result
/// `Details` section or the `More settings` advanced section cannot be found
/// until the tile is tapped. The scroll is deliberate: a header below the fold
/// is not built either, and a missing header should fail loudly here rather
/// than silently skip the expansion.
Future<void> openExpander(WidgetTester tester, String title) async {
  final tile = find.text(title);
  await tester.scrollUntilVisible(
    tile,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(tile);
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(
    Widget child, {
    double textScale = 1,
    AppPreferences preferences = const AppPreferences(),
    List<SavedLocation> savedLocations = const [],
  }) => ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      preferencesProvider.overrideWith(
        (ref) => Stream<AppPreferences>.value(preferences),
      ),
      equipmentRepositoryProvider.overrideWithValue(
        DriftEquipmentRepository(database),
      ),
      savedLocationsProvider.overrideWith(
        (ref) => Stream<List<SavedLocation>>.value(savedLocations),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );

  /// Scrolls [finder] into view and settles.
  ///
  /// The cheap calculators seed their answer and keep it live, so there is no
  /// Calculate button to press: a result is *revealed*, never requested.
  ///
  /// A target can sit either side of the current position - a result card is
  /// above the advanced section that was just opened, a field below the result
  /// card - and `scrollUntilVisible` only walks one way, so a target that is not
  /// built yet is reached from the top of the list, downwards.
  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 300,
  }) async {
    if (finder.evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        finder,
        delta.abs(),
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  /// Unmounts the screen, which also cancels the live-calculation timer the
  /// seeded answer scheduled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  /// Taps the result card's save action, revealing it first.
  Future<void> saveResult(WidgetTester tester) async {
    final save = find.widgetWithText(FilledButton, 'Save result');
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  /// Opens the collapsed "Site details" row that holds the observer elevation.
  ///
  /// The planners keep a rarely changed elevation behind that one disclosure so
  /// it costs no viewport, which means its field is only built once the row is
  /// opened.
  Future<void> openSiteDetails(WidgetTester tester) async {
    final title = find.text('Site details');
    await reveal(tester, title);
    await tester.tap(title);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'depth of field labels inputs, validates live, and explains result',
    (tester) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Focal length (mm)'), findsOneWidget);
      // The practical distance input is denominated in metres; the canonical raw
      // millimetre value stays behind the advanced group.
      expect(find.text('Focus distance (m)'), findsOneWidget);
      // The circle of confusion is a convention, not a per-shot decision, so it
      // starts collapsed and stays reachable one tap away.
      expect(find.text('Circle of confusion (mm)'), findsNothing);

      // A live calculator answers without a Calculate button: the validation
      // message appears as soon as the input stops being usable.
      expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);
      await tester.enterText(find.byKey(const Key('dof-focal')), '0');
      await tester.pumpAndSettle();
      expect(find.text('Enter a positive finite value.'), findsWidgets);
      await tester.enterText(find.byKey(const Key('dof-focal')), '50');
      await tester.pumpAndSettle();

      // The convention and the raw millimetre adapter open one tap away. They
      // are reached only after the focal field has been edited: walking back up
      // to it later would dispose the expanded group.
      await openExpander(tester, 'More settings');
      expect(find.text('Circle of confusion (mm)'), findsOneWidget);
      expect(find.text('Focus distance (raw mm)'), findsOneWidget);

      await reveal(tester, find.text('Hyperfocal distance'));
      // The answer leads; the input echo and model assumptions stay collapsed.
      expect(find.text('Hyperfocal distance'), findsOneWidget);
      expect(find.text('Values used'), findsNothing);
      await openExpander(tester, 'Details');
      expect(find.text('Values used'), findsOneWidget);
      expect(find.text('50 mm'), findsOneWidget);
      expect(find.text('f/8'), findsOneWidget);
      // The practical field shows metres; the raw millimetre value is what the
      // calculator read and it stays visible in the input echo.
      expect(find.text('10.00 m'), findsWidgets);
      expect(find.text('Near limit'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pumpAndSettle();
      expect(find.text('Model assumptions'), findsOneWidget);
      expect(find.textContaining('Thin-lens geometric model'), findsOneWidget);
      expect(find.text('Save result'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'the metre distance field keeps the raw millimetre value canonical',
    (tester) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      // Typing metres writes millimetres into the same controller the
      // calculator reads, and the raw adapter echoes it without rounding.
      await tester.enterText(find.byKey(const Key('dof-focal')), '50');
      final metreField = find.widgetWithText(TextField, 'Focus distance (m)');
      await reveal(tester, metreField);
      await tester.enterText(metreField, '2.5');
      await tester.pumpAndSettle();
      await openExpander(tester, 'More settings');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dof-focus-distance-mm')))
            .controller!
            .text,
        '2500',
      );
      await reveal(tester, find.text('Save result'));
      await saveResult(tester);
      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(snapshot.canonicalInputs['focusDistanceMm'], 2500.0);
      expect(snapshot.displayContext['distanceUnit'], 'metric');
      await unmount(tester);
    },
  );

  testWidgets('exposure comparison reports its live component result', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ExposureComparisonScreen()));
    await tester.pumpAndSettle();

    // Two identical exposures read as equivalent without any action.
    expect(
      find.widgetWithText(FilledButton, 'Compare exposures'),
      findsNothing,
    );
    await reveal(tester, find.text('Equivalent exposure'));
    expect(find.text('Equivalent exposure'), findsOneWidget);
    await openExpander(tester, 'Details');
    expect(find.text('Aperture contribution'), findsOneWidget);
    expect(find.text('Shutter contribution'), findsOneWidget);
    expect(find.text('ISO contribution'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('long exposure stacks filters live and gives bulb guidance', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LongExposureScreen()));
    // A photographer's shutter fraction, not a repeating decimal.
    await tester.enterText(find.byKey(const Key('long-base')), '1/30');
    await tester.enterText(find.byKey(const Key('long-stops')), '3, 7');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Filtered exposure time'));

    expect(find.text('Filtered exposure time'), findsOneWidget);
    expect(find.text('34.1 s'), findsOneWidget);
    expect(
      find.textContaining('From 1/30 s at 10 stops of ND.'),
      findsOneWidget,
    );
    expect(find.text('Total ND strength'), findsOneWidget);
    expect(find.text('10.0 stops'), findsOneWidget);
    // The tile and the guidance both name the required shutter mode.
    expect(find.text('Bulb or timer'), findsOneWidget);
    expect(find.textContaining('Bulb or timer mode'), findsOneWidget);

    await openExpander(tester, 'Details');
    expect(find.text('Filtered time (exact)'), findsOneWidget);
    expect(find.text('34.133333 s'), findsOneWidget);
    expect(find.text('10.00 stops'), findsOneWidget);
    // The fraction and its exact seconds are both recorded.
    expect(find.text('1/30 · 0.033333 s'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a decimal shutter time is still accepted', (tester) async {
    await tester.pumpWidget(app(const LongExposureScreen()));
    await tester.enterText(find.byKey(const Key('long-base')), '0.5');
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Filtered exposure time'));

    expect(find.text('8 min 32 s'), findsOneWidget);
    expect(
      find.textContaining('From 0.50 s at 10 stops of ND.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('flash exposure seeds its aperture and explains limitations', (
    tester,
  ) async {
    await tester.pumpWidget(app(const FlashExposureScreen()));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Recommended aperture'));
    expect(find.text('f/8'), findsOneWidget);
    expect(find.text('Effective guide number'), findsOneWidget);
    await openExpander(tester, 'Details');
    expect(find.textContaining('bounce loss'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('timelapse plans frames, playback, storage, and ramp', (
    tester,
  ) async {
    await tester.pumpWidget(app(const TimelapseScreen()));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Frames'));
    expect(find.text('361'), findsOneWidget);
    await openExpander(tester, 'Details');
    expect(find.text('Playback duration'), findsOneWidget);
    expect(find.text('12.033 s'), findsOneWidget);
    expect(find.text('8.81 GB'), findsOneWidget);
    expect(find.text('+2.00 stops'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'the capture duration is entered in minutes and stored in seconds',
    (tester) async {
      await tester.pumpWidget(app(const TimelapseScreen()));
      await tester.pumpAndSettle();

      final duration = find.byKey(
        const Key('timelapse-captureDurationSeconds'),
      );
      expect(duration, findsOneWidget);
      // 90 minutes of capture, typed in the unit the planner shows; the field is
      // a display adapter over the canonical seconds the calculator reads.
      await tester.enterText(duration, '90');
      await tester.pumpAndSettle();
      await reveal(tester, find.text('Save result'));
      await saveResult(tester);

      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      // The snapshot carries canonical seconds, not the displayed minutes.
      expect(snapshot.canonicalInputs['captureDurationSeconds'], 5400.0);
      await unmount(tester);
    },
  );

  testWidgets('macro planner seeds its configuration estimate', (tester) async {
    await tester.pumpWidget(app(const MacroScreen()));
    await tester.pumpAndSettle();
    // The three configurations are visible segments, not a dropdown.
    expect(find.byType(SegmentedButton<MacroConfiguration>), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Calculate macro setup'),
      findsNothing,
    );
    await reveal(tester, find.text('Subject width across frame'));
    expect(find.text('0.70×'), findsOneWidget);
    expect(find.text('f/13.6'), findsOneWidget);
    await openExpander(tester, 'Details');
    expect(find.textContaining('Working distance'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('macro and panorama expose their modes as chips and segments', (
    tester,
  ) async {
    await tester.pumpWidget(app(const PanoramaScreen()));
    await tester.pumpAndSettle();
    // Orientation is a visible chip row, not a dropdown, and it writes through
    // the same controllers the result is built from.
    expect(find.byType(ChoiceChip), findsWidgets);
    await reveal(tester, find.text('Camera orientation'));
    final portrait = find.widgetWithText(ChoiceChip, 'Portrait');
    await reveal(tester, portrait);
    await tester.tap(portrait);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Frames to shoot'));
    expect(find.textContaining('columns ×'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('panorama planner shows a complete ordered capture grid', (
    tester,
  ) async {
    await tester.pumpWidget(app(const PanoramaScreen()));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Frames to shoot'));
    expect(find.textContaining('3 columns × 2 rows'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    await openExpander(tester, 'Details');
    expect(find.textContaining('yaw'), findsWidgets);
    expect(find.textContaining('lens distortion'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'night-sky planner provides position, events, and exposure rules',
    (tester) async {
      await tester.pumpWidget(app(const AstronomyScreen()));
      // The heavy search stays explicit: no result exists until it is asked for.
      expect(find.byType(CalculationResultView), findsNothing);
      await reveal(tester, find.text('Plan night sky'));
      await tester.tap(find.text('Plan night sky'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('500 rule'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('500 rule'), findsOneWidget);
      expect(find.text('NPF rule'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Next events'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Next events'), findsOneWidget);
      expect(find.textContaining('true'), findsWidgets);
      await unmount(tester);
    },
  );

  testWidgets(
    'Milky Way orientation is accessible and saved with its convention',
    (tester) async {
      await tester.pumpWidget(app(const AstronomyScreen(), textScale: 2));
      await tester.scrollUntilVisible(
        find.text('Plan night sky'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Plan night sky'));
      await tester.pumpAndSettle();
      await openExpander(tester, 'Details');
      await tester.scrollUntilVisible(
        find.text('Milky Way orientation'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Milky Way orientation'), findsOneWidget);
      expect(find.textContaining('relative to horizon'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining(AstronomyCalculator.milkyWayOrientationConvention),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.textContaining('0° is horizontal, 90° is vertical'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Save result'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final save = find.widgetWithText(FilledButton, 'Save result');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(snapshot.formulaVersion, 2);
      expect(
        snapshot.canonicalOutputs['milkyWayOrientationDegrees'],
        inInclusiveRange(0, 180),
      );
      expect(
        snapshot.displayContext['milkyWayOrientationConvention'],
        AstronomyCalculator.milkyWayOrientationConvention,
      );
      expect(
        snapshot.assumptions.map((item) => item.value),
        contains(AstronomyCalculator.milkyWayOrientationConvention),
      );
      expect(
        snapshot.assumptions.map((item) => item.value).join(' '),
        contains('0.1°'),
      );
      await unmount(tester);
    },
  );

  testWidgets('night-sky plans preserve saved observer elevation', (
    tester,
  ) async {
    final location = SavedLocation(
      id: 'mountain-site',
      name: 'Mountain site',
      latitudeDegrees: 45.8326,
      longitudeDegrees: 6.8652,
      elevationMetres: 3842,
      timeZoneId: 'Europe/Paris',
      source: LocationSource.device,
      accuracyMetres: 8,
      createdAt: DateTime.utc(2026, 8, 26),
      updatedAt: DateTime.utc(2026, 8, 26),
    );
    await tester.pumpWidget(
      app(const AstronomyScreen(), savedLocations: [location]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved location (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mountain site').last);
    await tester.pumpAndSettle();
    // Elevation sits behind the one-line Site details row, so the row is opened
    // before the field it holds can be read or written.
    await openSiteDetails(tester);
    final elevationField = find.widgetWithText(
      TextField,
      'Observer elevation (m)',
    );
    await reveal(tester, elevationField);
    expect(tester.widget<TextField>(elevationField).controller!.text, '3842.0');

    await tester.scrollUntilVisible(
      find.text('Plan night sky'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan night sky'));
    await tester.pumpAndSettle();
    // The context card sits below the shorter result-first card, so it has to
    // be scrolled into view before it is built.
    await tester.scrollUntilVisible(
      find.text('Planning context'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Planning context'), findsOneWidget);
    // The name appears on the plan's context card and, while it is still built,
    // on the site picker that supplied it; the elevation row below pins which
    // card actually carries the applied site.
    expect(find.text('Mountain site'), findsWidgets);
    expect(find.textContaining('±8 m reported accuracy'), findsOneWidget);
    // Elevation presentation follows the length preference, like every other
    // distance in the app; the canonical value stays in metres.
    expect(find.text('3842.00 m'), findsOneWidget);
    expect(find.textContaining('SIMBAD'), findsOneWidget);
    expect(find.textContaining('approximately ±0.25°'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save result'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final save = find.widgetWithText(FilledButton, 'Save result');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
    final snapshot = (await DriftSnapshotRepository(
      database,
    ).listNewestFirst()).single;
    expect(snapshot.canonicalInputs['observerElevationMetres'], 3842.0);
    expect(snapshot.displayContext['timeZone'], 'Europe/Paris');
    expect(snapshot.displayContext['locationLabel'], 'Mountain site');
    expect(snapshot.displayContext['locationSource'], 'device');
    expect(snapshot.displayContext['locationAccuracyMetres'], 8.0);
    expect(snapshot.displayContext['locationUpdatedAtUtc'], isNotNull);
    expect(snapshot.displayContext['timeZoneConfidence'], contains('IANA'));
    expect(snapshot.displayContext['horizon'], contains('geometric'));
    expect(snapshot.displayContext['refraction'], 'not applied');
    expect(snapshot.displayContext['catalogVersion'], '2026.08');
    expect(snapshot.displayContext['catalogProvenance'], contains('SIMBAD'));
    expect(snapshot.displayContext['sourceFreshness'], contains('current'));
    expect(snapshot.displayContext['expectedAccuracy'], contains('±0.25°'));
    await unmount(tester);
  });

  testWidgets('night-sky planner opens a direct local date and time picker', (
    tester,
  ) async {
    final location = SavedLocation(
      id: 'paris',
      name: 'Paris',
      latitudeDegrees: 48.8566,
      longitudeDegrees: 2.3522,
      timeZoneId: 'Europe/Paris',
      source: LocationSource.manual,
      createdAt: DateTime.utc(2026, 8, 26),
      updatedAt: DateTime.utc(2026, 8, 26),
    );
    await tester.pumpWidget(
      app(const AstronomyScreen(), savedLocations: [location]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved location (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paris').last);
    await tester.pumpAndSettle();

    expect(find.text('Choose local date and time'), findsOneWidget);
    expect(find.textContaining('Europe/Paris'), findsWidgets);
    final chooseTime = find.text('Choose local date and time');
    await tester.ensureVisible(chooseTime);
    await tester.pumpAndSettle();
    await tester.tap(chooseTime);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('alignment planner preserves fallbacks and solar safety', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const AlignmentScreen(capabilities: PlanningCapabilities.fallback())),
    );
    // The solar warning is a standing card in the form - not something behind a
    // disclosure - but the form is a lazy list, so it is scrolled to before it
    // is read. A safety notice that is only reachable is still a notice.
    final solarSafety = find.textContaining('never look at the Sun');
    await reveal(tester, solarSafety);
    expect(solarSafety, findsOneWidget);
    // The heavy search is an explicit action, named for what it produces.
    expect(find.byType(CalculationResultView), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Find alignment'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    final search = find.byKey(const Key('alignment-search'));
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    await tester.tap(search);
    await tester.pumpAndSettle();
    await openExpander(tester, 'Details');
    await tester.scrollUntilVisible(
      find.text('Search resolution'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Search resolution'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('AR'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('AR'));
    await tester.pump();
    expect(find.text('AR unavailable'), findsOneWidget);
    expect(find.textContaining('remain fully usable'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('alignment planner selects an inclusive local date range', (
    tester,
  ) async {
    final location = SavedLocation(
      id: 'paris-alignment',
      name: 'Paris alignment',
      latitudeDegrees: 48.8566,
      longitudeDegrees: 2.3522,
      elevationMetres: 35,
      timeZoneId: 'Europe/Paris',
      source: LocationSource.manual,
      createdAt: DateTime.utc(2026, 8, 29),
      updatedAt: DateTime.utc(2026, 8, 29),
    );
    await tester.pumpWidget(
      app(const AlignmentScreen(), savedLocations: [location]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<SavedLocation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paris alignment').last);
    await tester.pumpAndSettle();

    final chooseRange = find.byKey(const Key('alignment-date-range'));
    await tester.scrollUntilVisible(
      chooseRange,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Europe/Paris'), findsWidgets);
    await tester.tap(chooseRange);
    await tester.pumpAndSettle();
    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('alignment timeline groups readable candidates by local date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AlignmentTimeline(
            timeZoneId: 'Europe/Paris',
            candidates: [
              AlignmentCandidate(
                instantUtc: DateTime.utc(2026, 3, 28, 23, 30),
                azimuthDegrees: 179.4,
                altitudeDegrees: 38.2,
                angularErrorDegrees: 0.62,
                aboveHorizon: true,
              ),
              AlignmentCandidate(
                instantUtc: DateTime.utc(2026, 3, 29, 22, 30),
                azimuthDegrees: 181.1,
                altitudeDegrees: -2.5,
                angularErrorDegrees: 1.21,
                aboveHorizon: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('2026-03-29'), findsOneWidget);
    expect(find.text('2026-03-30'), findsOneWidget);
    expect(find.textContaining('Europe/Paris'), findsNWidgets(2));
    expect(find.textContaining('above horizon'), findsOneWidget);
    expect(find.textContaining('below horizon'), findsOneWidget);
    expect(find.text('0.62° error'), findsOneWidget);
  });

  testWidgets('alignment plan displays and saves reproducibility context', (
    tester,
  ) async {
    final location = SavedLocation(
      id: 'device-ridge',
      name: 'Device ridge',
      latitudeDegrees: 45.8326,
      longitudeDegrees: 6.8652,
      elevationMetres: 1200,
      timeZoneId: 'Europe/Paris',
      source: LocationSource.device,
      accuracyMetres: 8,
      createdAt: DateTime.utc(2026, 8, 29),
      updatedAt: DateTime.utc(2026, 8, 29),
    );
    await tester.pumpWidget(
      app(const AlignmentScreen(), savedLocations: [location]),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<SavedLocation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device ridge').last);
    await tester.pumpAndSettle();

    final tolerance = find.widgetWithText(
      TextField,
      'Angular tolerance (degrees)',
    );
    await tester.scrollUntilVisible(
      tolerance,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(tolerance, '180');
    final search = find.byKey(const Key('alignment-search'));
    await tester.scrollUntilVisible(
      search,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Planning context'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Planning context'), findsOneWidget);
    // The name also labels the site picker while that is still built, so the
    // claim is that the context card carries it, not that it appears once.
    expect(find.text('Device ridge'), findsWidgets);
    expect(find.textContaining('±8 m reported accuracy'), findsOneWidget);

    final save = find.widgetWithText(FilledButton, 'Save result');
    await tester.scrollUntilVisible(
      save,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    final snapshot = (await DriftSnapshotRepository(
      database,
    ).listNewestFirst()).single;
    expect(snapshot.formulaVersion, 2);
    expect(snapshot.canonicalInputs['startLocalDate'], isNotNull);
    expect(snapshot.canonicalInputs['endLocalDate'], isNotNull);
    expect(snapshot.canonicalInputs['startUtc'], endsWith('Z'));
    expect(snapshot.canonicalInputs['endUtc'], endsWith('Z'));
    expect(snapshot.displayContext['locationLabel'], 'Device ridge');
    expect(snapshot.displayContext['locationSource'], contains('device'));
    expect(snapshot.displayContext['locationAccuracyMetres'], 8.0);
    expect(snapshot.displayContext['timeZone'], 'Europe/Paris');
    expect(snapshot.displayContext['timeZoneConfidence'], contains('IANA'));
    expect(snapshot.displayContext['observerElevationMetres'], 1200.0);
    expect(snapshot.displayContext['targetElevationMetres'], 820.0);
    expect(snapshot.displayContext['horizon'], contains('geometric'));
    expect(snapshot.displayContext['refraction'], 'not applied');
    expect(snapshot.displayContext['sourceFreshness'], contains('formula v2'));
    expect(snapshot.displayContext['expectedAccuracy'], contains('10 minutes'));
    await unmount(tester);
  });

  testWidgets('an over-sized filter stack is refused, not crashed', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LongExposureScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'ND filter strengths (stops)'),
      '1000000000000',
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('overflows the exposure time'), findsOneWidget);
    expect(find.byType(CalculationResultView), findsNothing);
    await unmount(tester);
  });

  testWidgets('an unshootable panorama grid is refused, not crashed', (
    tester,
  ) async {
    await tester.pumpWidget(app(const PanoramaScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Focal length (mm)'),
      '1000000000000',
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Too many frames: reduce the coverage'),
      findsOneWidget,
    );
    expect(find.byType(CalculationResultView), findsNothing);
    await unmount(tester);
  });

  testWidgets('preferences change result presentation, not calculations', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const DepthOfFieldScreen(),
        preferences: const AppPreferences(
          lengthDisplay: LengthDisplay.imperial,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Hyperfocal distance'));
    expect(find.textContaining('ft'), findsWidgets);
    await unmount(tester);

    await tester.pumpWidget(
      app(
        const LongExposureScreen(),
        preferences: const AppPreferences(
          shutterDisplay: ShutterDisplay.conventional,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Filtered exposure time'));
    expect(find.textContaining('32 s'), findsOneWidget);
    await saveResult(tester);
    final snapshot = (await DriftSnapshotRepository(
      database,
    ).listNewestFirst()).single;
    expect(snapshot.displayContext['fractionStep'], 'third');
    expect(snapshot.displayContext['shutterLabel'], '32 s');
    await unmount(tester);
  });

  testWidgets('planner defaults come from preferences and remain overridable', (
    tester,
  ) async {
    const preferences = AppPreferences(
      defaultStarSharpness: DefaultStarSharpness.strict,
      defaultAlignmentToleranceDegrees: 5,
    );
    await tester.pumpWidget(
      app(const AstronomyScreen(), preferences: preferences),
    );
    await tester.pumpAndSettle();
    await openExpander(tester, 'More settings');
    await tester.scrollUntilVisible(
      find.text('Default: strict from Settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Default: strict from Settings'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<StarSharpnessTolerance>>(
            find.byType(SegmentedButton<StarSharpnessTolerance>),
          )
          .selected,
      {StarSharpnessTolerance.strict},
    );
    await unmount(tester);

    await tester.pumpWidget(
      app(const AlignmentScreen(), preferences: preferences),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Default: 5° from Settings'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Default: 5° from Settings'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'Angular tolerance (degrees)'),
          )
          .controller!
          .text,
      '5',
    );
    await unmount(tester);
  });

  testWidgets('calculator screens remain scrollable at 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      app(const ExposureComparisonScreen(), textScale: 2),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Equivalent exposure'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    // The live answer renders at 2x text without a Calculate action.
    expect(find.text('Equivalent exposure'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('saved equipment applies values and identifies provenance', (
    tester,
  ) async {
    final repository = DriftEquipmentRepository(database);
    final now = DateTime.utc(2026, 8, 20);
    await repository.createLens(
      Lens(
        id: 'lens-ui',
        name: 'Saved 85 mm',
        minimumFocalLengthMm: 85,
        maximumFocalLengthMm: 85,
        minimumAperture: 1.8,
        provenance: const EquipmentProvenance(source: EquipmentSource.user),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(app(const DepthOfFieldScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved 85 mm').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('From Saved 85 mm'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('dof-focal')))
          .controller!
          .text,
      '85.0',
    );
    expect(find.textContaining('edit these values'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets(
    'an empty kit hides the optional pickers and a saved camera is primary',
    (tester) async {
      // Nothing to pick is not a row: manual entry is the primary path.
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Saved lens (optional)'), findsNothing);
      expect(find.text('Saved camera (optional)'), findsNothing);
      await unmount(tester);

      // A saved camera supplies the circle of confusion, so its picker sits with
      // the shot parameters - reachable without opening the advanced group - and
      // applying it writes through the same controller the calculator reads.
      final now = DateTime.utc(2026, 8, 26);
      await DriftEquipmentRepository(database).createCamera(
        CameraBody(
          id: 'camera-primary',
          name: 'Primary Camera',
          sensorWidthMm: 23.5,
          sensorHeightMm: 15.6,
          defaultCircleOfConfusionMm: 0.019,
          provenance: const EquipmentProvenance(source: EquipmentSource.user),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      // The advanced group stays closed: that the picker is reachable here is the
      // point.
      expect(find.text('Circle of confusion (mm)'), findsNothing);
      await tester.tap(find.text('Saved camera (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Primary Camera').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('From Primary Camera'), findsOneWidget);
      expect(
        find.textContaining('circle of confusion 0.019 mm'),
        findsOneWidget,
      );
      await unmount(tester);
    },
  );

  testWidgets('optics applies equipment and saves exact provenance', (
    tester,
  ) async {
    final repository = DriftEquipmentRepository(database);
    final now = DateTime.utc(2026, 8, 26);
    await repository.createCamera(
      CameraBody(
        id: 'camera-optics',
        name: 'APS-C Camera',
        sensorWidthMm: 23.5,
        sensorHeightMm: 15.6,
        defaultCircleOfConfusionMm: 0.019,
        provenance: const EquipmentProvenance(
          source: EquipmentSource.userOverride,
          note: 'Measured active area',
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repository.createLens(
      Lens(
        id: 'lens-optics',
        name: 'Prime 35',
        minimumFocalLengthMm: 35,
        maximumFocalLengthMm: 35,
        minimumAperture: 1.8,
        provenance: const EquipmentProvenance(source: EquipmentSource.user),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(app(const FieldOfViewScreen()));
    await tester.pumpAndSettle();

    // The saved lens is a primary picker; its applied-value notice appears
    // above More settings, so it is applied before the section is opened.
    // Selecting a saved item above that section rebuilds the list and collapses
    // the expander, which is why the order matters here.
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prime 35').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('From Prime 35'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('fieldOfView-focalLengthMm')))
          .controller!
          .text,
      '35.0',
    );

    // The camera picker is a primary control too: a saved camera supplies the
    // sensor size the field of view is built from, so it is applied before the
    // advanced group is opened.
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APS-C Camera').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('From APS-C Camera'), findsOneWidget);

    // The raw sensor dimensions stay behind More settings.
    await openExpander(tester, 'More settings');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('fieldOfView-sensorWidthMm')))
          .controller!
          .text,
      '23.5',
    );

    // The answer is live: no Calculate action stands between the equipment and
    // the result, and saving records both applied items.
    expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);
    await saveResult(tester);
    final snapshot = (await DriftSnapshotRepository(
      database,
    ).listNewestFirst()).single;
    expect(snapshot.equipment.map((item) => item.id), [
      'camera-optics',
      'lens-optics',
    ]);
    expect(snapshot.equipment.first.values['sensorWidthMm'], 23.5);
    await unmount(tester);
  });

  testWidgets('flash and planner elevations honor the imperial preference', (
    tester,
  ) async {
    const imperial = AppPreferences(lengthDisplay: LengthDisplay.imperial);

    await tester.pumpWidget(
      app(const FlashExposureScreen(), preferences: imperial),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Recommended aperture'));
    // Guide number 40 m is about 131 ft, and the snapshot records the unit.
    expect(find.textContaining('131.2'), findsWidgets);
    expect(find.textContaining('ft'), findsWidgets);
    await saveResult(tester);

    final flashSnapshot = (await DriftSnapshotRepository(
      database,
    ).listNewestFirst()).single;
    expect(flashSnapshot.displayContext['distanceUnit'], 'imperial');
    await unmount(tester);
  });

  testWidgets('night-sky elevation follows the length preference', (
    tester,
  ) async {
    const imperial = AppPreferences(lengthDisplay: LengthDisplay.imperial);
    await tester.pumpWidget(
      app(const AstronomyScreen(), preferences: imperial),
    );
    await tester.pumpAndSettle();
    await openSiteDetails(tester);
    final elevation = find.widgetWithText(TextField, 'Observer elevation (m)');
    await reveal(tester, elevation);
    await tester.enterText(elevation, '1200');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Plan night sky'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan night sky'));
    await tester.pumpAndSettle();
    // 1200 m is about 3937 ft; the canonical input stays in metres. The
    // elevation sits in the planning-context card below the result now, so the
    // list has to build it before it can be asserted.
    await tester.scrollUntilVisible(
      find.textContaining('3937.01 ft'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('3937.01 ft'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('expanded optics and macro honor imperial display preference', (
    tester,
  ) async {
    const imperial = AppPreferences(lengthDisplay: LengthDisplay.imperial);
    await tester.pumpWidget(
      app(const FieldOfViewScreen(), preferences: imperial),
    );
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Scene width at this distance'));
    expect(find.text('Scene width at this distance'), findsOneWidget);
    expect(
      tester
          .widgetList<Text>(find.textContaining('ft'))
          // Values render as rich spans (number + quiet unit), so read the
          // plain text rather than Text.data.
          .map((widget) => widget.data ?? widget.textSpan?.toPlainText()),
      containsAll(<String>['23.62 ft', 'Scene height 15.75 ft.']),
    );
    await unmount(tester);

    await tester.pumpWidget(app(const MacroScreen(), preferences: imperial));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Subject width across frame'));
    expect(find.text('2.02 in'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('every calculator saves canonical results to the local store', (
    tester,
  ) async {
    /// The cheap calculators update their answer live, so saving is a direct
    /// action on the result that is already on screen.
    Future<void> saveLiveResult(Widget screen) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      await saveResult(tester);
      expect(find.text('Result saved on this device.'), findsOneWidget);
      await unmount(tester);
    }

    /// The heavy planners keep their explicit search; the save follows it.
    Future<void> planAndSave(Widget screen, String action) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(action));
      await tester.tap(find.text(action));
      await tester.pumpAndSettle();
      await saveResult(tester);
      expect(find.text('Result saved on this device.'), findsOneWidget);
      await unmount(tester);
    }

    await saveLiveResult(const DepthOfFieldScreen());
    await saveLiveResult(const ExposureComparisonScreen());
    await saveLiveResult(const LongExposureScreen());
    await saveLiveResult(const FlashExposureScreen());
    await saveLiveResult(const TimelapseScreen());
    await saveLiveResult(const MacroScreen());
    await saveLiveResult(const FieldOfViewScreen());
    await saveLiveResult(const DiffractionScreen());
    await saveLiveResult(const FocusStackScreen());
    await saveLiveResult(const PanoramaScreen());
    await planAndSave(const AstronomyScreen(), 'Plan night sky');
    await planAndSave(const AlignmentScreen(), 'Find alignment');

    final snapshots = await DriftSnapshotRepository(database).listNewestFirst();
    expect(snapshots, hasLength(12));
    expect(snapshots.map((snapshot) => snapshot.calculatorId).toSet(), <String>{
      'depth_of_field',
      'exposure_comparison',
      'long_exposure_nd',
      'flash_exposure',
      'timelapse',
      'macro',
      'field_of_view',
      'diffraction',
      'focus_stacking',
      'panorama',
      'astronomy',
      'sun_moon_alignment',
    });
    expect(
      snapshots.every(
        (snapshot) =>
            snapshot.canonicalInputs.isNotEmpty &&
            snapshot.canonicalOutputs.isNotEmpty &&
            snapshot.displayContext.isNotEmpty,
      ),
      isTrue,
    );

    // "Non-empty" alone would accept a mis-keyed or swapped payload. Pin the
    // formula version and the exact provenance keys each calculator promises,
    // so a renamed or dropped field fails here instead of in the saved list.
    final byCalculator = <String, CalculationSnapshot>{
      for (final snapshot in snapshots) snapshot.calculatorId: snapshot,
    };
    const expectedProvenance =
        <String, (int, List<String>, List<String>, List<String>)>{
          'depth_of_field': (
            1,
            [
              'focalLengthMm',
              'aperture',
              'focusDistanceMm',
              'circleOfConfusionMm',
            ],
            [
              'hyperfocalDistanceMm',
              'nearLimitMm',
              'farLimitMm',
              'totalDepthMm',
            ],
            ['distanceUnit', 'infinityLabel'],
          ),
          'exposure_comparison': (
            1,
            ['baseline', 'candidate'],
            [
              'totalDifferenceStops',
              'apertureContributionStops',
              'timeContributionStops',
              'isoContributionStops',
              'multiplier',
              'direction',
            ],
            ['stopPrecision', 'multiplierPrecision'],
          ),
          'long_exposure_nd': (
            1,
            ['baseTimeSeconds', 'filterStops', 'targetTimeSeconds'],
            [
              'filteredTimeSeconds',
              'totalStrengthStops',
              'requiredStrengthStops',
              'requiresBulbOrTimer',
            ],
            ['shutterDisplay', 'fractionStep', 'shutterLabel'],
          ),
          'flash_exposure': (
            1,
            [
              'guideNumberIso100Metres',
              'iso',
              'powerFraction',
              'subjectDistanceMetres',
            ],
            [
              'effectiveGuideNumberMetres',
              'recommendedAperture',
              'powerReductionStops',
              'fullPowerRangeAtRecommendedApertureMetres',
            ],
            ['distanceUnit'],
          ),
          'timelapse': (
            1,
            [
              'intervalSeconds',
              'captureDurationSeconds',
              'playbackFps',
              'megabytesPerFrame',
              'startExposureSeconds',
              'endExposureSeconds',
            ],
            [
              'frameCount',
              'playbackDurationSeconds',
              'storageMegabytes',
              'exposureRampStops',
              'maximumDutyCycle',
            ],
            ['storageUnits'],
          ),
          'macro': (
            1,
            [
              'configuration',
              'focalLengthMm',
              'extensionLengthMm',
              'nativeMagnification',
              'nominalAperture',
              'sensorWidthMm',
            ],
            [
              'magnification',
              'effectiveAperture',
              'subjectWidthMm',
              'exposureCompensationStops',
            ],
            ['lengthUnit'],
          ),
          'field_of_view': (
            1,
            ['sensorWidthMm', 'sensorHeightMm', 'focalLengthMm', 'distanceMm'],
            [
              'horizontalDegrees',
              'verticalDegrees',
              'diagonalDegrees',
              'sceneWidthMm',
              'sceneHeightMm',
            ],
            ['distanceUnit'],
          ),
          'diffraction': (
            1,
            ['aperture', 'wavelengthNm', 'pixelPitchMicrometres'],
            ['airyDiskMicrometres', 'airyRadiusMicrometres', 'airyDiskPixels'],
            ['distanceUnit'],
          ),
          'focus_stacking': (
            1,
            [
              'focalLengthMm',
              'aperture',
              'circleOfConfusionMm',
              'nearDistanceMm',
              'farDistanceMm',
              'overlapPercent',
            ],
            ['frameCount', 'focusDistancesMm'],
            ['distanceUnit'],
          ),
          'panorama': (
            1,
            [
              'sensorWidthMm',
              'sensorHeightMm',
              'focalLengthMm',
              'orientation',
              'horizontalBoundsDegrees',
              'verticalBoundsDegrees',
              'horizontalOverlapPercent',
              'verticalOverlapPercent',
            ],
            [
              'columns',
              'rows',
              'frameCount',
              'frameHorizontalDegrees',
              'frameVerticalDegrees',
              'horizontalIncrementDegrees',
              'verticalIncrementDegrees',
              'horizontalCoverageDegrees',
              'verticalCoverageDegrees',
              'frames',
            ],
            ['angleUnit', 'positionOrigin'],
          ),
          'astronomy': (
            2,
            [
              'latitudeDegrees',
              'longitudeDegrees',
              'observerElevationMetres',
              'instantUtc',
              'target',
              'rightAscensionDegrees',
              'declinationDegrees',
              'focalLengthMm',
              'cropFactor',
              'aperture',
              'pixelPitchMicrometres',
              'desiredTrailDegrees',
              'selectedRule',
              'sharpnessTolerance',
            ],
            [
              'altitudeDegrees',
              'azimuthDegrees',
              'aboveHorizon',
              'rule500Seconds',
              'npfSeconds',
              'recommendedShutterSeconds',
              'events',
              'fieldChecklist',
            ],
            [
              'timeZone',
              'catalogVersion',
              'catalogProvenance',
              'sourceFreshness',
              'expectedAccuracy',
            ],
          ),
          'sun_moon_alignment': (
            2,
            [
              'body',
              'observerLatitudeDegrees',
              'observerLongitudeDegrees',
              'observerElevationMetres',
              'targetElevationMetres',
              'targetDistanceMetres',
              'desiredBearingDegrees',
              'angularToleranceDegrees',
              'startLocalDate',
              'endLocalDate',
              'startUtc',
              'endUtc',
            ],
            [
              'desiredAltitudeDegrees',
              'sampleMinutes',
              'candidates',
              'fieldChecklist',
            ],
            [
              'timeZone',
              'northReference',
              'mapMode',
              'locationLabel',
              'horizon',
              'refraction',
              'sourceFreshness',
              'expectedAccuracy',
            ],
          ),
        };

    for (final entry in expectedProvenance.entries) {
      final snapshot = byCalculator[entry.key];
      expect(snapshot, isNotNull, reason: '${entry.key} was not saved');
      final (version, inputKeys, outputKeys, contextKeys) = entry.value;
      expect(
        snapshot!.formulaVersion,
        version,
        reason: '${entry.key} saved the wrong formula version',
      );
      expect(
        snapshot.canonicalInputs.keys,
        containsAll(inputKeys),
        reason: '${entry.key} lost canonical inputs',
      );
      expect(
        snapshot.canonicalOutputs.keys,
        containsAll(outputKeys),
        reason: '${entry.key} lost canonical outputs',
      );
      expect(
        snapshot.displayContext.keys,
        containsAll(contextKeys),
        reason: '${entry.key} lost reproducibility context',
      );
    }

    // One absolute anchor: the default depth-of-field payload must carry the
    // canonical millimetre values and their thin-lens hyperfocal result.
    final depthOfField = byCalculator['depth_of_field']!;
    expect(depthOfField.canonicalInputs, <String, Object?>{
      'focalLengthMm': 50.0,
      'aperture': 8.0,
      'focusDistanceMm': 10000.0,
      'circleOfConfusionMm': 0.03,
    });
    expect(
      depthOfField.canonicalOutputs['hyperfocalDistanceMm'] as num,
      closeTo(50 * 50 / (8 * 0.03) + 50, 0.01),
    );
  });
}
