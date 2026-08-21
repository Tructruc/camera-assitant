/// Reusable, local-only observer location.
library;

enum LocationSource { manual, device }

final class SavedLocation {
  SavedLocation({
    required this.id,
    required String name,
    required this.latitudeDegrees,
    required this.longitudeDegrees,
    required this.timeZoneId,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.elevationMetres,
    this.accuracyMetres,
  }) : name = name.trim(),
       normalizedName = name.trim().toLowerCase() {
    if (id.trim().isEmpty || this.name.isEmpty || timeZoneId.trim().isEmpty) {
      throw ArgumentError('Location identity must not be blank.');
    }
    if (!latitudeDegrees.isFinite ||
        latitudeDegrees < -90 ||
        latitudeDegrees > 90 ||
        !longitudeDegrees.isFinite ||
        longitudeDegrees < -180 ||
        longitudeDegrees > 180) {
      throw ArgumentError('Location coordinates are outside Earth bounds.');
    }
    if (elevationMetres != null && !elevationMetres!.isFinite) {
      throw ArgumentError('Elevation must be finite.');
    }
    if (accuracyMetres != null &&
        (!accuracyMetres!.isFinite || accuracyMetres! < 0)) {
      throw ArgumentError('Accuracy must be non-negative.');
    }
    if (!createdAt.isUtc || !updatedAt.isUtc) {
      throw ArgumentError('Location timestamps must be UTC.');
    }
  }
  final String id;
  final String name;
  final String normalizedName;
  final double latitudeDegrees;
  final double longitudeDegrees;
  final double? elevationMetres;
  final String timeZoneId;
  final LocationSource source;
  final double? accuracyMetres;
  final DateTime createdAt;
  final DateTime updatedAt;
}
