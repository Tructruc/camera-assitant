class Lens {
  const Lens({
    this.id,
    required this.name,
    required this.minApertureWide,
    required this.minApertureTele,
    required this.maxAperture,
    required this.variableAperture,
    required this.minFocalLengthMm,
    required this.maxFocalLengthMm,
    required this.minFocusDistanceM,
  });

  final int? id;
  final String name;

  // Widest aperture at min focal length.
  final double minApertureWide;

  // Widest aperture at max focal length (equals wide for constant-aperture lenses).
  final double minApertureTele;

  // Smallest aperture supported (e.g. f/22).
  final double maxAperture;

  final bool variableAperture;
  final double minFocalLengthMm;
  final double maxFocalLengthMm;
  final double minFocusDistanceM;

  bool get isZoom => minFocalLengthMm != maxFocalLengthMm;

  String get focalLabel => isZoom
      ? '${minFocalLengthMm.toStringAsFixed(0)}-${maxFocalLengthMm.toStringAsFixed(0)}mm'
      : '${minFocalLengthMm.toStringAsFixed(0)}mm';

  String get apertureLabel {
    final wide = minApertureWide.toStringAsFixed(1);
    final tele = minApertureTele.toStringAsFixed(1);
    final max = maxAperture.toStringAsFixed(1);
    if (variableAperture && minApertureWide != minApertureTele) {
      return 'f/$wide-$tele to f/$max';
    }
    return 'f/$wide to f/$max';
  }

  String get displayLabel => '$name ($focalLabel, $apertureLabel)';

  double minApertureAtFocal(double focalMm) {
    final focal = focalMm.clamp(minFocalLengthMm, maxFocalLengthMm);
    if (!variableAperture || minFocalLengthMm == maxFocalLengthMm) {
      return minApertureWide;
    }
    final t =
        (focal - minFocalLengthMm) / (maxFocalLengthMm - minFocalLengthMm);
    return minApertureWide + (minApertureTele - minApertureWide) * t;
  }

  Lens copyWith({
    int? id,
    String? name,
    double? minApertureWide,
    double? minApertureTele,
    double? maxAperture,
    bool? variableAperture,
    double? minFocalLengthMm,
    double? maxFocalLengthMm,
    double? minFocusDistanceM,
  }) {
    return Lens(
      id: id ?? this.id,
      name: name ?? this.name,
      minApertureWide: minApertureWide ?? this.minApertureWide,
      minApertureTele: minApertureTele ?? this.minApertureTele,
      maxAperture: maxAperture ?? this.maxAperture,
      variableAperture: variableAperture ?? this.variableAperture,
      minFocalLengthMm: minFocalLengthMm ?? this.minFocalLengthMm,
      maxFocalLengthMm: maxFocalLengthMm ?? this.maxFocalLengthMm,
      minFocusDistanceM: minFocusDistanceM ?? this.minFocusDistanceM,
    );
  }

  factory Lens.fromMap(Map<String, Object?> map) {
    final wide = (map['min_aperture'] as num).toDouble();
    final tele = ((map['min_aperture_tele'] as num?) ?? wide).toDouble();
    final variable = ((map['variable_aperture'] as num?) ?? 0) == 1;

    return Lens(
      id: map['id'] as int,
      name: map['name'] as String,
      minApertureWide: wide,
      minApertureTele: tele,
      maxAperture: (map['max_aperture'] as num).toDouble(),
      variableAperture: variable,
      minFocalLengthMm: (map['min_focal_mm'] as num).toDouble(),
      maxFocalLengthMm: (map['max_focal_mm'] as num).toDouble(),
      minFocusDistanceM: ((map['min_focus_m'] as num?) ?? 0.3).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'min_aperture': minApertureWide,
      'min_aperture_tele': minApertureTele,
      'max_aperture': maxAperture,
      'variable_aperture': variableAperture ? 1 : 0,
      'min_focal_mm': minFocalLengthMm,
      'max_focal_mm': maxFocalLengthMm,
      // Kept for backward schema compatibility; no longer user-configured.
      'default_focal_mm': minFocalLengthMm,
      'min_focus_m': minFocusDistanceM,
    };
  }
}
