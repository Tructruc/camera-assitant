import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/core/data/repositories/drift_snapshot_repository.dart';
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart'
    show EquipmentProvenance, EquipmentSource, Lens;
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
  // streams while the fake clock can still drain Drift's cleanup timers.
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

  Future<void> scrollToBottom(WidgetTester tester) async {
    await tester.drag(find.byType(ListView).first, const Offset(0, -10000));
    await tester.pumpAndSettle();
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

  for (final (name, screen, action, label, value)
      in <(String, Widget, String, String, String)>[
        (
          'depth of field',
          const DepthOfFieldScreen(),
          'Calculate',
          'Focal length (mm)',
          '55',
        ),
        (
          'exposure comparison',
          const ExposureComparisonScreen(),
          'Compare exposures',
          'Baseline aperture (f-number)',
          '5.6',
        ),
        (
          'ND exposure',
          const LongExposureScreen(),
          'Calculate exposure',
          'Base shutter time (seconds)',
          '0.1',
        ),
        (
          'stacked ND filters',
          const LongExposureScreen(),
          'Calculate exposure',
          'ND filter strengths (stops)',
          '3, 7',
        ),
        (
          'flash',
          const FlashExposureScreen(),
          'Calculate flash exposure',
          'Guide number at ISO 100 (metres)',
          '50',
        ),
        (
          'timelapse',
          const TimelapseScreen(),
          'Plan timelapse',
          'Interval (seconds)',
          '12',
        ),
        (
          'macro',
          const MacroScreen(),
          'Calculate macro setup',
          'Lens focal length (mm)',
          '60',
        ),
        (
          'panorama',
          const PanoramaScreen(),
          'Plan panorama',
          'Sensor width (mm)',
          '40',
        ),
        (
          'field of view',
          const FieldOfViewScreen(),
          'Calculate',
          'Sensor width (mm)',
          '40',
        ),
        (
          'diffraction',
          const DiffractionScreen(),
          'Calculate',
          'Aperture (f-number)',
          '11',
        ),
        (
          'focus stack',
          const FocusStackScreen(),
          'Calculate',
          'Focal length (mm)',
          '110',
        ),
        (
          'night sky',
          const AstronomyScreen(),
          'Plan night sky',
          'Observer latitude (degrees)',
          '40',
        ),
        (
          'alignment',
          const AlignmentScreen(),
          'Search alignments',
          'Observer latitude (degrees)',
          '40',
        ),
      ]) {
    testWidgets('$name requires recalculation after editing inputs', (
      tester,
    ) async {
      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();
      final calculate = find.widgetWithText(FilledButton, action);
      final save = find.widgetWithText(FilledButton, 'Save result');
      await reveal(tester, calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      await reveal(tester, save);
      expect(find.byType(CalculationResultView), findsOneWidget);

      final field = find.widgetWithText(TextField, label);
      await reveal(tester, field, delta: -300);
      await tester.enterText(field, value);
      await tester.pumpAndSettle();
      await scrollToBottom(tester);
      expect(save, findsNothing);
      expect(find.byType(CalculationResultView), findsNothing);
      expect(
        await DriftSnapshotRepository(database).listNewestFirst(),
        isEmpty,
      );

      await reveal(tester, calculate, delta: -300);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      await reveal(tester, save);
      expect(find.byType(CalculationResultView), findsOneWidget);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(
        await DriftSnapshotRepository(database).listNewestFirst(),
        hasLength(1),
      );

      await unmount(tester);
    });
  }

  testWidgets('cursor-only edits keep the displayed and savable result', (
    tester,
  ) async {
    await tester.pumpWidget(app(const DepthOfFieldScreen()));
    await tester.pumpAndSettle();
    final calculate = find.widgetWithText(FilledButton, 'Calculate');
    await reveal(tester, calculate);
    await tester.tap(calculate);
    await tester.pumpAndSettle();
    await reveal(tester, find.widgetWithText(FilledButton, 'Save result'));
    expect(find.byType(CalculationResultView), findsOneWidget);

    final focalField = find.widgetWithText(TextField, 'Focal length (mm)');
    await reveal(tester, focalField, delta: -300);
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
    expect(find.widgetWithText(FilledButton, 'Save result'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets(
    'unchanged numeric inputs still invalidate when equipment provenance changes',
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

      final calculate = find.widgetWithText(FilledButton, 'Calculate');
      await reveal(tester, calculate);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(FilledButton, 'Save result'));
      expect(find.byType(CalculationResultView), findsOneWidget);

      // Swapping to an optically identical lens leaves every numeric input
      // byte-for-byte the same, so only the provenance change can invalidate.
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
      await scrollToBottom(tester);
      expect(find.byType(CalculationResultView), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Save result'), findsNothing);
      expect(
        await DriftSnapshotRepository(database).listNewestFirst(),
        isEmpty,
      );

      await reveal(tester, calculate, delta: -300);
      await tester.tap(calculate);
      await tester.pumpAndSettle();
      await reveal(tester, find.widgetWithText(FilledButton, 'Save result'));
      await tester.tap(find.widgetWithText(FilledButton, 'Save result'));
      await tester.pumpAndSettle();
      final saved = await DriftSnapshotRepository(database).listNewestFirst();
      expect(saved, hasLength(1));
      expect(saved.single.equipment.map((item) => item.id), ['lens-b']);
      expect(saved.single.equipment.single.values['focalLengthMm'], 85);

      await unmount(tester);
    },
  );
}
