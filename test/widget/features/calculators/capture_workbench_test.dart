import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, CalculationSnapshot, NdFilter, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    show CameraBody, EquipmentProvenance, EquipmentSource, NdFilter;
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart'
    show CameraOrientation;
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

/// Capture-family workbench contract.
///
/// These tests pin the interaction the redesign introduces for the five
/// capture tools: the answer is on screen as soon as the screen opens, every
/// cheap edit - typing, a chip, a slider, an orientation - recalculates it
/// without a compute button, the controls speak the camera's own values
/// (f-stops, ISO, shutter fractions, ND stops, flash fractions), an empty kit
/// never displaces manual entry, and the canonical raw units and the snapshot
/// schema are unchanged.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen, {double textScale = 1}) => ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(
        DriftEquipmentRepository(database),
      ),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: screen),
      ),
    ),
  );

  /// Unmounting before the test ends lets Riverpod dispose the local database
  /// streams and the page cancel its own live-calculation timer.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  /// Brings [finder] on screen, whichever way it lies.
  ///
  /// A lazy list only builds what it can show, so a target below the fold is
  /// not in the tree yet: start from the top and search downwards, then let
  /// `ensureVisible` finish the job when it is already built but scrolled past.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
    }
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    // `.first` only here: it keeps the reveal tolerant of a finder that
    // legitimately matches more than one widget (a total echoed by the tile
    // that contributes it, for instance).
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
  }

  /// Asserts [finder] is on screen - and that it could be reached at all.
  Future<void> expectVisible(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    expect(finder, findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await reveal(tester, finder);
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  /// The canonical text of a field - the value the calculator parses.
  Future<String> fieldText(WidgetTester tester, String label) async {
    final field = find.widgetWithText(TextField, label);
    await reveal(tester, field);
    return tester.widget<TextField>(field).controller!.text;
  }

  Future<void> saveResult(WidgetTester tester) async {
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Save result'));
  }

  group('exposure comparison', () {
    testWidgets('opens on a live answer with both sides readable', (
      tester,
    ) async {
      await tester.pumpWidget(app(const ExposureComparisonScreen()));
      await tester.pumpAndSettle();

      // Two identical defaults read as equivalent before anything is touched.
      await expectVisible(tester, find.text('Equivalent exposure'));
      await expectVisible(
        tester,
        find.textContaining('A f/4 · 1/125 s · ISO 100'),
      );
      await expectVisible(
        tester,
        find.textContaining('B f/4 · 1/125 s · ISO 100'),
      );

      // The candidate triple is visible, not collapsed behind an expander, so
      // the two sides can be read together.
      await expectVisible(tester, find.text('Candidate (B)'));
      await expectVisible(
        tester,
        find.widgetWithText(TextField, 'Candidate shutter (seconds)'),
      );

      // A cheap live tool has no repeated compute button; the live signal
      // replaces it.
      expect(
        find.widgetWithText(FilledButton, 'Compare exposures'),
        findsNothing,
      );
      await expectVisible(tester, find.text('Updates as you adjust'));
      await unmount(tester);
    });

    testWidgets('a shutter chip changes the answer without a button press', (
      tester,
    ) async {
      await tester.pumpWidget(app(const ExposureComparisonScreen()));
      await tester.pumpAndSettle();

      // One stop of shutter on the candidate side: full stops are one tap.
      const chip = 'Set Candidate shutter (seconds) to 1/250 s';
      await tapVisible(tester, find.byTooltip(chip));

      expect(await fieldText(tester, 'Candidate shutter (seconds)'), '0.004');
      // The chosen dial position is marked in the row it was tapped in.
      expect(
        tester
            .widget<ChoiceChip>(
              find.descendant(
                of: find.byTooltip(chip),
                matching: find.byType(ChoiceChip),
              ),
            )
            .selected,
        isTrue,
      );
      await expectVisible(tester, find.text('Candidate is darker'));
      // The total is echoed by the shutter tile that contributes all of it.
      expect(find.text('-1.0 stops'), findsWidgets);
      await expectVisible(tester, find.text('-1.0 stops').first);
      await unmount(tester);
    });

    testWidgets('Use A for B returns the comparison to equivalent', (
      tester,
    ) async {
      await tester.pumpWidget(app(const ExposureComparisonScreen()));
      await tester.pumpAndSettle();

      await tapVisible(
        tester,
        find.byTooltip('Set Candidate aperture (f-number) to 2.8'),
      );
      await expectVisible(tester, find.text('Candidate is brighter'));
      // The total is echoed by the aperture tile that contributes all of it.
      expect(find.text('+1.0 stops'), findsWidgets);
      await expectVisible(tester, find.text('+1.0 stops').first);

      await tapVisible(tester, find.text('Use A for B'));
      await expectVisible(tester, find.text('Equivalent exposure'));
      expect(await fieldText(tester, 'Candidate aperture (f-number)'), '4');
      await unmount(tester);
    });
  });

  group('long exposure', () {
    testWidgets('opens on familiar shutter values with stop controls', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();

      // 1/30 s at 10 stops of ND is 34.1 s.
      await expectVisible(tester, find.text('Filtered exposure time'));
      await expectVisible(tester, find.text('34.1 s'));
      await expectVisible(tester, find.text('From 1/30 s at 10 stops of ND.'));
      expect(
        find.widgetWithText(FilledButton, 'Calculate exposure'),
        findsNothing,
      );
      await expectVisible(tester, find.text('Updates as you adjust'));
      // Familiar shutter and ND wording is on screen, not only in the result.
      await expectVisible(
        tester,
        find.byTooltip('Set the base shutter to 1/15 s'),
      );
      await expectVisible(tester, find.byTooltip('Add 3 stops of ND'));
      await unmount(tester);
    });

    testWidgets('one-stop buttons walk the dial values', (tester) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();

      // One stop faster halves the time: 1/30 s becomes 1/60 s.
      await tapVisible(tester, find.text('-1 stop'));
      expect(await fieldText(tester, 'Base shutter time (seconds)'), '1/60');
      await expectVisible(tester, find.text('17.1 s'));

      // And back the other way, still on the dial's own values.
      await tapVisible(tester, find.text('+1 stop'));
      expect(await fieldText(tester, 'Base shutter time (seconds)'), '1/30');
      await expectVisible(tester, find.text('34.1 s'));
      await unmount(tester);
    });

    testWidgets('ND chips toggle the stack and the result follows', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byTooltip('Add 3 stops of ND'));
      expect(await fieldText(tester, 'ND filter strengths (stops)'), '10, 3');
      // 1/30 s at 13 stops of ND is a little over four and a half minutes.
      await expectVisible(tester, find.text('4 min 33 s'));

      // The same chip removes its stops again, so the stack is usable without
      // the keyboard in both directions.
      await tapVisible(tester, find.byTooltip('Remove 3 stops of ND'));
      expect(await fieldText(tester, 'ND filter strengths (stops)'), '10');
      await expectVisible(tester, find.text('34.1 s'));
      await unmount(tester);
    });

    testWidgets(
      'an empty kit shows no picker; a saved filter fills the stack',
      (tester) async {
        await tester.pumpWidget(app(const LongExposureScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Saved ND filter (optional)'), findsNothing);

        final now = DateTime.utc(2026, 10, 1);
        await DriftEquipmentRepository(database).createFilter(
          NdFilter(
            id: 'filter-ten',
            name: '10-stop ND',
            strengthStops: 10,
            provenance: const EquipmentProvenance(source: EquipmentSource.user),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await tester.pumpWidget(app(const LongExposureScreen()));
        await tester.pumpAndSettle();
        expect(find.text('Saved ND filter (optional)'), findsOneWidget);

        await tester.tap(find.text('Saved ND filter (optional)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('10-stop ND').last);
        await tester.pumpAndSettle();

        expect(await fieldText(tester, 'ND filter strengths (stops)'), '10.0');
        await expectVisible(tester, find.textContaining('10.0 stops applied'));
        await unmount(tester);
      },
    );

    testWidgets('saves canonical seconds and the raw stop stack', (
      tester,
    ) async {
      await tester.pumpWidget(app(const LongExposureScreen()));
      await tester.pumpAndSettle();
      await tapVisible(
        tester,
        find.byTooltip('Set the base shutter to 1/15 s'),
      );
      await saveResult(tester);

      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(snapshot.calculatorId, 'long_exposure_nd');
      final inputs = snapshot.canonicalInputs;
      expect(inputs['baseTimeSeconds'] as double, closeTo(1 / 15, 1e-12));
      expect(inputs['filterStops'], <double>[10]);
      expect(
        snapshot.canonicalOutputs['filteredTimeSeconds'] as double,
        closeTo(1 / 15 * 1024, 1e-9),
      );
      await unmount(tester);
    });
  });

  group('flash', () {
    testWidgets('power chips offer the dial from 1/1 to 1/128', (tester) async {
      await tester.pumpWidget(app(const FlashExposureScreen()));
      await tester.pumpAndSettle();

      await expectVisible(
        tester,
        find.byTooltip('Set the flash to 1/128 power'),
      );
      for (final label in <String>[
        '1/1',
        '1/2',
        '1/4',
        '1/8',
        '1/16',
        '1/32',
        '1/64',
        '1/128',
      ]) {
        expect(
          find.widgetWithText(ChoiceChip, label),
          findsOneWidget,
          reason: '$label power is missing from the power row',
        );
      }

      // Full power at guide number 40 m and 5 m is f/8; half power is f/5.7.
      await expectVisible(tester, find.text('f/8'));
      await tapVisible(tester, find.byTooltip('Set the flash to 1/2 power'));
      await expectVisible(tester, find.text('f/5.7'));
      await expectVisible(tester, find.textContaining('half power'));

      // 1/128 power is named the way the dial reads it.
      await tapVisible(tester, find.byTooltip('Set the flash to 1/128 power'));
      await expectVisible(tester, find.text('f/0.7'));
      await expectVisible(tester, find.textContaining('1/128 power'));
      await unmount(tester);
    });
  });

  group('timelapse', () {
    testWidgets('interval presets are camera cadences', (tester) async {
      await tester.pumpWidget(app(const TimelapseScreen()));
      await tester.pumpAndSettle();

      // 10 s over an hour is 361 frames.
      await expectVisible(tester, find.text('361'));
      expect(find.widgetWithText(FilledButton, 'Plan timelapse'), findsNothing);
      await expectVisible(tester, find.text('Updates as you adjust'));

      await tapVisible(tester, find.byTooltip('Set Interval (seconds) to 30'));
      expect(await fieldText(tester, 'Interval (seconds)'), '30');
      await expectVisible(tester, find.text('121'));
      await unmount(tester);
    });

    testWidgets('capture duration is entered in minutes, stored in seconds', (
      tester,
    ) async {
      await tester.pumpWidget(app(const TimelapseScreen()));
      await tester.pumpAndSettle();

      // The default hour is shown the way a photographer plans it.
      expect(await fieldText(tester, 'Capture duration'), '60');

      await tapVisible(
        tester,
        find.byTooltip('Set Capture duration to 30 min'),
      );
      expect(await fieldText(tester, 'Capture duration'), '30');
      await expectVisible(tester, find.text('181'));

      // The canonical snapshot value stays in seconds.
      await saveResult(tester);
      final snapshot = (await DriftSnapshotRepository(
        database,
      ).listNewestFirst()).single;
      expect(snapshot.calculatorId, 'timelapse');
      expect(
        snapshot.canonicalInputs['captureDurationSeconds'] as double,
        closeTo(1800, 1e-9),
      );
      expect(snapshot.canonicalInputs['intervalSeconds'] as double, 10);
      await unmount(tester);
    });

    testWidgets('storage and ramp assumptions stay one disclosure down', (
      tester,
    ) async {
      await tester.pumpWidget(app(const TimelapseScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Capture duration'), findsOneWidget);
      expect(find.text('Estimated size per frame (MB)'), findsNothing);

      await tapVisible(tester, find.text('More settings'));
      await expectVisible(tester, find.text('Estimated size per frame (MB)'));
      await expectVisible(tester, find.text('Starting exposure (seconds)'));
      await unmount(tester);
    });
  });

  group('panorama', () {
    testWidgets('orientation is a chip row, not a dropdown', (tester) async {
      await tester.pumpWidget(app(const PanoramaScreen()));
      await tester.pumpAndSettle();

      expect(
        find.byType(DropdownButtonFormField<CameraOrientation>),
        findsNothing,
      );
      await expectVisible(tester, find.widgetWithText(ChoiceChip, 'Landscape'));
      await expectVisible(tester, find.widgetWithText(ChoiceChip, 'Portrait'));
      expect(find.widgetWithText(FilledButton, 'Plan panorama'), findsNothing);
      await expectVisible(tester, find.text('Updates as you adjust'));

      // The default 50 mm landscape sweep is 3 columns × 2 rows.
      await expectVisible(tester, find.textContaining('3 columns × 2 rows'));

      await tapVisible(tester, find.widgetWithText(ChoiceChip, 'Portrait'));
      await expectVisible(tester, find.textContaining('5 columns × 2 rows'));
      await unmount(tester);
    });

    testWidgets('an overlap chip rebuilds the grid and its coverage', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PanoramaScreen()));
      await tester.pumpAndSettle();

      // Overlap is a bounded continuous input, so it carries a slider too.
      expect(find.byType(Slider), findsWidgets);

      await tapVisible(
        tester,
        find.byTooltip('Set Horizontal overlap (%) to 70'),
      );
      expect(await fieldText(tester, 'Horizontal overlap (%)'), '70');
      // Doubling the columns is the rebuild the chip has to drive; the vertical
      // overlap is untouched, so the row count stays at two.
      await expectVisible(tester, find.textContaining('6 columns × 2 rows'));
      // The grid and its coverage are summarised, not just the frame count.
      await expectVisible(tester, find.text('Coverage'));
      await expectVisible(tester, find.text('Column step'));
      await expectVisible(tester, find.text('Row step'));
      await unmount(tester);
    });

    testWidgets('an empty kit shows no picker; a saved camera fills it', (
      tester,
    ) async {
      await tester.pumpWidget(app(const PanoramaScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Saved lens (optional)'), findsNothing);
      expect(find.text('Saved camera (optional)'), findsNothing);

      final now = DateTime.utc(2026, 10, 1);
      await DriftEquipmentRepository(database).createCamera(
        CameraBody(
          id: 'camera-ff',
          name: 'Full Frame Camera',
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          provenance: const EquipmentProvenance(source: EquipmentSource.user),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpWidget(app(const PanoramaScreen()));
      await tester.pumpAndSettle();

      await tapVisible(tester, find.text('More settings'));
      await expectVisible(tester, find.text('Saved camera (optional)'));
      await tester.tap(find.text('Saved camera (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full Frame Camera').last);
      await tester.pumpAndSettle();

      await expectVisible(
        tester,
        find.textContaining('From Full Frame Camera'),
      );
      // The page is a lazy list, and scrolling back up to the picker disposed
      // the disclosure: it is opened again before reading the sensor field.
      await reveal(tester, find.text('More settings'));
      if (find
          .widgetWithText(TextField, 'Sensor width (mm)')
          .evaluate()
          .isEmpty) {
        await tester.tap(find.text('More settings'));
        await tester.pumpAndSettle();
      }
      expect(await fieldText(tester, 'Sensor width (mm)'), '36.0');
      // The answer is the one for the sensor now in the fields.
      await expectVisible(tester, find.byType(CalculationResultView));
      await unmount(tester);
    });
  });

  // Narrow phones and 200 percent text are where a chip row or a six-tile
  // result overflows. Every capture screen has to stay scrollable and keep its
  // answer and actions reachable.
  for (final (name, screen) in <(String, Widget)>[
    ('exposure comparison', const ExposureComparisonScreen()),
    ('long exposure', const LongExposureScreen()),
    ('flash exposure', const FlashExposureScreen()),
    ('timelapse planner', const TimelapseScreen()),
    ('panorama planner', const PanoramaScreen()),
  ]) {
    testWidgets('$name stays usable on a 320 wide phone at 200% text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(screen, textScale: 2));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);

      // The live signal, the answer and its save action are all reachable.
      await expectVisible(tester, find.text('Updates as you adjust'));
      await expectVisible(tester, find.byType(CalculationResultView));
      await expectVisible(
        tester,
        find.widgetWithText(FilledButton, 'Save result'),
      );
      expect(tester.takeException(), isNull);

      await unmount(tester);
    });
  }
}
