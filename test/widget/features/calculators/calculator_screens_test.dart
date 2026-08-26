import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';
import 'package:photography_assistant/features/planning/domain/saved_location.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

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

  testWidgets('depth of field labels inputs, validates, and explains result', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DepthOfFieldScreen()));

    expect(find.text('Focal length (mm)'), findsOneWidget);
    expect(find.text('Circle of confusion (mm)'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('dof-focal')), '0');
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final calculate = find.widgetWithText(FilledButton, 'Calculate');
    await tester.ensureVisible(calculate);
    await tester.pumpAndSettle();
    await tester.tap(calculate);
    await tester.pump();
    expect(find.text('Enter a positive finite value.'), findsWidgets);

    await tester.enterText(find.byKey(const Key('dof-focal')), '50');
    await tester.tap(find.text('Calculate'));
    await tester.pump();
    expect(find.text('Near limit'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('Assumptions'), findsOneWidget);
    expect(find.textContaining('Thin-lens geometric model'), findsOneWidget);
    expect(find.text('Save result'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('exposure comparison reports component result and direction', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ExposureComparisonScreen()));
    await tester.tap(find.text('Compare exposures'));
    await tester.pump();

    expect(find.text('Equivalent exposure'), findsOneWidget);
    expect(find.text('Aperture contribution'), findsOneWidget);
    expect(find.text('Shutter contribution'), findsOneWidget);
    expect(find.text('ISO contribution'), findsOneWidget);
  });

  testWidgets('long exposure calculates stacked filters and bulb guidance', (
    tester,
  ) async {
    await tester.pumpWidget(app(const LongExposureScreen()));
    await tester.enterText(
      find.byKey(const Key('long-base')),
      '0.0333333333333333',
    );
    await tester.enterText(find.byKey(const Key('long-stops')), '3, 7');
    await tester.tap(find.text('Calculate exposure'));
    await tester.pump();

    expect(find.text('34.133333 seconds'), findsOneWidget);
    expect(find.textContaining('Bulb or timer'), findsOneWidget);
    expect(find.text('10.00 stops'), findsOneWidget);
  });

  testWidgets('flash exposure calculates aperture and explains limitations', (
    tester,
  ) async {
    await tester.pumpWidget(app(const FlashExposureScreen()));
    await tester.tap(find.text('Calculate flash exposure'));
    await tester.pump();
    expect(find.text('f/8.0'), findsOneWidget);
    expect(find.text('Effective guide number'), findsOneWidget);
    expect(find.textContaining('bounce loss'), findsOneWidget);
  });

  testWidgets('timelapse plans frames, playback, storage, and ramp', (
    tester,
  ) async {
    await tester.pumpWidget(app(const TimelapseScreen()));
    await tester.tap(find.text('Plan timelapse'));
    await tester.pump();
    expect(find.text('361'), findsOneWidget);
    expect(find.text('12.03 seconds'), findsOneWidget);
    expect(find.text('8.81 GB'), findsOneWidget);
    expect(find.text('+2.00 stops'), findsOneWidget);
  });

  testWidgets('macro planner calculates and explains its approximation', (
    tester,
  ) async {
    await tester.pumpWidget(app(const MacroScreen()));
    await tester.scrollUntilVisible(
      find.text('Calculate macro setup'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate macro setup'));
    await tester.pump();
    expect(find.text('0.70×'), findsOneWidget);
    expect(find.text('f/13.6'), findsOneWidget);
    expect(find.textContaining('Working distance'), findsOneWidget);
  });

  testWidgets('panorama planner shows a complete ordered capture grid', (
    tester,
  ) async {
    await tester.pumpWidget(app(const PanoramaScreen()));
    await tester.scrollUntilVisible(
      find.text('Plan panorama'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan panorama'));
    await tester.pump();
    expect(find.text('3 columns × 2 rows'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.textContaining('yaw'), findsWidgets);
    expect(find.textContaining('lens distortion'), findsOneWidget);
  });

  testWidgets(
    'night-sky planner provides position, events, and exposure rules',
    (tester) async {
      await tester.pumpWidget(app(const AstronomyScreen()));
      await tester.scrollUntilVisible(
        find.text('Plan night sky'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Plan night sky'));
      await tester.pump();
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
    await tester.tap(find.text('Mountain site').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(TextField, 'Observer elevation (m)'),
          )
          .controller!
          .text,
      '3842.0',
    );

    await tester.scrollUntilVisible(
      find.text('Plan night sky'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Plan night sky'));
    await tester.pumpAndSettle();
    expect(find.textContaining('elevation 3842.0 m'), findsOneWidget);
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
  });

  testWidgets('alignment planner preserves fallbacks and solar safety', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(const AlignmentScreen(capabilities: PlanningCapabilities.fallback())),
    );
    expect(find.textContaining('never look at the Sun'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Search alignments'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search alignments'));
    await tester.pump();
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
    await tester.tap(find.text('Calculate'));
    await tester.pump();
    expect(find.textContaining('ft'), findsWidgets);

    await tester.pumpWidget(
      app(
        const LongExposureScreen(),
        preferences: const AppPreferences(
          shutterDisplay: ShutterDisplay.conventional,
        ),
      ),
    );
    await tester.tap(find.text('Calculate exposure'));
    await tester.pump();
    expect(find.text('34.1 s'), findsOneWidget);
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
      find.text('Compare exposures'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Compare exposures'), findsOneWidget);
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
  });

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
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('APS-C Camera').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prime 35').last);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('fieldOfView-sensorWidthMm')))
          .controller!
          .text,
      '23.5',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('fieldOfView-focalLengthMm')))
          .controller!
          .text,
      '35.0',
    );
    expect(find.textContaining('From APS-C Camera'), findsOneWidget);
    expect(find.textContaining('From Prime 35'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final calculateOptics = find.widgetWithText(FilledButton, 'Calculate');
    await tester.ensureVisible(calculateOptics);
    await tester.pumpAndSettle();
    await tester.tap(calculateOptics);
    await tester.pumpAndSettle();
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
    expect(snapshot.equipment.map((item) => item.id), [
      'camera-optics',
      'lens-optics',
    ]);
    expect(snapshot.equipment.first.values['sensorWidthMm'], 23.5);
  });

  testWidgets('expanded optics and macro honor imperial display preference', (
    tester,
  ) async {
    const imperial = AppPreferences(lengthDisplay: LengthDisplay.imperial);
    await tester.pumpWidget(
      app(const FieldOfViewScreen(), preferences: imperial),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final calculate = find.widgetWithText(FilledButton, 'Calculate');
    await tester.ensureVisible(calculate);
    await tester.pumpAndSettle();
    await tester.tap(calculate);
    await tester.pump();
    expect(find.text('Scene coverage'), findsOneWidget);
    expect(
      tester
          .widgetList<Text>(find.textContaining('ft'))
          .map((widget) => widget.data),
      contains('23.62 ft × 15.75 ft'),
    );

    await tester.pumpWidget(app(const MacroScreen(), preferences: imperial));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Calculate macro setup'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Calculate macro setup'));
    await tester.pump();
    expect(find.text('2.02 in'), findsOneWidget);
  });

  testWidgets('every calculator saves canonical results to the local store', (
    tester,
  ) async {
    Future<void> calculateAndSave(Widget screen, String calculateLabel) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(calculateLabel),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).first, const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text(calculateLabel));
      await tester.pumpAndSettle();
      final saveButton = find.widgetWithText(FilledButton, 'Save result');
      await tester.scrollUntilVisible(
        saveButton,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      expect(find.text('Result saved on this device.'), findsOneWidget);
    }

    await calculateAndSave(const DepthOfFieldScreen(), 'Calculate');
    await calculateAndSave(
      const ExposureComparisonScreen(),
      'Compare exposures',
    );
    await calculateAndSave(const LongExposureScreen(), 'Calculate exposure');
    await calculateAndSave(
      const FlashExposureScreen(),
      'Calculate flash exposure',
    );
    await calculateAndSave(const TimelapseScreen(), 'Plan timelapse');
    await calculateAndSave(const MacroScreen(), 'Calculate macro setup');
    await calculateAndSave(const FieldOfViewScreen(), 'Calculate');
    await calculateAndSave(const DiffractionScreen(), 'Calculate');
    await calculateAndSave(const FocusStackScreen(), 'Calculate');
    await calculateAndSave(const PanoramaScreen(), 'Plan panorama');
    await calculateAndSave(const AstronomyScreen(), 'Plan night sky');
    await calculateAndSave(const AlignmentScreen(), 'Search alignments');

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
  });
}
