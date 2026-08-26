import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/repositories/preferences_repository.dart';
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';
import 'package:photography_assistant/features/planning/presentation/live_compass_view.dart';

void main() {
  testWidgets('shows live magnetic heading, target delta, and accuracy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveCompassView(
            trueBearingDegrees: 100,
            magneticDeclinationDegrees: 7,
            northReference: NorthReference.trueNorth,
            headingReadings: Stream.value(
              const DeviceHeadingReading(
                headingDegrees: 80,
                cameraHeadingDegrees: null,
                accuracyDegrees: 6,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Heading 80.0° magnetic'), findsOneWidget);
    expect(find.textContaining('Target 100.0° true'), findsOneWidget);
    expect(find.textContaining('13.0° right'), findsOneWidget);
    expect(find.textContaining('Calibrated ±6°'), findsOneWidget);
  });

  testWidgets('keeps target guidance when the sensor is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveCompassView(
            trueBearingDegrees: 100,
            magneticDeclinationDegrees: 7,
            northReference: NorthReference.magneticNorth,
            headingReadings: Stream.empty(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Live heading unavailable'), findsOneWidget);
    expect(find.textContaining('93.0° magnetic'), findsOneWidget);
    expect(find.textContaining('numeric and map'), findsOneWidget);
  });
}
