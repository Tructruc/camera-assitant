/// Platform capability states keep every planner usable without permissions.
library;

enum PlanningView { numeric, timeline, compass, map, augmentedReality }

enum CapabilityStatus { available, permissionRequired, denied, unsupported }

final class PlanningCapabilities {
  const PlanningCapabilities({
    required this.location,
    required this.orientation,
    required this.camera,
    required this.augmentedReality,
  });
  const PlanningCapabilities.fallback()
    : location = CapabilityStatus.permissionRequired,
      orientation = CapabilityStatus.unsupported,
      camera = CapabilityStatus.permissionRequired,
      augmentedReality = CapabilityStatus.unsupported;
  final CapabilityStatus location;
  final CapabilityStatus orientation;
  final CapabilityStatus camera;
  final CapabilityStatus augmentedReality;
  bool get canShowAr =>
      camera == CapabilityStatus.available &&
      orientation == CapabilityStatus.available &&
      augmentedReality == CapabilityStatus.available;
}
