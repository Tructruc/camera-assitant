import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide
        CalculationSnapshot,
        CameraBody,
        NdFilter,
        OpticalAccessory,
        SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/domain/calculation_snapshot.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    show
        CameraBody,
        EquipmentProvenance,
        EquipmentSource,
        Lens,
        NdFilter,
        OpticalAccessory,
        OpticalAccessoryKind;
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

  // Unmounting before the test ends lets Riverpod dispose the local database
  // streams while the fake clock can still drain Drift's cleanup timers, and it
  // cancels the live-calculation timer a cheap calculator scheduled.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  /// Reveals [finder] wherever it sits in the screen.
  ///
  /// A target can be either side of the current position - a result card is
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

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, -10000));
    await tester.pumpAndSettle();
  }

  Finder equipmentPicker(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate(
      (widget) => widget is DropdownButtonFormField,
    ),
  );

  Finder saveButton() => find.widgetWithText(FilledButton, 'Save result');

  /// Saves the result that is currently on screen and returns the single stored
  /// snapshot, so a test can assert the canonical payload the user just saved.
  Future<CalculationSnapshot> saveAndRead(WidgetTester tester) async {
    final save = saveButton();
    await reveal(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    final snapshots = await DriftSnapshotRepository(database).listNewestFirst();
    expect(snapshots, hasLength(1), reason: 'exactly one result was expected');
    return snapshots.single;
  }

  /// Reads a nested canonical input by key path.
  Object? canonicalAt(CalculationSnapshot snapshot, List<String> path) {
    Object? current = snapshot.canonicalInputs;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  /// Opens the collapsed input groups so a moved control can be reached.
  ///
  /// The redesign hides conventions behind "More settings". Nothing was
  /// removed, so reaching the control through the expander is part of the
  /// contract these tests verify: a section that cannot be opened fails here.
  Future<void> expandSections(WidgetTester tester) async {
    for (final title in const <String>['More settings']) {
      var header = find.text(title);
      for (
        var attempt = 0;
        attempt < 10 && header.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pumpAndSettle();
        header = find.text(title);
      }
      if (header.evaluate().isEmpty) continue;
      final tile = find.ancestor(
        of: header,
        matching: find.byType(ExpansionTile),
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }
  }

  Lens savedLens(String id, String name) {
    final now = DateTime.utc(2026, 9, 10);
    return Lens(
      id: id,
      name: name,
      minimumFocalLengthMm: 85,
      maximumFocalLengthMm: 85,
      minimumAperture: 1.8,
      provenance: const EquipmentProvenance(source: EquipmentSource.user),
      createdAt: now,
      updatedAt: now,
    );
  }

  // The cheap calculators seed their answer and keep it live: there is no
  // Calculate action left to press, so a changed input must produce the answer
  // for the *new* value in the same result card, and that is what gets saved.
  // "The card disappears until you recalculate" would now be a defect - a stale
  // answer is what the live contract forbids, not an updated one.
  for (final (name, screen, fieldLabel, value, path, expected)
      in <(String, Widget, String, String, List<String>, Object?)>[
        (
          'depth of field',
          const DepthOfFieldScreen(),
          'Focal length (mm)',
          '55',
          ['focalLengthMm'],
          55.0,
        ),
        (
          'exposure comparison',
          const ExposureComparisonScreen(),
          'Baseline aperture (f-number)',
          '5.6',
          ['baseline', 'aperture'],
          5.6,
        ),
        (
          'ND exposure',
          const LongExposureScreen(),
          'Base shutter time (seconds)',
          '0.1',
          ['baseTimeSeconds'],
          0.1,
        ),
        (
          'stacked ND filters',
          const LongExposureScreen(),
          'ND filter strengths (stops)',
          '3, 7',
          ['filterStops'],
          <double>[3, 7],
        ),
        (
          'flash',
          const FlashExposureScreen(),
          'Guide number at ISO 100 (metres)',
          '50',
          ['guideNumberIso100Metres'],
          50.0,
        ),
        (
          'timelapse',
          const TimelapseScreen(),
          'Interval (seconds)',
          '12',
          ['intervalSeconds'],
          12.0,
        ),
        (
          'macro',
          const MacroScreen(),
          'Lens focal length (mm)',
          '60',
          ['focalLengthMm'],
          60.0,
        ),
        (
          'panorama',
          const PanoramaScreen(),
          'Sensor width (mm)',
          '40',
          ['sensorWidthMm'],
          40.0,
        ),
        (
          'field of view',
          const FieldOfViewScreen(),
          'Sensor width (mm)',
          '40',
          ['sensorWidthMm'],
          40.0,
        ),
        (
          'diffraction',
          const DiffractionScreen(),
          'Aperture (f-number)',
          '11',
          ['aperture'],
          11.0,
        ),
        (
          'focus stack',
          const FocusStackScreen(),
          'Focal length (mm)',
          '110',
          ['focalLengthMm'],
          110.0,
        ),
      ]) {
    testWidgets('$name answers and saves the edited input', (tester) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();

      // A live answer is already on screen before anything is touched.
      await reveal(tester, find.byType(CalculationResultView));
      expect(find.byType(CalculationResultView), findsOneWidget);

      // The advanced group is opened only after the result card has been
      // reached: walking back up the list would dispose the expanded tile, and
      // an input inside it has to stay built to be edited.
      await expandSections(tester);
      final field = find.widgetWithText(TextField, fieldLabel);
      await reveal(tester, field);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();

      // The answer was updated, not discarded: it still describes the inputs
      // and it is still savable.
      await reveal(tester, saveButton());
      expect(
        find.byType(CalculationResultView),
        findsOneWidget,
        reason: '$name discarded a live answer instead of updating it',
      );

      final snapshot = await saveAndRead(tester);
      expect(
        canonicalAt(snapshot, path),
        expected,
        reason: '$name saved a stale canonical value',
      );

      await unmount(tester);
    });
  }

  // The heavy planners are the opposite contract: their search is explicit, so
  // an edited input must withdraw the answer and say why, and nothing may be
  // saved until the search runs again. Each planner also names its canonical
  // inputs in its own vocabulary - the night-sky plan stores `latitudeDegrees`,
  // the alignment search `observerLatitudeDegrees` - so the key the searched
  // latitude is saved under is part of the case, not a name shared by both.
  for (final (name, screen, action, label, value, savedKey)
      in <(String, Widget, String, String, String, String)>[
        (
          'night sky',
          const AstronomyScreen(),
          'Plan night sky',
          'Observer latitude (degrees)',
          '40',
          'latitudeDegrees',
        ),
        (
          'alignment',
          const AlignmentScreen(),
          'Find alignment',
          'Observer latitude (degrees)',
          '40',
          'observerLatitudeDegrees',
        ),
      ]) {
    testWidgets('$name requires the explicit search after editing inputs', (
      tester,
    ) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      await expandSections(tester);
      final calculate = find.widgetWithText(FilledButton, action);
      await reveal(tester, calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      await reveal(tester, saveButton());
      expect(find.byType(CalculationResultView), findsOneWidget);

      final field = find.widgetWithText(TextField, label);
      await reveal(tester, field);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();

      // The result is withdrawn - an expensive search that has not run again
      // cannot be trusted - and the screen says so rather than showing a blank.
      // The notice sits above the result area, so it is scrolled to: a message
      // that is not built is not a message the screen is giving.
      expect(find.byType(CalculationResultView), findsNothing);
      final stale = find.textContaining('Inputs changed since the last');
      await reveal(tester, stale);
      expect(stale, findsOneWidget);
      expect(saveButton(), findsNothing);
      expect(
        await DriftSnapshotRepository(database).listNewestFirst(),
        isEmpty,
      );

      await reveal(tester, calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      final snapshot = await saveAndRead(tester);
      // The searched latitude is what was saved, under the name that screen
      // uses for it: asserting presence on one shared key would not prove the
      // edit was stored, and would fail on the vocabulary the other planner
      // never claimed to use.
      expect(
        snapshot.canonicalInputs,
        containsPair(savedKey, 40.0),
        reason: '$name did not save the edited observer latitude',
      );

      await unmount(tester);
    });
  }

  testWidgets('cursor-only edits keep the displayed and savable result', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DepthOfFieldScreen()));
    await tester.pumpAndSettle();
    // The answer is live from the first frame; no action produces it.
    await reveal(tester, find.byType(CalculationResultView));
    expect(find.byType(CalculationResultView), findsOneWidget);

    final focalField = find.widgetWithText(TextField, 'Focal length (mm)');
    await reveal(tester, focalField);
    final controller = tester.widget<TextField>(focalField).controller!;
    final before = controller.text;
    // Moving the caret, extending the selection, and changing the composing
    // region must not be treated as an input change.
    controller.selection = TextSelection.collapsed(offset: 0);
    await tester.pumpAndSettle();
    controller.selection = TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.pumpAndSettle();
    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pumpAndSettle();

    expect(controller.text, before);
    expect(find.byType(CalculationResultView), findsOneWidget);
    await scrollToBottom(tester);
    expect(saveButton(), findsOneWidget);

    await unmount(tester);
  });

  testWidgets(
    'a swapped lens updates the live answer and the saved provenance',
    (tester) async {
      final repository = DriftEquipmentRepository(database);
      await repository.createLens(savedLens('lens-a', 'Saved 85 A'));
      await repository.createLens(savedLens('lens-b', 'Saved 85 B'));

      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved lens (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved 85 A').last);
      await tester.pumpAndSettle();

      final focalField = find.widgetWithText(TextField, 'Focal length (mm)');
      final apertureField = find.widgetWithText(
        TextField,
        'Aperture (f-number)',
      );
      final focal = tester.widget<TextField>(focalField).controller!;
      final aperture = tester.widget<TextField>(apertureField).controller!;
      expect(focal.text, '85.0');
      expect(aperture.text, '1.8');

      await reveal(tester, find.byType(CalculationResultView));
      expect(find.byType(CalculationResultView), findsOneWidget);

      // Swapping to an optically identical lens leaves every numeric input
      // byte-for-byte the same, so only the provenance change can move the
      // answer; the result stays savable and must record the new item.
      await tester.scrollUntilVisible(
        find.text('Saved lens (optional)'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final lensPicker = find.byType(DropdownButtonFormField<Lens>);
      await tester.ensureVisible(lensPicker);
      await tester.pumpAndSettle();
      await tester.tap(lensPicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved 85 B').last);
      await tester.pumpAndSettle();

      expect(focal.text, '85.0');
      expect(aperture.text, '1.8');
      expect(find.textContaining('From Saved 85 B'), findsOneWidget);
      expect(find.textContaining('From Saved 85 A'), findsNothing);
      // The live result still describes the current inputs, so it stays savable
      // and records the provenance that produced it.
      await reveal(tester, saveButton());
      expect(find.byType(CalculationResultView), findsOneWidget);
      final saved = await saveAndRead(tester);
      expect(saved.equipment.map((item) => item.id), ['lens-b']);
      expect(saved.equipment.single.values['focalLengthMm'], 85);

      await unmount(tester);
    },
  );

  // T150: the provenance-only invalidation rule must hold for every equipment
  // kind, not just the depth-of-field lens case.
  for (final (name, screen, pickerLabel, firstName, secondName)
      in <(String, Widget, String, String, String)>[
        (
          'field of view camera',
          const FieldOfViewScreen(),
          'Saved camera (optional)',
          'Camera A',
          'Camera B',
        ),
        (
          'macro extension tube',
          const MacroScreen(),
          'Saved extension tube (optional)',
          'Tube A',
          'Tube B',
        ),
        (
          'ND filter',
          const LongExposureScreen(),
          'Saved ND filter (optional)',
          'Filter A',
          'Filter B',
        ),
      ]) {
    testWidgets('swapping an identical $name updates and saves its provenance', (
      tester,
    ) async {
      final repository = DriftEquipmentRepository(database);
      final now = DateTime.utc(2026, 9, 10);
      final provenance = EquipmentProvenance(
        source: EquipmentSource.user,
        note: now.toIso8601String(),
      );
      await repository.createCamera(
        CameraBody(
          id: 'camera-a',
          name: 'Camera A',
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.createCamera(
        CameraBody(
          id: 'camera-b',
          name: 'Camera B',
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.createAccessory(
        OpticalAccessory(
          id: 'tube-a',
          name: 'Tube A',
          kind: OpticalAccessoryKind.extensionTube,
          value: 25,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.createAccessory(
        OpticalAccessory(
          id: 'tube-b',
          name: 'Tube B',
          kind: OpticalAccessoryKind.extensionTube,
          value: 25,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.createFilter(
        NdFilter(
          id: 'filter-a',
          name: 'Filter A',
          strengthStops: 10,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await repository.createFilter(
        NdFilter(
          id: 'filter-b',
          name: 'Filter B',
          strengthStops: 10,
          provenance: provenance,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      await expandSections(tester);
      final picker = equipmentPicker(pickerLabel);
      await reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text(firstName).last);
      await tester.pumpAndSettle();

      // These three are cheap live calculators: the answer updates as the
      // equipment is applied, with no explicit action to press.
      await reveal(tester, find.byType(CalculationResultView));
      expect(find.byType(CalculationResultView), findsOneWidget);

      await reveal(tester, picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text(secondName).last);
      await tester.pumpAndSettle();

      // The notice follows the applied item, and the live answer stays savable
      // with the new provenance rather than describing the previous one.
      expect(find.textContaining('From $secondName'), findsWidgets);
      await reveal(tester, saveButton());
      expect(find.byType(CalculationResultView), findsOneWidget);
      final saved = await saveAndRead(tester);
      expect(saved.equipment.map((item) => item.id), hasLength(1));
      expect(
        saved.equipment.single.id,
        endsWith('-b'),
        reason: '$name saved the previous item\'s provenance',
      );

      await unmount(tester);
    });
  }
}
