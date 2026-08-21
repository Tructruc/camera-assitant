import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/domain/planning_capabilities.dart';

void main() {
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
