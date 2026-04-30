enum LensFocusType { manual, autofocus, both }

enum LensStabilization { none, optical, hybrid }

enum LensOwnershipStatus { owned, sold, loaned, lost, broken, archived }

enum LensCondition {
  newInBox,
  likeNew,
  excellent,
  veryGood,
  good,
  fair,
  wellUsed,
  forParts,
}

extension LensFocusTypeLabel on LensFocusType {
  String get label => switch (this) {
        LensFocusType.manual => 'Manual',
        LensFocusType.autofocus => 'Autofocus',
        LensFocusType.both => 'Manual + autofocus',
      };
}

extension LensStabilizationLabel on LensStabilization {
  String get label => switch (this) {
        LensStabilization.none => 'None',
        LensStabilization.optical => 'Optical',
        LensStabilization.hybrid => 'Hybrid',
      };
}

extension LensOwnershipStatusLabel on LensOwnershipStatus {
  String get label => switch (this) {
        LensOwnershipStatus.owned => 'Owned',
        LensOwnershipStatus.sold => 'Sold',
        LensOwnershipStatus.loaned => 'Loaned',
        LensOwnershipStatus.lost => 'Lost',
        LensOwnershipStatus.broken => 'Broken',
        LensOwnershipStatus.archived => 'Archived',
      };
}

extension LensConditionLabel on LensCondition {
  String get label => switch (this) {
        LensCondition.newInBox => 'New',
        LensCondition.likeNew => 'Like new',
        LensCondition.excellent => 'Excellent',
        LensCondition.veryGood => 'Very good',
        LensCondition.good => 'Good',
        LensCondition.fair => 'Fair',
        LensCondition.wellUsed => 'Well used',
        LensCondition.forParts => 'For parts',
      };
}

class Lens {
  const Lens({
    this.id,
    required this.name,
    this.brand,
    this.model,
    this.serialNumber,
    this.mount,
    required this.minApertureWide,
    required this.minApertureTele,
    required this.maxAperture,
    required this.variableAperture,
    required this.minFocalLengthMm,
    required this.maxFocalLengthMm,
    required this.minFocusDistanceM,
    this.filterThreadMm,
    this.apertureBlades,
    this.focusType = LensFocusType.manual,
    this.stabilization = LensStabilization.none,
    this.weightG,
    this.lengthMm,
    this.diameterMm,
    this.notes,
    this.purchaseDate,
    this.purchasePrice,
    this.condition,
    this.ownershipStatus = LensOwnershipStatus.owned,
  });

  final int? id;
  final String name;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? mount;

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
  final double? filterThreadMm;
  final int? apertureBlades;
  final LensFocusType focusType;
  final LensStabilization stabilization;
  final double? weightG;
  final double? lengthMm;
  final double? diameterMm;
  final String? notes;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final LensCondition? condition;
  final LensOwnershipStatus ownershipStatus;

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

