/// Immutable, versioned saved-calculation payloads.
library;

import 'validation/validation.dart';

enum SnapshotEquipmentType { camera, lens, filter }

final class UnsupportedSnapshotVersionException implements Exception {
  const UnsupportedSnapshotVersionException(this.version);
  final int version;

  @override
  String toString() => 'Unsupported snapshot payload version $version';
}

final class AppliedEquipmentSnapshot {
  AppliedEquipmentSnapshot({
    required this.id,
    required this.type,
    required this.name,
    required this.source,
    required Map<String, Object?> values,
    this.note,
  }) : values = _freezeMap(values) {
    _nonBlank(id, 'id');
    _nonBlank(name, 'name');
    _nonBlank(source, 'source');
  }

  final String id;
  final SnapshotEquipmentType type;
  final String name;
  final String source;
  final String? note;
  final Map<String, Object?> values;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'type': type.name,
    'name': name,
    'source': source,
    'note': note,
    'values': values,
  };

  // Kept beside toJson so the codec remains auditable as one block.
  // ignore: sort_constructors_first
  factory AppliedEquipmentSnapshot.fromJson(Map<String, Object?> json) {
    final typeName = _string(json, 'type');
    final type = SnapshotEquipmentType.values
        .where((value) => value.name == typeName)
        .firstOrNull;
    if (type == null) {
      throw FormatException('Unsupported equipment type: $typeName');
    }
    return AppliedEquipmentSnapshot(
      id: _string(json, 'id'),
      type: type,
      name: _string(json, 'name'),
      source: _string(json, 'source'),
      note: json['note'] as String?,
      values: _map(json['values'], 'values'),
    );
  }
}

final class CalculationSnapshot {
  CalculationSnapshot({
    required this.id,
    required this.calculatorId,
    required this.formulaVersion,
    required this.createdAt,
    required this.title,
    required Map<String, Object?> canonicalInputs,
    required Map<String, Object?> canonicalOutputs,
    required Map<String, Object?> displayContext,
    this.notes,
    this.payloadVersion = currentPayloadVersion,
    List<CalculationAssumption> assumptions = const [],
    List<CalculationWarning> warnings = const [],
    List<AppliedEquipmentSnapshot> equipment = const [],
  }) : canonicalInputs = _freezeMap(canonicalInputs),
       canonicalOutputs = _freezeMap(canonicalOutputs),
       displayContext = _freezeMap(displayContext),
       assumptions = List.unmodifiable(assumptions),
       warnings = List.unmodifiable(warnings),
       equipment = List.unmodifiable(equipment) {
    _validate();
  }

  CalculationSnapshot._preserved({
    required this.id,
    required this.calculatorId,
    required this.formulaVersion,
    required this.createdAt,
    required this.title,
    required this.notes,
    required this.payloadVersion,
    required this.canonicalInputs,
    required this.canonicalOutputs,
    required this.displayContext,
    required this.assumptions,
    required this.warnings,
    required this.equipment,
  });

  static const currentPayloadVersion = 1;

  final String id;
  final String calculatorId;
  final int formulaVersion;
  final DateTime createdAt;
  final String title;
  final String? notes;
  final int payloadVersion;
  final Map<String, Object?> canonicalInputs;
  final Map<String, Object?> canonicalOutputs;
  final Map<String, Object?> displayContext;
  final List<CalculationAssumption> assumptions;
  final List<CalculationWarning> warnings;
  final List<AppliedEquipmentSnapshot> equipment;

