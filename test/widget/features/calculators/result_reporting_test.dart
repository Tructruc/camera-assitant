import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, NdFilter, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    show CameraBody, EquipmentProvenance, EquipmentSource, Lens, NdFilter;
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';

/// Covers the presentation gaps found by the Phase 20 convergence pass:
/// derived depth rows, stated limitations, applied-value provenance, camera
/// provenance in the planners, and reported calculator warnings.
void main() {
  final now = DateTime.utc(2026, 9, 10);
  late AppDatabase database;
  late DriftEquipmentRepository repository;

  setUp(() {
    database = AppDatabase.inMemory();
    repository = DriftEquipmentRepository(database);
  });
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(repository),
    ],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

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
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  CameraBody savedCamera() => CameraBody(
    id: 'camera-ff',
    name: 'Full Frame Camera',
    sensorWidthMm: 36,
    sensorHeightMm: 24,
    provenance: const EquipmentProvenance(
      source: EquipmentSource.userOverride,
      note: 'Measured active area',
    ),
    createdAt: now,
    updatedAt: now,
  );

  Lens savedLens() => Lens(
    id: 'lens-50',
    name: 'Standard 50',
    minimumFocalLengthMm: 50,
    maximumFocalLengthMm: 50,
    minimumAperture: 1.8,
    provenance: const EquipmentProvenance(source: EquipmentSource.bundled),
    createdAt: now,
    updatedAt: now,
  );

  testWidgets('depth of field reports the depth on each side of focus', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DepthOfFieldScreen()));
    await tester.pumpAndSettle();
    final calculate = find.widgetWithText(FilledButton, 'Calculate');
    await reveal(tester, calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(find.text('Depth in front of focus'), findsOneWidget);
    expect(find.text('Depth behind focus'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('exposure comparison states its model limitations', (
    tester,
  ) async {
    await tester.pumpWidget(app(const ExposureComparisonScreen()));
    await tester.pumpAndSettle();
    final calculate = find.widgetWithText(FilledButton, 'Compare exposures');
    await reveal(tester, calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Limitation: this comparison ignores'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('the ND notice shows the applied value and its provenance', (
    tester,
  ) async {
    await repository.createFilter(
      NdFilter(
        id: 'filter-ten-stop',
        name: '10-stop ND',
        strengthStops: 10,
        provenance: const EquipmentProvenance(source: EquipmentSource.user),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(app(const LongExposureScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved ND filter (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10-stop ND').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('10.0 stops applied'), findsOneWidget);
    expect(find.textContaining('(user-entered)'), findsOneWidget);

    // A one-off override must change the notice, not just the field.
    await tester.enterText(
      find.widgetWithText(TextField, 'ND filter strengths (stops)'),
      '6',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('6 stops applied'), findsOneWidget);
    expect(find.textContaining('10.0 stops applied'), findsNothing);
    await unmount(tester);
  });

  testWidgets('night-sky planner applies a saved camera crop factor', (
    tester,
  ) async {
    await repository.createCamera(savedCamera());
    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();
    final cameraPicker = find.text('Saved camera (optional)');
    await reveal(tester, cameraPicker);
    await tester.tap(cameraPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();

    final cropFactorField = find.widgetWithText(TextField, 'Crop factor');
    await reveal(tester, cropFactorField);
    final cropFactor = tester
        .widget<TextField>(cropFactorField)
        .controller!
        .text;
    expect(cropFactor, '1.00');

    // The provenance notice sits above the fields, so scroll back to it.
    final notice = find.textContaining('1.00× crop factor');
    await reveal(tester, notice, delta: -300);
    expect(notice, findsOneWidget);
    expect(find.textContaining('(user override)'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('macro planner applies a saved camera sensor width', (
    tester,
  ) async {
    await repository.createCamera(savedCamera());
    await repository.createLens(savedLens());
    await tester.pumpWidget(app(const MacroScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved camera (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();

    final sensorWidthField = find.widgetWithText(
      TextField,
      'Sensor width (mm)',
    );
    await reveal(tester, sensorWidthField);
    expect(tester.widget<TextField>(sensorWidthField).controller!.text, '36.0');
    expect(find.textContaining('36.0 mm sensor width'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('focus stacking surfaces its frame-limit warning', (
    tester,
  ) async {
    await tester.pumpWidget(app(const FocusStackScreen()));
    await tester.pumpAndSettle();
    final cocField = find.byKey(const Key('focusStack-circleOfConfusionMm'));
    await reveal(tester, cocField, delta: 200);
    await tester.enterText(cocField, '0.0001');
    await tester.pumpAndSettle();
    final calculate = find.widgetWithText(FilledButton, 'Calculate');
    await reveal(tester, calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    final warnings = find.text('Warnings');
    await reveal(tester, warnings);
    expect(warnings, findsOneWidget);
    expect(find.textContaining('1,000-frame planning limit'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('equipment notices live inside the accessible result contract', (
    tester,
  ) async {
    await repository.createLens(savedLens());
    await tester.pumpWidget(app(const DepthOfFieldScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved lens (optional)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Standard 50').last);
    await tester.pumpAndSettle();

    expect(find.byType(AppliedEquipmentNotice), findsOneWidget);
    expect(find.textContaining('(bundled catalog)'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the solar warning appears for the Sun and not for the Moon', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();

    final menu = find.byType(DropdownMenu<CelestialTarget>);
    await reveal(tester, find.text('Search celestial targets'));
    await tester.tap(menu);
    await tester.pumpAndSettle();
    // The Sun and Moon are the last catalog entries, so the menu must scroll
    // them into view before they can be tapped.
    final moonEntry = find.textContaining('Moon ·');
    await tester.ensureVisible(moonEntry);
    await tester.pumpAndSettle();
    await tester.tap(moonEntry);
    await tester.pumpAndSettle();
    expect(find.textContaining('Solar safety:'), findsNothing);

    // The same picker now switches to the Sun and the card appears.
    await tester.ensureVisible(menu);
    await tester.pumpAndSettle();
    await tester.tap(menu);
    await tester.pumpAndSettle();
    final sunEntry = find.textContaining('Sun ·');
    await tester.ensureVisible(sunEntry);
    await tester.pumpAndSettle();
    await tester.tap(sunEntry);
    await tester.pumpAndSettle();
    expect(find.textContaining('Solar safety:'), findsOneWidget);

    // The Moon's events and the Sun's result warning are covered by
    // test/unit/features/astronomy/solar_lunar_fixture_test.dart.
    await unmount(tester);
  });

  testWidgets('the night-sky planner warns about solar safety for the Sun', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();

    final targetPicker = find.text('Search celestial targets');
    await reveal(tester, targetPicker);
    await tester.tap(targetPicker);
    await tester.pumpAndSettle();
    final sunEntry = find.textContaining('Sun ·');
    await tester.ensureVisible(sunEntry);
    await tester.pumpAndSettle();
    await tester.tap(sunEntry);
    await tester.pumpAndSettle();

    // The warning is present before the user calculates, not only afterwards.
    // Match the card sentence rather than the menu entry label.
    expect(find.textContaining('Solar safety:'), findsOneWidget);
    // The same warning reaches the result and the saved plan through the
    // calculator's structured warning, which the unit fixture test and the
    // saved-plan warning test cover.
    await unmount(tester);
  });

  testWidgets('applied cameras are recorded in night-sky and macro snapshots', (
    tester,
  ) async {
    await repository.createCamera(savedCamera());

    await tester.pumpWidget(app(const AstronomyScreen()));
    await tester.pumpAndSettle();
    final cameraPicker = find.text('Saved camera (optional)');
    await reveal(tester, cameraPicker);
    await tester.tap(cameraPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();
    final planNightSky = find.widgetWithText(FilledButton, 'Plan night sky');
    await reveal(tester, planNightSky);
    await tester.tap(planNightSky);
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Save result');
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    final astronomySnapshot = await DriftSnapshotRepository(
      database,
    ).listNewestFirst();
    final astronomyCamera = astronomySnapshot.single.equipment.single;
    expect(astronomyCamera.id, 'camera-ff');
    expect(
      astronomyCamera.type,
      // The applied input is the crop factor this camera derives.
      SnapshotEquipmentType.camera,
    );
    expect(astronomyCamera.values['cropFactor'], 1.0);
    expect(astronomyCamera.values['sensorWidthMm'], 36);
    await unmount(tester);

    await tester.pumpWidget(app(const MacroScreen()));
    await tester.pumpAndSettle();
    final macroPicker = find.text('Saved camera (optional)');
    await reveal(tester, macroPicker);
    await tester.tap(macroPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full Frame Camera').last);
    await tester.pumpAndSettle();
    final calculateMacro = find.widgetWithText(
      FilledButton,
      'Calculate macro setup',
    );
    await reveal(tester, calculateMacro);
    await tester.tap(calculateMacro);
    await tester.pumpAndSettle();
    final macroSave = find.widgetWithText(FilledButton, 'Save result');
    await reveal(tester, macroSave);
    await tester.tap(macroSave);
    await tester.pumpAndSettle();

    final macroSnapshot = await DriftSnapshotRepository(
      database,
    ).listNewestFirst();
    expect(macroSnapshot.first.equipment.map((item) => item.id), ['camera-ff']);
    expect(macroSnapshot.first.equipment.single.values['sensorWidthMm'], 36);
    await unmount(tester);
  });
}
