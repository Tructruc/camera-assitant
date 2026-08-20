/// Validated, immutable equipment entities and lifecycle operations.
library;

import 'dart:math' as math;

import '../../../core/domain/validation/validation.dart';

enum EquipmentSource { user, bundled, userOverride }

final class EquipmentProvenance {
  const EquipmentProvenance({required this.source, this.note});
  final EquipmentSource source;
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is EquipmentProvenance &&
      other.source == source &&
      other.note == note;

  @override
  int get hashCode => Object.hash(source, note);
}

final class EquipmentValidationException implements Exception {
  EquipmentValidationException(this.errors)
    : assert(errors.isNotEmpty, 'At least one error is required');
  final List<ValidationError> errors;

  @override
  String toString() =>
      'Invalid equipment: ${errors.map((e) => e.field).join(', ')}';
}

abstract base class EquipmentItem {
  EquipmentItem({
    required String id,
    required String name,
    required this.provenance,
    required this.createdAt,
    required this.updatedAt,
    required this.archivedAt,
  }) : id = _requiredText(id, 'id'),
       name = _displayName(name),
       normalizedName = _normalizeName(name) {
    _validateUtc(createdAt, 'createdAt');
    _validateUtc(updatedAt, 'updatedAt');
    if (archivedAt case final value?) {
      _validateUtc(value, 'archivedAt');
    }
    if (updatedAt.isBefore(createdAt)) {
      _fail('updatedAt', 'chronology');
    }
  }

  final String id;
  final String name;
  final String normalizedName;
  final EquipmentProvenance provenance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;

  bool get isArchived => archivedAt != null;
}

final class CameraBody extends EquipmentItem {
  CameraBody({
    required super.id,
    required super.name,
    required double sensorWidthMm,
    required double sensorHeightMm,
    required super.provenance,
    required super.createdAt,
    required super.updatedAt,
    double? defaultCircleOfConfusionMm,
    super.archivedAt,
  }) : sensorWidthMm = _positive(sensorWidthMm, 'sensorWidthMm'),
       sensorHeightMm = _positive(sensorHeightMm, 'sensorHeightMm'),
       defaultCircleOfConfusionMm = _optionalPositive(
         defaultCircleOfConfusionMm,
         'defaultCircleOfConfusionMm',
       );

  final double sensorWidthMm;
  final double sensorHeightMm;
  final double? defaultCircleOfConfusionMm;

  CameraBody archive(DateTime at) => _copy(archivedAt: _lifecycleTime(at));

  CameraBody restore(DateTime at) =>
      _copy(archivedAt: null, updatedAt: _lifecycleTime(at));

  CameraBody _copy({DateTime? archivedAt, DateTime? updatedAt}) => CameraBody(
    id: id,
    name: name,
    sensorWidthMm: sensorWidthMm,
    sensorHeightMm: sensorHeightMm,
    defaultCircleOfConfusionMm: defaultCircleOfConfusionMm,
    provenance: provenance,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt,
  );
}

final class Lens extends EquipmentItem {
  Lens({
    required super.id,
    required super.name,
    required double minimumFocalLengthMm,
    required double maximumFocalLengthMm,
    required super.provenance,
    required super.createdAt,
    required super.updatedAt,
    double? minimumAperture,
    double? maximumFocalLengthMinimumAperture,
    double? minimumFocusDistanceMm,
    this.notes,
    super.archivedAt,
  }) : minimumFocalLengthMm = _positive(
         minimumFocalLengthMm,
         'minimumFocalLengthMm',
       ),
       maximumFocalLengthMm = _focalMaximum(
         maximumFocalLengthMm,
         minimumFocalLengthMm,
       ),
       minimumAperture = _optionalPositive(minimumAperture, 'minimumAperture'),
       maximumFocalLengthMinimumAperture = _optionalPositive(
         maximumFocalLengthMinimumAperture,
         'maximumFocalLengthMinimumAperture',
       ),
       minimumFocusDistanceMm = _optionalPositive(
         minimumFocusDistanceMm,
         'minimumFocusDistanceMm',
       );

  final double minimumFocalLengthMm;
  final double maximumFocalLengthMm;
  final double? minimumAperture;
  final double? maximumFocalLengthMinimumAperture;
  final double? minimumFocusDistanceMm;
  final String? notes;

  Lens archive(DateTime at) => _copy(archivedAt: _lifecycleTime(at));
  Lens restore(DateTime at) =>
      _copy(archivedAt: null, updatedAt: _lifecycleTime(at));

  Lens _copy({DateTime? archivedAt, DateTime? updatedAt}) => Lens(
    id: id,
    name: name,
    minimumFocalLengthMm: minimumFocalLengthMm,
    maximumFocalLengthMm: maximumFocalLengthMm,
    minimumAperture: minimumAperture,
    maximumFocalLengthMinimumAperture: maximumFocalLengthMinimumAperture,
    minimumFocusDistanceMm: minimumFocusDistanceMm,
    notes: notes,
    provenance: provenance,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt,
  );
}