  String get identityLabel {
    final parts = [brand, model].whereType<String>().where((s) => s.isNotEmpty);
    final joined = parts.join(' ');
    return joined.isEmpty ? name : joined;
  }

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
    String? brand,
    String? model,
    String? serialNumber,
    String? mount,
    double? minApertureWide,
    double? minApertureTele,
    double? maxAperture,
    bool? variableAperture,
    double? minFocalLengthMm,
    double? maxFocalLengthMm,
    double? minFocusDistanceM,
    double? filterThreadMm,
    int? apertureBlades,
    LensFocusType? focusType,
    LensStabilization? stabilization,
    double? weightG,
    double? lengthMm,
    double? diameterMm,
    String? notes,
    DateTime? purchaseDate,
    double? purchasePrice,
    LensCondition? condition,
    LensOwnershipStatus? ownershipStatus,
  }) {
    return Lens(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      mount: mount ?? this.mount,
      minApertureWide: minApertureWide ?? this.minApertureWide,
      minApertureTele: minApertureTele ?? this.minApertureTele,
      maxAperture: maxAperture ?? this.maxAperture,
      variableAperture: variableAperture ?? this.variableAperture,
      minFocalLengthMm: minFocalLengthMm ?? this.minFocalLengthMm,
      maxFocalLengthMm: maxFocalLengthMm ?? this.maxFocalLengthMm,
      minFocusDistanceM: minFocusDistanceM ?? this.minFocusDistanceM,
      filterThreadMm: filterThreadMm ?? this.filterThreadMm,
      apertureBlades: apertureBlades ?? this.apertureBlades,
      focusType: focusType ?? this.focusType,
      stabilization: stabilization ?? this.stabilization,
      weightG: weightG ?? this.weightG,
      lengthMm: lengthMm ?? this.lengthMm,
      diameterMm: diameterMm ?? this.diameterMm,
      notes: notes ?? this.notes,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      condition: condition ?? this.condition,
      ownershipStatus: ownershipStatus ?? this.ownershipStatus,
    );
  }

  factory Lens.fromMap(Map<String, Object?> map) {
    final wide = (map['min_aperture'] as num).toDouble();
    final tele = ((map['min_aperture_tele'] as num?) ?? wide).toDouble();
    final variable = ((map['variable_aperture'] as num?) ?? 0) == 1;

    return Lens(
      id: map['id'] as int?,
      name: map['name'] as String,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      mount: map['mount'] as String?,
      minApertureWide: wide,
      minApertureTele: tele,
      maxAperture: (map['max_aperture'] as num).toDouble(),
      variableAperture: variable,
      minFocalLengthMm: (map['min_focal_mm'] as num).toDouble(),
      maxFocalLengthMm: (map['max_focal_mm'] as num).toDouble(),
      minFocusDistanceM: ((map['min_focus_m'] as num?) ?? 0.3).toDouble(),
      filterThreadMm: (map['filter_thread_mm'] as num?)?.toDouble(),
      apertureBlades: (map['aperture_blades'] as num?)?.toInt(),
      focusType: _focusTypeFromStorage(map['focus_type'] as String?) ??
          LensFocusType.manual,
      stabilization: _stabilizationFromStorage(
            map['stabilization'] as String?,
          ) ??
          LensStabilization.none,
      weightG: (map['weight_g'] as num?)?.toDouble(),
      lengthMm: (map['length_mm'] as num?)?.toDouble(),
      diameterMm: (map['diameter_mm'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      purchaseDate: _parseDate(map['purchase_date'] as String?),
      purchasePrice: (map['purchase_price'] as num?)?.toDouble(),
      condition: _conditionFromStorage(map['condition'] as String?),
      ownershipStatus: _ownershipStatusFromStorage(
            map['ownership_status'] as String?,
          ) ??
          LensOwnershipStatus.owned,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'serial_number': serialNumber,
      'mount': mount,
      'min_aperture': minApertureWide,
      'min_aperture_tele': minApertureTele,
      'max_aperture': maxAperture,
      'variable_aperture': variableAperture ? 1 : 0,
      'min_focal_mm': minFocalLengthMm,
      'max_focal_mm': maxFocalLengthMm,
      // Kept for backward schema compatibility; no longer user-configured.
      'default_focal_mm': minFocalLengthMm,
      'min_focus_m': minFocusDistanceM,
      'filter_thread_mm': filterThreadMm,
      'aperture_blades': apertureBlades,
      'focus_type': focusType.name,
      'stabilization': stabilization.name,
      'weight_g': weightG,
      'length_mm': lengthMm,
      'diameter_mm': diameterMm,
      'notes': notes,
      'purchase_date': _formatDate(purchaseDate),
      'purchase_price': purchasePrice,
      'condition': condition?.name,
      'ownership_status': ownershipStatus.name,
    };
  }

  static LensFocusType? _focusTypeFromStorage(String? value) {
    for (final item in LensFocusType.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }

  static LensStabilization? _stabilizationFromStorage(String? value) {
    for (final item in LensStabilization.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }

  static LensOwnershipStatus? _ownershipStatusFromStorage(String? value) {
    for (final item in LensOwnershipStatus.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }

  static LensCondition? _conditionFromStorage(String? value) {
    for (final item in LensCondition.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static String? _formatDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
