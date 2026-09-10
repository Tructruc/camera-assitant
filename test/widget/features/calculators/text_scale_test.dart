import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/providers.dart';
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

/// FR-019: every calculator and planner must stay reachable and unclipped at
/// 200% system text scale on a small phone viewport.
void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase.inMemory());
  tearDown(() => database.close());

  Widget app(Widget screen) => ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(database)],
    child: MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(body: screen),
      ),
    ),
  );

  for (final (name, screen) in <(String, Widget)>[
    ('saved locations', const SavedLocationsScreen()),
    ('depth of field', const DepthOfFieldScreen()),
    ('exposure comparison', const ExposureComparisonScreen()),
    ('long exposure / ND', const LongExposureScreen()),
    ('field of view', const FieldOfViewScreen()),
    ('diffraction guidance', const DiffractionScreen()),
    ('focus stack planner', const FocusStackScreen()),
    ('flash exposure', const FlashExposureScreen()),
    ('timelapse planner', const TimelapseScreen()),
    ('macro planner', const MacroScreen()),
    ('panorama planner', const PanoramaScreen()),
    ('night-sky planner', const AstronomyScreen()),
    ('Sun & Moon alignment', const AlignmentScreen()),
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

      // The longest content stays reachable by scrolling to the end.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  }
}
