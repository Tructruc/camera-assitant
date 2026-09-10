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

  test('camera pitch derives vertical angle from gravity', () {
    expect(cameraPitchDegrees(0, 9.81, 0), closeTo(0, 0.01));
    expect(cameraPitchDegrees(0, 0, -9.81), closeTo(90, 0.01));
    expect(cameraPitchDegrees(0, 0, 9.81), closeTo(-90, 0.01));
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

  test('raw platform observations map to capability states', () {
    final ready = planningCapabilitiesFrom(
      location: CapabilityStatus.available,
      camera: CapabilityStatus.available,
      compassAvailable: true,
    );
    expect(ready.canShowAr, isTrue);
    expect(ready.augmentedReality, CapabilityStatus.available);
    expect(ready.augmentedRealityLimitation, contains('available'));

    final noCompass = planningCapabilitiesFrom(
      location: CapabilityStatus.permissionRequired,
      camera: CapabilityStatus.available,
      compassAvailable: false,
    );
    expect(noCompass.orientation, CapabilityStatus.unsupported);
    expect(noCompass.canShowAr, isFalse);
    expect(
      noCompass.augmentedRealityLimitation,
      contains('orientation sensor'),
    );

    final cameraDenied = planningCapabilitiesFrom(
      location: CapabilityStatus.unsupported,
      camera: CapabilityStatus.denied,
      compassAvailable: true,
    );
    // Location never gates AR, and a denied camera must be described as denied
    // rather than as an unsupported device.
    expect(cameraDenied.augmentedReality, CapabilityStatus.unsupported);
    expect(cameraDenied.augmentedRealityLimitation, contains('denied'));
    expect(cameraDenied.augmentedRealityLimitation, contains('camera'));

    final cameraUnasked = planningCapabilitiesFrom(
      location: CapabilityStatus.available,
      camera: CapabilityStatus.permissionRequired,
      compassAvailable: true,
    );
    expect(
      cameraUnasked.augmentedRealityLimitation,
      contains('not been granted yet'),
    );
  });

  test('the fallback set explains itself without claiming a device fault', () {
    const fallback = PlanningCapabilities.fallback();
    expect(fallback.canShowAr, isFalse);
    expect(fallback.augmentedRealityLimitation, contains('camera'));
    expect(fallback.augmentedRealityLimitation, isNot(contains('no usable')));
  });
}
