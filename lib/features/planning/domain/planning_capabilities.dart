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

  /// User-facing explanation of what specifically blocks the live AR overlay.
  /// Detection never prompts for a permission, so "permissionRequired" means
  /// "not asked yet", not "refused".
  String get augmentedRealityLimitation {
    if (canShowAr) return 'The live AR overlay is available.';
    for (final missing in <(CapabilityStatus, String)>[
      (camera, 'camera'),
      (orientation, 'orientation sensor'),
      (augmentedReality, 'AR support'),
    ]) {
      switch (missing.$1) {
        case CapabilityStatus.denied:
          return 'Access to the ${missing.$2} is denied for this app.';
        case CapabilityStatus.permissionRequired:
          return 'Access to the ${missing.$2} has not been granted yet; it is requested only when you open the live view.';
        case CapabilityStatus.unsupported:
          return 'This device provides no usable ${missing.$2}.';
        case CapabilityStatus.available:
          continue;
      }
    }
    return 'This device cannot show the live AR overlay.';
  }
}

/// Pure mapping from raw platform observations to planner capabilities, so the
/// permission-required / denied / unsupported branches are testable without a
/// device or a platform channel.
PlanningCapabilities planningCapabilitiesFrom({
  required CapabilityStatus location,
  required CapabilityStatus camera,
  required bool compassAvailable,
}) {
  final orientation = compassAvailable
      ? CapabilityStatus.available
      : CapabilityStatus.unsupported;
  return PlanningCapabilities(
    location: location,
    orientation: orientation,
    camera: camera,
    augmentedReality:
        camera == CapabilityStatus.available &&
            orientation == CapabilityStatus.available
        ? CapabilityStatus.available
        : CapabilityStatus.unsupported,
  );
}