final class NdFilter extends EquipmentItem {
  NdFilter({
    required super.id,
    required super.name,
    required double strengthStops,
    required super.provenance,
    required super.createdAt,
    required super.updatedAt,
    double? opticalDensity,
    double? filterFactor,
    this.notes,
    super.archivedAt,
  }) : strengthStops = _nonNegative(strengthStops, 'strengthStops'),
       opticalDensity = _consistentDensity(opticalDensity, strengthStops),
       filterFactor = _consistentFactor(filterFactor, strengthStops);

  final double strengthStops;
  final double? opticalDensity;
  final double? filterFactor;
  final String? notes;

  NdFilter archive(DateTime at) => _copy(archivedAt: _lifecycleTime(at));
  NdFilter restore(DateTime at) =>
      _copy(archivedAt: null, updatedAt: _lifecycleTime(at));

  NdFilter _copy({DateTime? archivedAt, DateTime? updatedAt}) => NdFilter(
    id: id,
    name: name,
    strengthStops: strengthStops,
    opticalDensity: opticalDensity,
    filterFactor: filterFactor,
    notes: notes,
    provenance: provenance,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    archivedAt: archivedAt,
  );
}

enum OpticalAccessoryKind { extensionTube, teleconverter }

final class OpticalAccessory extends EquipmentItem {
  OpticalAccessory({
    required super.id,
    required super.name,
    required this.kind,
    required double value,
    required super.provenance,
    required super.createdAt,
    required super.updatedAt,
    this.notes,
    super.archivedAt,
  }) : value = _accessoryValue(kind, value);

  final OpticalAccessoryKind kind;
  final double value;
  final String? notes;

  double? get extensionLengthMm =>
      kind == OpticalAccessoryKind.extensionTube ? value : null;
  double? get magnificationFactor =>
      kind == OpticalAccessoryKind.teleconverter ? value : null;

  OpticalAccessory archive(DateTime at) =>
      _copy(archivedAt: _lifecycleTime(at));
  OpticalAccessory restore(DateTime at) =>
      _copy(archivedAt: null, updatedAt: _lifecycleTime(at));

  OpticalAccessory _copy({DateTime? archivedAt, DateTime? updatedAt}) =>
      OpticalAccessory(
        id: id,
        name: name,
        kind: kind,
        value: value,
        notes: notes,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        archivedAt: archivedAt,
      );
}

String _requiredText(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    _fail(field, 'required');
  }
  return trimmed;
}

String _displayName(String value) {
  final required = _requiredText(value, 'name');
  return required.replaceAll(RegExp(r'\s+'), ' ');
}

String _normalizeName(String value) => _displayName(value).toLowerCase();

double _positive(double value, String field) {
  if (!value.isFinite || value <= 0) {
    _fail(field, 'positive');
  }
  return value;
}

double _nonNegative(double value, String field) {
  if (!value.isFinite || value < 0) {
    _fail(field, 'nonNegative');
  }
  return value;
}

double? _optionalPositive(double? value, String field) =>
    value == null ? null : _positive(value, field);

double _focalMaximum(double maximum, double minimum) {
  _positive(maximum, 'maximumFocalLengthMm');
  if (maximum < minimum) {
    _fail('maximumFocalLengthMm', 'range');
  }
  return maximum;
}

double _accessoryValue(OpticalAccessoryKind kind, double value) {
  _positive(value, 'value');
  if (kind == OpticalAccessoryKind.teleconverter && value < 1) {
    _fail('value', 'teleconverterRange');
  }
  return value;
}

double? _consistentDensity(double? density, double stops) {
  if (density == null) {
    return null;
  }
  _nonNegative(density, 'opticalDensity');
  if ((density * math.log(10) / math.ln2 - stops).abs() > 0.02) {
    _fail('opticalDensity', 'inconsistent');
  }
  return density;
}

double? _consistentFactor(double? factor, double stops) {
  if (factor == null) {
    return null;
  }
  _positive(factor, 'filterFactor');
  if ((math.log(factor) / math.ln2 - stops).abs() > 0.01) {
    _fail('filterFactor', 'inconsistent');
  }
  return factor;
}

void _validateUtc(DateTime value, String field) {
  if (!value.isUtc) {
    _fail(field, 'utc');
  }
}

DateTime _lifecycleTime(DateTime value) {
  _validateUtc(value, 'lifecycleTime');
  return value;
}

Never _fail(String field, String code) {
  throw EquipmentValidationException(<ValidationError>[
    ValidationError(
      field: field,
      code: code,
      messageKey: 'equipment.$field.$code',
    ),
  ]);
}
