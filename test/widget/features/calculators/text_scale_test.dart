import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

import '../../../support/real_font.dart';

/// FR-019: every calculator and planner must stay reachable and unclipped at
/// 200% system text scale on a small phone viewport.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light,
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: screen),
      ),
    ),
  );

  for (final (name, screen, primaryAction) in <(String, Widget, String)>[
    ('saved locations', const SavedLocationsScreen(), 'Add location'),
    ('depth of field', const DepthOfFieldScreen(), 'Calculate'),
    (
      'exposure comparison',
      const ExposureComparisonScreen(),
      'Compare exposures',
    ),
    ('long exposure / ND', const LongExposureScreen(), 'Calculate exposure'),
    ('field of view', const FieldOfViewScreen(), 'Calculate'),
    ('diffraction guidance', const DiffractionScreen(), 'Calculate'),
    ('focus stack planner', const FocusStackScreen(), 'Calculate'),
    ('flash exposure', const FlashExposureScreen(), 'Calculate flash exposure'),
    ('timelapse planner', const TimelapseScreen(), 'Plan timelapse'),
    ('macro planner', const MacroScreen(), 'Calculate macro setup'),
    ('panorama planner', const PanoramaScreen(), 'Plan panorama'),
    ('night-sky planner', const AstronomyScreen(), 'Plan night sky'),
    ('Sun & Moon alignment', const AlignmentScreen(), 'Search alignments'),
  ]) {
    testWidgets('$name stays usable at 200 percent text scale', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();

      // No overflow, clipping, or layout assertion may escape the frame.
      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);

      // Every screen keeps labelled controls for screen readers, not just one.
      expect(find.bySemanticsLabel(RegExp('.+')), findsAtLeastNWidgets(2));

      // The screen's real primary action must still be reachable at 2x text;
      // "some scrollable and some labelled node exist" would accept a control
      // that 200% text pushed out of the scroll extent.
      final action = find.widgetWithText(FilledButton, primaryAction);
      await tester.scrollUntilVisible(
        action,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        action,
        findsOneWidget,
        reason: '$primaryAction is unreachable at 200 percent text',
      );
      expect(tester.takeException(), isNull);

      // The longest content stays reachable by scrolling to the end.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  }

  // The forms are gated above; these are the computed results, which carry the
  // densest layouts in the app (hero values, tile grids, ordered capture
  // tables, long provenance lines). A screen can compute cleanly at 100% and
  // still overflow at 200%, and the result is the part a photographer actually
  // reads in the field. Every result view offers the same pair of trailing
  // actions, so they double as the proof that an answer rendered at all.
  for (final (name, screen, action, prefill)
      in <(String, Widget, String, Future<void> Function(WidgetTester)?)>[
        ('timelapse plan', const TimelapseScreen(), 'Plan timelapse', null),
        ('macro setup', const MacroScreen(), 'Calculate macro setup', null),
        ('panorama grid', const PanoramaScreen(), 'Plan panorama', null),
        (
          'exposure comparison',
          const ExposureComparisonScreen(),
          'Compare exposures',
          null,
        ),
        ('field of view', const FieldOfViewScreen(), 'Calculate', null),
        ('diffraction guidance', const DiffractionScreen(), 'Calculate', null),
        ('focus stack plan', const FocusStackScreen(), 'Calculate', null),
        (
          'flash exposure',
          const FlashExposureScreen(),
          'Calculate flash exposure',
          null,
        ),
        ('night-sky plan', const AstronomyScreen(), 'Plan night sky', null),
        (
          'alignment search',
          const AlignmentScreen(),
          'Search alignments',
          null,
        ),
        (
          'depth of field',
          const DepthOfFieldScreen(),
          'Calculate',
          (tester) async {
            await tester.enterText(find.byKey(const Key('dof-focal')), '50');
          },
        ),
        (
          'long exposure stack',
          const LongExposureScreen(),
          'Calculate exposure',
          (tester) async {
            await tester.enterText(find.byKey(const Key('long-base')), '1/30');
          },
        ),
      ]) {
    testWidgets('$name result stays intact at 200 percent text scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();

      if (prefill != null) {
        await prefill(tester);
        await tester.pumpAndSettle();
      }

      final compute = find.text(action);
      await tester.scrollUntilVisible(
        compute,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(compute);
      await tester.pumpAndSettle();

      // The answer leads at 2x text too, and every stored section below it is
      // reachable rather than clipped away.
      expect(tester.takeException(), isNull);
      expect(
        find.text('Save result'),
        findsOneWidget,
        reason: 'the $name result did not render at 200 percent text',
      );
      await tester.scrollUntilVisible(
        find.text('Reset'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  // 400x800 is a comfortable phone. A 320x568 device is the narrowest these
  // screens are expected to survive, and the test font is wider than the real
  // one, so this is the pessimistic end of supported hardware rather than a
  // device anyone actually carries. The four results below are the widest
  // content in the app: an ordered capture table, a long planner-context list,
  // an event table with provenance, and the optics tiles.
  for (final (name, screen, action, prefill)
      in <(String, Widget, String, Future<void> Function(WidgetTester)?)>[
        ('panorama grid', const PanoramaScreen(), 'Plan panorama', null),
        ('night-sky plan', const AstronomyScreen(), 'Plan night sky', null),
        ('timelapse plan', const TimelapseScreen(), 'Plan timelapse', null),
        (
          'depth of field',
          const DepthOfFieldScreen(),
          'Calculate',
          (tester) async {
            await tester.enterText(find.byKey(const Key('dof-focal')), '50');
          },
        ),
      ]) {
    testWidgets('$name result fits a 320 wide phone at 200 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app(screen));
      await tester.pumpAndSettle();

      if (prefill != null) {
        await prefill(tester);
        await tester.pumpAndSettle();
      }

      final compute = find.text(action);
      await tester.scrollUntilVisible(
        compute,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(compute);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Save result'),
        findsOneWidget,
        reason: 'the $name result did not render on a 320 wide phone',
      );
      await tester.scrollUntilVisible(
        find.text('Reset'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Reset'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }

  /// Renders one screen at a given text scale on the narrowest phone the app
  /// supports, so a message that only fits a wide viewport fails here.
  Widget appAt(Widget screen, double scale) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light.copyWith(
        textTheme: AppTheme.light.textTheme.apply(fontFamily: 'RobotoMeasured'),
      ),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Scaffold(body: screen),
      ),
    ),
  );

  Finder fieldLabelled(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );

  Future<void> calculate(WidgetTester tester) async {
    final button = find.text('Calculate');
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    // scrollUntilVisible stops as soon as any part of the button is inside the
    // viewport, which on a short screen can still leave its centre outside it.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  /// Fails when the laid-out message is cut short, which is invisible to a test
  /// that only looks for the widget's text. The message may be below the fold,
  /// so it is scrolled to first: a field that is not built cannot be measured.
  Future<void> expectFullyLaidOut(WidgetTester tester, String message) async {
    final finder = find.text(message);
    final scrollable = find.byType(Scrollable);
    if (finder.evaluate().isEmpty && scrollable.evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: scrollable.first,
      );
      await tester.pumpAndSettle();
    }
    expect(
      finder,
      findsOneWidget,
      reason: 'the message "$message" is not on screen at all',
    );
    final render = finder.evaluate().single.findRenderObject()!;
    final paragraph = render is RenderParagraph
        ? render
        : render.parent! as RenderParagraph;
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason:
          '"$message" is cut off: it needs '
          '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(0)}px '
          'in a ${paragraph.size.width.toStringAsFixed(0)}px line',
    );
  }

  // A field's message is the app telling the user what to change, and the
  // input decorator lays it out on a single line unless it is told otherwise:
  // the longest message in the app used to render as a fifth of its sentence,
  // at 100% text as well as 200%. These cases measure the paragraph that was
  // actually laid out, on the narrowest supported viewport, rather than the
  // string the widget holds.
  // The field messages are measured against the app's real font: this group
  // claims a message *fits*, and `flutter_test`'s stand-in font is about twice
  // as wide per glyph, which would fail copy a photographer reads fine. Loading
  // Roboto under the family the app's text theme already asks for means the
  // styles inside the decoration theme resolve to it as well.
  var hasRealFont = false;
  setUpAll(() async {
    hasRealFont = await loadRoboto();
  });

  for (final scale in <double>[1, 1.3, 2]) {
    testWidgets('field messages are readable at ${scale}x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      expect(
        hasRealFont,
        isTrue,
        reason:
            'Roboto did not load, so this gate would measure the '
            'stand-in font instead of the one the app ships',
      );

      await tester.pumpWidget(appAt(const DepthOfFieldScreen(), scale));
      await tester.pumpAndSettle();

      // The shortest of the two messages: a focus inside the focal length.
      await tester.enterText(find.byKey(const Key('dof-focal')), '20000');
      await calculate(tester);
      await expectFullyLaidOut(
        tester,
        'Focus distance must be greater than focal length.',
      );

      // The longest one, which needs the advanced section open and a focus
      // still beyond the focal length so validation passes first.
      final advanced = find.text('More settings');
      await tester.scrollUntilVisible(
        advanced,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(advanced);
      await tester.pumpAndSettle();
      await tester.enterText(fieldLabelled('Focal length (mm)'), '1e200');
      await tester.enterText(fieldLabelled('Focus distance (mm)'), '1e201');
      await calculate(tester);
      await expectFullyLaidOut(
        tester,
        'Increase the aperture or circle of confusion.',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
