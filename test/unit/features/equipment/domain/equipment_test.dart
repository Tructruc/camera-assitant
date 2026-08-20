import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 19);
  const provenance = EquipmentProvenance(source: EquipmentSource.user);

  test('camera validates dimensions and normalizes its active name', () {
    final camera = CameraBody(
      id: 'camera-1',
      name: '  Full   Frame  ',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(camera.name, 'Full Frame');
    expect(camera.normalizedName, 'full frame');
    expect(camera.isArchived, isFalse);
    expect(
      () => CameraBody(
        id: 'camera-1',
        name: 'Invalid',
        sensorWidthMm: 0,
        sensorHeightMm: 24,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsA(isA<EquipmentValidationException>()),
    );
  });

  test('lens validates focal range and positive optional values', () {
    final lens = Lens(
      id: 'lens-1',
      name: '24–70 mm',
      minimumFocalLengthMm: 24,
      maximumFocalLengthMm: 70,
      minimumAperture: 2.8,
      minimumFocusDistanceMm: 380,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(lens.maximumFocalLengthMm, 70);
    expect(
      () => Lens(
        id: 'lens-2',
        name: 'Invalid zoom',
        minimumFocalLengthMm: 70,
        maximumFocalLengthMm: 24,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsA(isA<EquipmentValidationException>()),
    );
  });

  test('ND filter preserves equivalent stop, density, and factor sources', () {
    final filter = NdFilter(
      id: 'filter-1',
      name: 'ND 3 stops',
      strengthStops: 3,
      opticalDensity: 0.9,
      filterFactor: math.pow(2, 3).toDouble(),
      provenance: const EquipmentProvenance(
        source: EquipmentSource.userOverride,
        note: 'Measured value',
      ),
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(filter.provenance.note, 'Measured value');
    expect(filter.strengthStops, 3);
    expect(
      () => NdFilter(
        id: 'filter-2',
        name: 'Conflicting values',
        strengthStops: 3,
        opticalDensity: 3,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsA(isA<EquipmentValidationException>()),
    );
  });

  test('archive and restore preserve identity and provenance', () {
    final camera = CameraBody(
      id: 'camera-1',
      name: 'Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final archivedAt = DateTime.utc(2026, 8, 20);

    final archived = camera.archive(archivedAt);
    final restored = archived.restore(DateTime.utc(2026, 8, 21));

    expect(archived.isArchived, isTrue);
    expect(archived.archivedAt, archivedAt);
    expect(restored.isArchived, isFalse);
    expect(restored.id, camera.id);
    expect(restored.provenance, camera.provenance);
  });

  test('timestamps must be UTC and identifiers must not be blank', () {
    expect(
      () => CameraBody(
        id: ' ',
        name: 'Camera',
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        provenance: provenance,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
      throwsA(isA<EquipmentValidationException>()),
    );
  });

  test('optical accessories preserve only their variant-specific value', () {
    final tube = OpticalAccessory(
      id: 'tube-1',
      name: '25 mm tube',
      kind: OpticalAccessoryKind.extensionTube,
      value: 25,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    final converter = OpticalAccessory(
      id: 'tc-1',
      name: '1.4× converter',
      kind: OpticalAccessoryKind.teleconverter,
      value: 1.4,
      provenance: provenance,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    expect(tube.extensionLengthMm, 25);
    expect(tube.magnificationFactor, isNull);
    expect(converter.extensionLengthMm, isNull);
    expect(converter.magnificationFactor, 1.4);
    expect(
      () => OpticalAccessory(
        id: 'bad',
        name: 'Invalid converter',
        kind: OpticalAccessoryKind.teleconverter,
        value: 0.8,
        provenance: provenance,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      throwsA(isA<EquipmentValidationException>()),
    );
  });
}
