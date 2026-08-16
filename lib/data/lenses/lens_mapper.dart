import 'package:camera_assistant/domain/models/lens.dart';

class LensMapper {
  LensMapper._();

  static Lens fromRow(Map<String, Object?> row) {
    final wide = (row['min_aperture'] as num).toDouble();
    final tele = ((row['min_aperture_tele'] as num?) ?? wide).toDouble();
    final variable = ((row['variable_aperture'] as num?) ?? 0) == 1;

    return Lens(
      id: row['id'] as int?,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      model: row['model'] as String?,
      serialNumber: row['serial_number'] as String?,
      mount: row['mount'] as String?,
      minApertureWide: wide,
      minApertureTele: tele,
      maxAperture: (row['max_aperture'] as num).toDouble(),
      variableAperture: variable,
      minFocalLengthMm: (row['min_focal_mm'] as num).toDouble(),
      maxFocalLengthMm: (row['max_focal_mm'] as num).toDouble(),
      minFocusDistanceM: ((row['min_focus_m'] as num?) ?? 0.3).toDouble(),
      filterThreadMm: (row['filter_thread_mm'] as num?)?.toDouble(),
      apertureBlades: (row['aperture_blades'] as num?)?.toInt(),
      focusType:
          _enumFromName(row['focus_type'] as String?, LensFocusType.values) ??
              LensFocusType.manual,
      stabilization: _enumFromName(
            row['stabilization'] as String?,
            LensStabilization.values,
          ) ??
          LensStabilization.none,
      weightG: (row['weight_g'] as num?)?.toDouble(),
      lengthMm: (row['length_mm'] as num?)?.toDouble(),
      diameterMm: (row['diameter_mm'] as num?)?.toDouble(),
      notes: row['notes'] as String?,
      purchaseDate: _parseDate(row['purchase_date'] as String?),
      purchasePrice: (row['purchase_price'] as num?)?.toDouble(),
      condition:
          _enumFromName(row['condition'] as String?, LensCondition.values),
      ownershipStatus: _enumFromName(
            row['ownership_status'] as String?,
            LensOwnershipStatus.values,
          ) ??
          LensOwnershipStatus.owned,
    );
  }

  static Map<String, Object?> toRow(Lens lens) {
    return {
      'id': lens.id,
      'name': lens.name,
      'brand': lens.brand,
      'model': lens.model,
      'serial_number': lens.serialNumber,
      'mount': lens.mount,
      'min_aperture': lens.minApertureWide,
      'min_aperture_tele': lens.minApertureTele,
      'max_aperture': lens.maxAperture,
      'variable_aperture': lens.variableAperture ? 1 : 0,
      'min_focal_mm': lens.minFocalLengthMm,
      'max_focal_mm': lens.maxFocalLengthMm,
      // Kept for backward schema compatibility; no longer user-configured.
      'default_focal_mm': lens.minFocalLengthMm,
      'min_focus_m': lens.minFocusDistanceM,
      'filter_thread_mm': lens.filterThreadMm,
      'aperture_blades': lens.apertureBlades,
      'focus_type': lens.focusType.name,
      'stabilization': lens.stabilization.name,
      'weight_g': lens.weightG,
      'length_mm': lens.lengthMm,
      'diameter_mm': lens.diameterMm,
      'notes': lens.notes,
      'purchase_date': _formatDate(lens.purchaseDate),
      'purchase_price': lens.purchasePrice,
      'condition': lens.condition?.name,
      'ownership_status': lens.ownershipStatus.name,
    };
  }

  static T? _enumFromName<T extends Enum>(String? value, List<T> values) {
    for (final item in values) {
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
