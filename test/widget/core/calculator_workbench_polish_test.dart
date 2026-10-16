import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, CalculationSnapshot, SavedLocation;
import 'package:photography_assistant/core/presentation/calculator/calculator_components.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/capture_field_controls.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

/// The last polish pass from the rendered-screen review: a live answer that
/// stays on screen while its inputs scroll, one horizontal rail for a long
/// camera-value list instead of three wrapped rows, and disclosures that
/// survive being scrolled out of a lazy list.
///
/// The strip and the rail are shared kit, so the contracts are asserted here
/// once (on `CalculatorPage`, `CalculatorChipRail`/`CaptureChipRow` and the two
/// keep-alive disclosures) and then proved end-to-end on a real calculator
/// screen.
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

  /// Unmounting before the test ends lets Riverpod dispose the database
  /// streams and the page cancel its own live-calculation timer.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// The mirror's own rendered value.
  ///
  /// The strip paints its value as one rich run rather than a second [Text],
  /// so it is matched by the plain text of that run.
  Finder mirrorValue(String text) => find.byWidgetPredicate(
    (widget) => widget is RichText && widget.text.toPlainText() == text,
  );

  Widget page({
    required List<Widget> children,
    VoidCallback? onCalculate,
    List<TextEditingController> controllers = const <TextEditingController>[],
  }) => MaterialApp(
    home: Scaffold(
      body: CalculatorPage(
        inputControllers: controllers,
        onInputsChanged: () {},
        onCalculate: onCalculate,
        children: children,
      ),
    ),
  );

  CalculationResultView resultView({
    String title = 'Depth of field result',
    (String, String) highlight = const ('Hyperfocal distance', '10.47 m'),
    bool stale = false,
  }) => CalculationResultView(
    title: title,
    highlight: highlight,
    stale: stale,
    onReset: () {},
    onSave: () {},
  );

  group('pinned live answer strip', () {
    testWidgets('pins the result view own label and value below the inputs', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[const SizedBox(height: 1200), resultView()],
        ),
      );

      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(bar, findsOneWidget);
      // The same exact pair the result card leads with - nothing re-derived.
      expect(
        find.descendant(of: bar, matching: mirrorValue('Hyperfocal distance')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: mirrorValue('10.47 m')),
        findsOneWidget,
      );

      // It takes its own layout row: the scroll view ends where it begins, so
      // it can never cover a control.
      expect(
        tester.getRect(find.byType(ListView)).bottom,
        lessThanOrEqualTo(tester.getRect(bar).top + 0.5),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('mirrors the answer without becoming a second copy of it', (
      tester,
    ) async {
      // The card is on screen here, so both it and the strip are built at once.
      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[resultView(), const SizedBox(height: 1200)],
        ),
      );

      // The result card is the one canonical text node for the value; the
      // strip adds a painted mirror and one semantics node, not a second
      // addressable string of the same number.
      expect(find.text('10.47 m'), findsOneWidget);
      expect(find.byType(CalculatorLiveAnswerBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CalculatorLiveAnswerBar),
          matching: mirrorValue('10.47 m'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.label ==
                  'Depth of field result: Hyperfocal distance 10.47 m',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('stays on screen while the body scrolls far past the result', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[
            const SizedBox(height: 400),
            resultView(),
            const SizedBox(height: 2400),
          ],
        ),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: mirrorValue('10.47 m')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('follows the current result and never pins a stale one', (
      tester,
    ) async {
      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[
            resultView(highlight: ('Hyperfocal distance', '10.47 m')),
          ],
        ),
      );
      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(
        find.descendant(of: bar, matching: mirrorValue('10.47 m')),
        findsOneWidget,
      );

      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[
            resultView(highlight: ('Hyperfocal distance', '8.21 m')),
          ],
        ),
      );
      expect(
        find.descendant(of: bar, matching: mirrorValue('8.21 m')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: bar, matching: mirrorValue('10.47 m')),
        findsNothing,
      );

      // A stale result describes inputs that have moved on; it is never
      // summarised as if it were the live answer.
      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: <Widget>[
            resultView(
              highlight: ('Hyperfocal distance', '8.21 m'),
              stale: true,
            ),
          ],
        ),
      );
      expect(bar, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is absent for an explicit-action tool and for no result', (
      tester,
    ) async {
      // Astronomy and alignment keep a Calculate action and pass no
      // `onCalculate`, so a result that may not track the inputs is never
      // pinned.
      await tester.pumpWidget(
        page(onCalculate: null, children: <Widget>[resultView()]),
      );
      expect(find.byType(CalculatorLiveAnswerBar), findsNothing);

      await tester.pumpWidget(
        page(
          onCalculate: () {},
          children: const <Widget>[SizedBox(height: 400)],
        ),
      );
      expect(find.byType(CalculatorLiveAnswerBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is a readout, not a button', (tester) async {
      await tester.pumpWidget(
        page(onCalculate: () {}, children: <Widget>[resultView()]),
      );

      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(
        find.descendant(of: bar, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.descendant(of: bar, matching: find.byType(ButtonStyleButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: bar, matching: find.byType(GestureDetector)),
        findsNothing,
      );
    });

    testWidgets('stays readable above the keyboard at 320 wide, 200 percent '
        'text', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 260),
              ),
              child: Scaffold(
                body: CalculatorPage(
                  inputControllers: const <TextEditingController>[],
                  onInputsChanged: () {},
                  onCalculate: () {},
                  children: <Widget>[
                    const SizedBox(height: 1000),
                    resultView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(bar, findsOneWidget);
      // The Scaffold resizes around the inset, so the strip sits above the
      // keyboard rather than under it, and it stays on screen.
      final rect = tester.getRect(bar);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(568 - 260 + 0.5));
      expect(
        find.descendant(of: bar, matching: mirrorValue('Hyperfocal distance')),
        findsOneWidget,
      );
    });

    testWidgets('survives landscape at 200 percent text', (tester) async {
      tester.view.physicalSize = const Size(568, 320);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        page(onCalculate: () {}, children: <Widget>[resultView()]),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(CalculatorLiveAnswerBar), findsOneWidget);
    });
  });

  group('camera-value chip rail', () {
    List<Widget> shutterChips({String selected = '1/125'}) => <Widget>[
      for (final (label, seconds) in commonShutterStops.take(10))
        CaptureChoiceChip<double>(
          label: label,
          value: seconds,
          selected: label == selected,
          onSelected: (_) {},
        ),
    ];

    testWidgets('ten full stops are one horizontal rail, not three rows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                CaptureChipRow(caption: 'Full stops', chips: shutterChips()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = find.byType(CalculatorChipRail);
      expect(rail, findsOneWidget);
      final scroller = find.descendant(
        of: rail,
        matching: find.byType(SingleChildScrollView),
      );
      expect(
        tester.widget<SingleChildScrollView>(scroller).scrollDirection,
        Axis.horizontal,
      );
      // One row: ten chips could never fit side by side, and wrapping them is
      // exactly the clutter the rail replaces.
      expect(tester.getSize(scroller).height, lessThan(64));

      // Every label is still there, and the selected state is still marked.
      expect(find.byType(ChoiceChip), findsNWidgets(10));
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '1/125'))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail fades its edge while more chips are reachable', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                CaptureChipRow(caption: 'Full stops', chips: shutterChips()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = find.byType(CalculatorChipRail);
      final fade = find.descendant(
        of: rail,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).gradient != null,
        ),
      );
      expect(fade, findsOneWidget);

      // At the end of the rail there is nothing more to reach, so no hint is
      // left behind.
      await tester.drag(
        find.descendant(of: rail, matching: find.byType(SingleChildScrollView)),
        const Offset(-900, 0),
      );
      await tester.pumpAndSettle();
      expect(fade, findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short mode or orientation list still wraps', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                CaptureChipRow(
                  caption: 'Camera orientation',
                  chips: <Widget>[
                    for (final label in const <String>['Landscape', 'Portrait'])
                      CaptureChoiceChip<String>(
                        label: label,
                        value: label,
                        selected: label == 'Landscape',
                        onSelected: (_) {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorChipRail), findsNothing);
      expect(find.byType(ChoiceChip), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });

  group('disclosure state survives viewport eviction', () {
    testWidgets('More settings stays open after it is scrolled away', (
      tester,
    ) async {
      final raw = TextEditingController(text: '0.03');
      addTearDown(raw.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                CalculatorAdvancedSection(
                  children: <Widget>[
                    TextField(
                      controller: raw,
                      decoration: const InputDecoration(
                        labelText: 'Circle of confusion (mm)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4000),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Circle of confusion (mm)'), findsNothing);
      await tester.tap(find.text('More settings'));
      await tester.pumpAndSettle();
      expect(find.text('Circle of confusion (mm)'), findsOneWidget);

      // Far enough that a plain lazy list evicts index 0 entirely.
      await tester.drag(find.byType(ListView), const Offset(0, -3500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 3500));
      await tester.pumpAndSettle();

      // Still open, without a second tap, and the edited value is intact.
      expect(find.text('Circle of confusion (mm)'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '0.03',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the result Details stay open after they are scrolled away', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                CalculationResultView(
                  title: 'Depth of field result',
                  highlight: const ('Hyperfocal distance', '10.47 m'),
                  details: const <(String, String)>[
                    ('Depth in front of focus', '5.25 m'),
                  ],
                  inputs: const <(String, String)>[('Focal length', '50 mm')],
                  onReset: () {},
                  onSave: () {},
                ),
                const SizedBox(height: 4000),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(find.text('Values used'), findsOneWidget);
      expect(find.text('Focal length'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -3500));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 3500));
      await tester.pumpAndSettle();

      expect(find.text('Values used'), findsOneWidget);
      expect(find.text('Focal length'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a real screen keeps More settings open across a long scroll', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(const TimelapseScreen()));
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('More settings'),
        300,
        scrollable: scrollable,
      );
      await tester.tap(find.text('More settings'));
      await tester.pumpAndSettle();

      final sizeField = find.widgetWithText(
        TextField,
        'Estimated size per frame (MB)',
      );
      await tester.scrollUntilVisible(sizeField, 300, scrollable: scrollable);
      await tester.enterText(sizeField, '42');
      await tester.pumpAndSettle();

      // Far past the section - the QA repro - and back.
      await tester.drag(scrollable, const Offset(0, -6000));
      await tester.pumpAndSettle();
      await tester.drag(scrollable, const Offset(0, 6000));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(sizeField, 300, scrollable: scrollable);

      // Still open, and the raw value is the one that was typed.
      expect(sizeField, findsOneWidget);
      expect(tester.widget<TextField>(sizeField).controller?.text, '42');
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });

  group('exposure comparison polish', () {
    testWidgets('the redundant shutter and ISO sliders are gone', (
      tester,
    ) async {
      await tester.pumpWidget(app(const ExposureComparisonScreen()));
      await tester.pumpAndSettle();

      // Preset stepping and the rail carry the camera values; a continuous
      // slider repeated them and pushed the answer off the phone.
      expect(find.byType(Slider), findsNothing);

      // Exact entry is untouched, on both sides.
      expect(
        find.widgetWithText(TextField, 'Baseline shutter (seconds)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextField, 'Baseline ISO'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Candidate shutter (seconds)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.widgetWithText(TextField, 'Candidate shutter (seconds)'),
        findsOneWidget,
      );

      // The ten full stops are one rail, not three wrapped rows.
      expect(find.byType(CalculatorChipRail), findsWidgets);
      await unmount(tester);
    });

    testWidgets('the pinned answer tracks an edit of the top field', (
      tester,
    ) async {
      await tester.pumpWidget(app(const ExposureComparisonScreen()));
      await tester.pumpAndSettle();

      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: mirrorValue('Total difference')),
        findsOneWidget,
      );
      // Two identical defaults read as equivalent.
      expect(
        find.descendant(of: bar, matching: mirrorValue('0.0 stops')),
        findsOneWidget,
      );

      // Editing the very top input is enough: the pinned value follows without
      // scrolling to the result card.
      await tester.enterText(
        find.widgetWithText(TextField, 'Baseline aperture (f-number)'),
        '2.8',
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: bar, matching: mirrorValue('-1.0 stops')),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('a lightweight screen pins its answer from the first frame', (
      tester,
    ) async {
      await tester.pumpWidget(app(const DepthOfFieldScreen()));
      await tester.pumpAndSettle();

      final bar = find.byType(CalculatorLiveAnswerBar);
      expect(bar, findsOneWidget);
      expect(
        find.descendant(of: bar, matching: mirrorValue('Hyperfocal distance')),
        findsOneWidget,
      );
      await unmount(tester);
    });
  });
}
