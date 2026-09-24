import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/app/theme/app_theme.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/equipment/presentation/equipment_picker.dart';
import 'package:photography_assistant/features/planning/presentation/field_checklist.dart';
import 'package:photography_assistant/features/planning/presentation/live_compass_view.dart';
import 'package:photography_assistant/features/planning/presentation/offline_planning_map.dart';
import 'package:photography_assistant/features/planning/presentation/planning_context_card.dart';

/// FR-019 for the planning surfaces that are not screens of their own: the
/// equipment picker sheet, the field checklist, the live compass card and the
/// offline map legend all carry labels the user reads outdoors, and all of them
/// are rendered inside a plan or a calculator screen rather than alone.
///
/// Two of the three real defects found under this feature were labels that
/// could not wrap (a settings section header and a catalogue group header), so
/// these widgets are gated with the longest label a real catalogue produces.
void main() {
  const long = 'Long descriptive label that a real catalogue would carry';

  final cases = <(String, Widget)>[
    (
      'equipment picker',
      EquipmentPicker<String>(
        label: 'Saved ND filter (optional)',
        items: ['$long one', '$long two'],
        itemLabel: (item) => item,
        onSelected: (_) {},
      ),
    ),
    (
      'field checklist',
      FieldChecklist(
        items: {'$long alpha': false, '$long beta': true},
        onChanged: (_) {},
      ),
    ),
    (
      'live compass',
      const LiveCompassView(
        trueBearingDegrees: 123.4,
        magneticDeclinationDegrees: 1.2,
        northReference: NorthReference.trueNorth,
      ),
    ),
    (
      'offline planning map',
      OfflinePlanningMap(
        desiredBearingDegrees: 90,
        observerLabel: '$long observer',
        markers: [
          PlanningMapMarker(
            bearingDegrees: 45,
            altitudeDegrees: 20,
            label: '$long sun',
          ),
        ],
      ),
    ),
    (
      'planning context card',
      PlanningContextCard(
        entries: [
          ('Planner time', '2026-08-21 22:00 UTC+02:00'),
          ('$long key', '$long value'),
        ],
      ),
    ),
  ];

  for (final (name, widget) in cases) {
    testWidgets('$name lays out at 200 percent text scale', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(body: SingleChildScrollView(child: widget)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '$name overflowed at first paint',
      );

      // Content that pushed the widget past the viewport has to be reachable,
      // not merely painted off the bottom edge.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '$name overflowed while scrolling',
      );
    });
  }
}
