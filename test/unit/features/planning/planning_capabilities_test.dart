import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';

void main() {
  test('heading accuracy exposes calibration state', () {
    expect(
      const DeviceHeadingReading(
        headingDegrees: 20,
        cameraHeadingDegrees: 21,
        accuracyDegrees: 8,
      ).needsCalibration,
      isFalse,
    );
    expect(
      const DeviceHeadingReading(
        headingDegrees: 20,
        cameraHeadingDegrees: null,
        accuracyDegrees: null,
      ).needsCalibration,
      isTrue,
    );
  });
  test('AR requires camera, orientation, and AR support', () {
    expect(const PlanningCapabilities.fallback().canShowAr, isFalse);
    expect(
      const PlanningCapabilities(
        location: CapabilityStatus.denied,
        orientation: CapabilityStatus.available,
        camera: CapabilityStatus.available,
        augmentedReality: CapabilityStatus.available,
      ).canShowAr,
      isTrue,
    );
  });
}
