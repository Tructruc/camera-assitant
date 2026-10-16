import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, CalculationSnapshot, SavedLocation;
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';

/// Focus-family workbench contract.
///
/// These tests pin the interaction the redesign introduces: the answer is on
/// screen as soon as the screen opens, every cheap edit recalculates it, the
/// shot-defining controls lead and the conventions sit behind one disclosure,
/// distances are entered in metres with a raw-millimetre adapter beside them,
/// and an empty equipment kit never displaces manual entry.
void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    key: UniqueKey(),
    overrides: <Override>[
      appDatabaseProvider.overrideWithValue(database),
      equipmentRepositoryProvider.overrideWithValue(
        DriftEquipmentRepository(database),
      ),
    ],
    child: MaterialApp(home: Scaffold(body: screen)),
  );

  /// The plain text of every [Text] in the tree, including rich spans.
  ///
  /// Result values render as rich spans (number + quiet unit), so matching on
  /// `Text.data` alone would miss them.
  List<String?> renderedText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText())
      .toList();

  Matcher hasRenderedText(Pattern pattern) => contains(matches(pattern));

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

  /// Reveals the full result card before anything it carries is asserted.
  ///
  /// The card sits below the inputs it describes, so on the test viewport the
  /// page's lazy list has not built it yet: a card that is not built holds no
  /// text, and finding none of it says nothing about what the screen shows.
  Future<void> revealResult(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.byType(CalculationResultView),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  /// A screen that watches the equipment stream keeps a zero-duration timer
  /// pending when the last subscription is cancelled, so the tree is unmounted
  /// (and the timer flushed) before the test ends.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> saveLens(AppDatabase database, {String id = 'lens-a'}) async {
    final now = DateTime.utc(2026, 10, 1);
    await DriftEquipmentRepository(database).createLens(
      Lens(
        id: id,
        name: 'Saved 85 mm',
        minimumFocalLengthMm: 85,
        maximumFocalLengthMm: 85,
        minimumAperture: 1.8,
        provenance: const EquipmentProvenance(source: EquipmentSource.user),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  group('depth of field', () {
    testWidgets('opens with a live answer and no Calculate button', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      // The default shot is already answered: 50 mm at f/8 focused on 10 m
      // has a 10.47 m hyperfocal distance under the 0.03 mm convention.
      expect(find.byType(CalculationResultView), findsOneWidget);
      expect(find.text('Hyperfocal distance'), findsOneWidget);
      expect(renderedText(tester), hasRenderedText('10.47 m'));

      // A cheap live tool has no repeated compute button; the live signal
      // replaces it.
      expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);
      expect(find.text('Updates as you adjust'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('editing aperture recalculates without a button press', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      expect(renderedText(tester), hasRenderedText('10.47 m'));

      await tester.enterText(
        find.widgetWithText(TextField, 'Aperture (f-number)'),
        '16',
      );
      await tester.pumpAndSettle();

      // Stopping down moves the hyperfocal distance to 5.26 m; the answer
      // follows the input with no explicit action.
      expect(renderedText(tester), hasRenderedText('5.26 m'));
      expect(renderedText(tester), isNot(hasRenderedText('10.47 m')));

      await unmount(tester);
    });

    testWidgets('focus distance is entered in metres and adapts to raw mm', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      final metres = find.widgetWithText(TextField, 'Focus distance (m)');
      expect(metres, findsOneWidget);
      // The metre field is a display of the canonical millimetres: it shows 10,
      // and the exact raw value behind it stays 10000. Its controller is kept
      // here because scrolling to the expander can take the field off screen.
      final metreController = tester.widget<TextField>(metres).controller!;
      expect(metreController.text, '10');

      // The raw adapter lives with the other conventions, and edits the very
      // same controller so nothing is duplicated or lost.
      await openExpander(tester, 'More settings');
      final adapter = find.widgetWithText(
        TextField,
        FocusDistanceAdapterField.label,
      );
      expect(adapter, findsOneWidget);
      expect(tester.widget<TextField>(adapter).controller!.text, '10000');
      expect(
        find.text('Stored in millimetres; the metre display is rounded.'),
        findsOneWidget,
      );

      // Typing the canonical millimetres moves the metre display with them.
      await tester.enterText(adapter, '2500');
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(adapter).controller!.text, '2500');
      expect(metreController.text, '2.5');

      await unmount(tester);
    });

    testWidgets('the sensor convention stays behind one disclosure', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Circle of confusion (mm)'), findsNothing);
      await openExpander(tester, 'More settings');
      expect(find.text('Circle of confusion (mm)'), findsOneWidget);
      expect(
        find.textContaining('0.03 mm is the 35 mm sharpness convention'),
        findsOneWidget,
      );

      await unmount(tester);
    });

    testWidgets('invalid input withdraws the answer instead of showing it', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(CalculationResultView), findsOneWidget);

      await tester.enterText(find.byKey(const Key('dof-focal')), '0');
      await tester.pumpAndSettle();

      expect(find.byType(CalculationResultView), findsNothing);
      expect(find.text('Enter a positive finite value.'), findsWidgets);

      await unmount(tester);
    });

    testWidgets('an empty kit shows no picker; a saved lens does', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Saved lens (optional)'), findsNothing);
      expect(find.text('Saved camera (optional)'), findsNothing);

      await saveLens(database);
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Saved lens (optional)'), findsOneWidget);

      await tester.tap(find.text('Saved lens (optional)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Saved 85 mm').last);
      await tester.pumpAndSettle();

      // Applying a saved lens is an input change: the shown answer must be the
      // one for the lens that is now selected.
      expect(find.textContaining('From Saved 85 mm'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('dof-focal')))
            .controller!
            .text,
        '85.0',
      );
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Aperture (f-number)'),
            )
            .controller!
            .text,
        '1.8',
      );
      // The applied-equipment notice above the inputs pushes the answer below
      // the fold on the test viewport, so it is scrolled back into view.
      await tester.scrollUntilVisible(
        find.byType(CalculationResultView),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byType(CalculationResultView), findsOneWidget);

      await unmount(tester);
    });
  });

  group('macro', () {
    testWidgets('configuration modes are visible segments, not a dropdown', (
      tester,
    ) async {
      await tester.pumpWidget(app(const MacroScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<MacroConfiguration>), findsOneWidget);
      expect(find.text('Extension tube'), findsWidgets);
      expect(find.text('Reversed lens'), findsOneWidget);
      expect(find.text('Coupled lenses'), findsOneWidget);
      expect(
        find.byType(DropdownButtonFormField<MacroConfiguration>),
        findsNothing,
      );
      expect(
        find.widgetWithText(FilledButton, 'Calculate macro setup'),
        findsNothing,
      );

      await unmount(tester);
    });

    testWidgets('switching mode keeps a live answer for that mode', (
      tester,
    ) async {
      await tester.pumpWidget(app(const MacroScreen()));
      await tester.pumpAndSettle();

      // Extension tube default: 50 mm + 0.2 native at 25 mm extension. The
      // pinned strip mirrors the one label/value pair the card leads with, so
      // the answer is readable while the full card itself opens below the fold.
      expect(find.byType(CalculatorLiveAnswerBar), findsOneWidget);
      // The card leads with this label and the value under it; the page's lazy
      // list has not built it until it is scrolled to.
      await revealResult(tester);
      expect(find.text('Subject width across frame'), findsOneWidget);
      expect(renderedText(tester), hasRenderedText('0.70×'));

      // Reaching the card scrolled the mode selector out of the built range, so
      // it is brought back before the mode is switched.
      await tester.scrollUntilVisible(
        find.text('Coupled lenses'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Coupled lenses'));
      await tester.pumpAndSettle();

      // Coupled default: 50 mm primary over 28 mm reversed. The primary focal
      // length is the mode's own control, so it is revealed like every other
      // child of the lazy list before it is asserted.
      final primaryFocal = find.widgetWithText(
        TextField,
        'Primary focal length (mm)',
      );
      await tester.scrollUntilVisible(
        primaryFocal,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(primaryFocal, findsOneWidget);
      // The full card is still the canonical answer, one scroll below the strip.
      await revealResult(tester);
      expect(find.byType(CalculationResultView), findsOneWidget);
      expect(renderedText(tester), hasRenderedText('1.79×'));

      await unmount(tester);
    });

    testWidgets('the sensor width and native magnification stay advanced', (
      tester,
    ) async {
      await tester.pumpWidget(app(const MacroScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sensor width (mm)'), findsNothing);
      expect(find.text('Lens native magnification (×)'), findsNothing);
      await openExpander(tester, 'More settings');
      expect(find.text('Sensor width (mm)'), findsOneWidget);
      expect(find.text('Lens native magnification (×)'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('optics', () {
    testWidgets('focus stack leads with a plan and recalculates on overlap', (
      tester,
    ) async {
      await tester.pumpWidget(app(const FocusStackScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CalculationResultView), findsOneWidget);
      expect(find.text('Frames to shoot'), findsOneWidget);
      // 100 mm at f/8, 0.5 m to 1 m, 20% overlap: 62 frames.
      expect(renderedText(tester), hasRenderedText('62'));

      // Overlap is a preference, so it lives behind the conventions disclosure.
      await openExpander(tester, 'More settings');
      final overlap = find.byKey(const Key('focusStack-overlapPercent'));
      await tester.scrollUntilVisible(
        overlap,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(overlap, '50');
      await tester.pumpAndSettle();

      // 50% overlap needs 98 frames; the plan tracks the control.
      expect(renderedText(tester), hasRenderedText('98'));
      expect(find.widgetWithText(FilledButton, 'Calculate'), findsNothing);

      await unmount(tester);
    });

    testWidgets('field of view uses metres and answers immediately', (
      tester,
    ) async {
      await tester.pumpWidget(app(const FieldOfViewScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CalculationResultView), findsOneWidget);
      expect(find.text('Scene width at this distance'), findsOneWidget);
      expect(find.text('Subject distance (m)'), findsOneWidget);
      // The distance field is a display of the canonical millimetres, so it
      // shows 10 m while the calculation reads 10000 mm.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('fieldOfView-distanceMm')))
            .controller!
            .text,
        '10',
      );
      // 36x24 mm at 50 mm from 10 m: 39.60° horizontal, 7.20 m wide.
      expect(renderedText(tester), hasRenderedText('39.6°'));
      expect(renderedText(tester), hasRenderedText('7.20 m'));

      await unmount(tester);
    });

    testWidgets('diffraction keeps its sampling warning visible', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DiffractionScreen()));
      await tester.pumpAndSettle();

      // Default f/8 at a 4 µm pitch: a 2.68-pixel Airy disk, already at the
      // two-pixel sampling limit, so the warning shows from the first frame.
      expect(find.text('Airy disk on the sensor'), findsOneWidget);
      expect(renderedText(tester), hasRenderedText('2.68 pixels'));
      expect(find.textContaining('Diffraction is visible'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('diffraction-aperture')),
        '22',
      );
      await tester.pumpAndSettle();

      // Stopping down to f/22 grows the disk to 7.38 pixels.
      expect(renderedText(tester), hasRenderedText('7.38 pixels'));
      expect(find.textContaining('Diffraction is visible'), findsOneWidget);
      expect(
        find.textContaining('Diffraction spans at least two pixels'),
        findsOneWidget,
      );

      await unmount(tester);
    });
  });

  group('shared focus-family widgets', () {
    test('the raw millimetre adapter explains its conversion', () {
      const note = 'Stored in millimetres; the metre display is rounded.';
      expect(FocusDistanceAdapterField.helperFor(10000), note);
      expect(FocusDistanceAdapterField.helperFor(2500), note);
      expect(FocusDistanceAdapterField.helperFor(500), note);
      expect(FocusDistanceAdapterField.helperFor(0), isNull);
      expect(FocusDistanceAdapterField.helperFor(double.nan), isNull);
    });

    testWidgets('the live hint is announced to assistive tech', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: CalculatorLiveHint())),
        ),
      );
      expect(find.text('Updates as you adjust'), findsOneWidget);
      semantics.dispose();

      await unmount(tester);
    });
  });
}