  CalculationSnapshot withMetadata({required String title, String? notes}) {
    _nonBlank(title, 'title');
    return CalculationSnapshot._preserved(
      id: id,
      calculatorId: calculatorId,
      formulaVersion: formulaVersion,
      createdAt: createdAt,
      title: title.trim(),
      notes: notes,
      payloadVersion: payloadVersion,
      canonicalInputs: canonicalInputs,
      canonicalOutputs: canonicalOutputs,
      displayContext: displayContext,
      assumptions: assumptions,
      warnings: warnings,
      equipment: equipment,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'calculatorId': calculatorId,
    'formulaVersion': formulaVersion,
    'createdAt': createdAt.toIso8601String(),
    'title': title,
    'notes': notes,
    'payloadVersion': payloadVersion,
    'canonicalInputs': canonicalInputs,
    'canonicalOutputs': canonicalOutputs,
    'displayContext': displayContext,
    'assumptions': [
      for (final item in assumptions) {'key': item.key, 'value': item.value},
    ],
    'warnings': [
      for (final item in warnings)
        {'code': item.code, 'messageKey': item.messageKey},
    ],
    'equipment': [for (final item in equipment) item.toJson()],
  };

  // Kept beside toJson so the codec remains auditable as one block.
  // ignore: sort_constructors_first
  factory CalculationSnapshot.fromJson(Map<String, Object?> json) {
    final payloadVersion = _integer(json, 'payloadVersion');
    if (payloadVersion != currentPayloadVersion) {
      throw UnsupportedSnapshotVersionException(payloadVersion);
    }
    return CalculationSnapshot(
      id: _string(json, 'id'),
      calculatorId: _string(json, 'calculatorId'),
      formulaVersion: _integer(json, 'formulaVersion'),
      createdAt: DateTime.parse(_string(json, 'createdAt')),
      title: _string(json, 'title'),
      notes: json['notes'] as String?,
      payloadVersion: payloadVersion,
      canonicalInputs: _map(json['canonicalInputs'], 'canonicalInputs'),
      canonicalOutputs: _map(json['canonicalOutputs'], 'canonicalOutputs'),
      displayContext: _map(json['displayContext'], 'displayContext'),
      assumptions: [
        for (final item in _list(json['assumptions'], 'assumptions'))
          CalculationAssumption(
            key: _string(_map(item, 'assumption'), 'key'),
            value: _string(_map(item, 'assumption'), 'value'),
          ),
      ],
      warnings: [
        for (final item in _list(json['warnings'], 'warnings'))
          CalculationWarning(
            code: _string(_map(item, 'warning'), 'code'),
            messageKey: _string(_map(item, 'warning'), 'messageKey'),
          ),
      ],
      equipment: [
        for (final item in _list(json['equipment'], 'equipment'))
          AppliedEquipmentSnapshot.fromJson(_map(item, 'equipment item')),
      ],
    );
  }

  void _validate() {
    _nonBlank(id, 'id');
    _nonBlank(calculatorId, 'calculatorId');
    _nonBlank(title, 'title');
    if (formulaVersion < 1) {
      throw ArgumentError.value(formulaVersion, 'formulaVersion');
    }
    if (payloadVersion != currentPayloadVersion) {
      throw UnsupportedSnapshotVersionException(payloadVersion);
    }
    if (!createdAt.isUtc) {
      throw ArgumentError.value(createdAt, 'createdAt', 'must be UTC');
    }
  }
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) =>
    Map.unmodifiable(source.map((key, value) => MapEntry(key, _freeze(value))));

Object? _freeze(Object? value) => switch (value) {
  Map<String, Object?>() => _freezeMap(value),
  List<Object?>() => List<Object?>.unmodifiable(value.map(_freeze)),
  null || String() || bool() => value,
  num() when value.isFinite => value,
  _ => throw ArgumentError.value(value, 'payload', 'must be JSON-compatible'),
};

Map<String, Object?> _map(Object? value, String field) {
  if (value is! Map<Object?, Object?>) {
    throw FormatException('$field must be an object');
  }
  return value.map((key, item) {
    if (key is! String) throw FormatException('$field keys must be strings');
    return MapEntry(key, item);
  });
}

List<Object?> _list(Object? value, String field) {
  if (value is! List<Object?>) throw FormatException('$field must be a list');
  return value;
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

int _integer(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

void _nonBlank(String value, String field) {
  if (value.trim().isEmpty) throw ArgumentError.value(value, field);
}
