import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/presentation/offline_planning_map.dart';

void main() {
  testWidgets('renders an accessible spatial bearing and altitude schematic', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflinePlanningMap(
            desiredBearingDegrees: 135,
            observerLabel: 'Observer 51.5, 0.0',
            markers: [
              PlanningMapMarker(
                bearingDegrees: 135,
                altitudeDegrees: 18,
                label: 'Moon',
                isPrimary: true,
              ),
              PlanningMapMarker(
                bearingDegrees: 160,
                altitudeDegrees: 5,
                label: 'Later',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Offline spatial schematic'), findsOneWidget);
    expect(find.textContaining('135.0° true'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(OfflinePlanningMap)).label,
      contains(
        'Offline spatial schematic. Desired bearing 135.0 degrees true. Moon at 135.0 degrees bearing and 18.0 degrees altitude. Later at 160.0 degrees bearing and 5.0 degrees altitude.',
      ),
    );
  });

  testWidgets('explains when no candidate markers are available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OfflinePlanningMap(
            desiredBearingDegrees: 270,
            observerLabel: 'Observer',
            markers: [],
          ),
        ),
      ),
    );

    expect(find.text('No target positions in this plan.'), findsOneWidget);
    expect(find.textContaining('No terrain or map tiles'), findsOneWidget);
  });
}
