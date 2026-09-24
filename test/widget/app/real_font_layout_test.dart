import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/database/app_database.dart'
    hide CameraBody, SavedLocation;
import 'package:photography_assistant/features/alignment/presentation/alignment_screen.dart';
import 'package:photography_assistant/features/astronomy/presentation/astronomy_screen.dart';
import 'package:photography_assistant/features/depth_of_field/presentation/depth_of_field_screen.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_list_screen.dart';
import 'package:photography_assistant/features/exposure_comparison/presentation/exposure_comparison_screen.dart';
import 'package:photography_assistant/features/flash_exposure/presentation/flash_exposure_screen.dart';
import 'package:photography_assistant/features/long_exposure/presentation/long_exposure_screen.dart';
import 'package:photography_assistant/features/macro/presentation/macro_screen.dart';
import 'package:photography_assistant/features/optics/presentation/optics_screens.dart';
import 'package:photography_assistant/features/panorama/presentation/panorama_screen.dart';
import 'package:photography_assistant/features/planning/presentation/saved_locations_screen.dart';
import 'package:photography_assistant/features/saved_calculations/presentation/saved_calculations_screen.dart';
import 'package:photography_assistant/features/settings/presentation/settings_screen.dart';
import 'package:photography_assistant/features/timelapse/presentation/timelapse_screen.dart';

import '../../support/real_font.dart';

/// FR-019 measured with the font the app really ships.
///
/// Every other layout gate runs with `flutter_test`'s stand-in font, whose
/// glyphs are about one em wide. That font is *wider* than Roboto, so those
/// gates err on the pessimistic side - which is the safe direction - but it
/// breaks lines where Roboto would not, so a result that only overflows with
/// real metrics could still pass them.
///
/// This file loads the Roboto that ships with the Flutter SDK and re-checks the
/// densest screens at 200% system text, the scale FR-019 names. The SDK ships
/// the files under `bin/cache/artifacts/material_fonts`, reachable from the dart
/// inside that same cache, so the path is derived rather than hardcoded and the
/// group skips (with a reason) instead of failing if a future SDK moves them.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  if (robotoFontPaths().isEmpty) {
    test(
      'real-font layout gate',
      () {},
      skip: 'no Roboto in ${materialFontsDirectory()}',
    );
    return;
  }

  setUpAll(() async {
    expect(
      await loadRoboto(),
      isTrue,
      reason: 'the SDK listed Roboto faces but they did not load',
    );
  });

  Widget app(Widget screen, {bool bold = false}) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      theme: AppTheme.light.copyWith(
        textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
      ),
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: const TextScaler.linear(2),
          // Android's "bold text" accessibility setting. With real Roboto this
          // asks for the bold face and widens copy by about two percent, which
          // the stand-in font could never show - it has one weight.
          boldText: bold,
        ),
        child: Scaffold(body: screen),
      ),
    ),
  );

  // If Roboto failed to load, Flutter would silently fall back to the stand-in
  // font and every case below would measure the very metrics this file exists
  // to avoid, so the load is asserted rather than assumed: the same string has
  // a different width in the two fonts.
  testWidgets('the real font is the one being measured', (tester) async {
    const sample = 'Hyperfocal distance 1,234.56 m';
    double widthOf(String? family) {
      final painter = TextPainter(
        text: TextSpan(
          text: sample,
          style: TextStyle(fontFamily: family, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.size.width;
      painter.dispose();
      return width;
    }

    expect(
      widthOf('Roboto'),
      isNot(equals(widthOf(null))),
      reason:
          'Roboto did not load, so this file would measure the stand-in font',
    );
  });

  // Every screen the shell can reach, at the largest text scale FR-019 names,
  // on the narrowest phone the app supports and with Roboto's metrics. The
  // stand-in font is wider, so these cases mostly re-confirm the gates that
  // already run - except where a long unbreakable token (,`1/8000`, `ISO
  // 102400`, a lens name) breaks lines differently in a real font.
  const cases = <(String, Widget, String, Key?)>[
    ('depth of field', DepthOfFieldScreen(), 'Calculate', Key('dof-focal')),
    (
      'exposure comparison',
      ExposureComparisonScreen(),
      'Compare exposures',
      null,
    ),
    ('long exposure / ND', LongExposureScreen(), 'Calculate exposure', null),
    ('field of view', FieldOfViewScreen(), 'Calculate', null),
    ('diffraction guidance', DiffractionScreen(), 'Calculate', null),
    ('focus stack planner', FocusStackScreen(), 'Calculate', null),
    ('flash exposure', FlashExposureScreen(), 'Calculate flash exposure', null),
    ('timelapse planner', TimelapseScreen(), 'Plan timelapse', null),
    ('macro planner', MacroScreen(), 'Calculate macro setup', null),
    ('panorama planner', PanoramaScreen(), 'Plan panorama', null),
    ('night-sky planner', AstronomyScreen(), 'Plan night sky', null),
    ('Sun & Moon alignment', AlignmentScreen(), 'Search alignments', null),
    ('saved locations', SavedLocationsScreen(), 'Add location', null),
    ('saved results', SavedCalculationsScreen(), '', null),
    ('settings', SettingsScreen(), '', null),
    ('equipment list', EquipmentListScreen(), '', null),
  ];

  // The screen with a horizontal kind filter would otherwise be scrolled along
  // its chips, which proves nothing about the rows. A screen with an empty
  // state has no scrollable at all, and `.first` on none of them throws rather
  // than matching nothing, so the empty case returns the plain finder.
  Finder listScrollable() {
    final vertical = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    if (vertical.evaluate().isNotEmpty) return vertical.first;
    final any = find.byType(Scrollable);
    return any.evaluate().isEmpty ? any : any.first;
  }

  for (final bold in <bool>[false, true]) {
    for (final (name, screen, action, prefillKey) in cases) {
      testWidgets('$name fits at 200 percent text with real font metrics'
          '${bold ? ' and bold text' : ''}', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(app(screen, bold: bold));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$name overflowed');

        if (prefillKey != null) {
          await tester.enterText(find.byKey(prefillKey), '50');
          await tester.pumpAndSettle();
        }
        if (action.isNotEmpty) {
          final primary = find.text(action);
          await tester.scrollUntilVisible(
            primary,
            300,
            scrollable: listScrollable(),
          );
          await tester.pumpAndSettle();
          await tester.tap(primary);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$name overflowed once it produced a result',
          );
        }

        // Walk the whole surface: a row that only overflows below the fold would
        // otherwise never be laid out. A screen with an empty state has nothing
        // to scroll, which is not a failure.
        final scrollable = listScrollable();
        if (scrollable.evaluate().isNotEmpty) {
          for (var step = 0; step < 10; step++) {
            await tester.drag(scrollable, const Offset(0, -200));
            await tester.pumpAndSettle();
          }
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '$name overflowed while scrolling with real font metrics',
        );

        // A drift-backed screen left mounted keeps a zero-duration query-stream
        // timer pending, which hangs the test instead of failing it.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      });
    }
  }
}
