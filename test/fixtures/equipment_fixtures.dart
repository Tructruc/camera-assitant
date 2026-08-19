/// Deterministic equipment fixtures shared by unit and integration journeys.
library;

import 'package:photography_assistant/features/equipment/domain/equipment.dart';

final DateTime equipmentFixtureTime = DateTime.utc(2026, 8, 19, 10);

CameraBody fullFrameCameraFixture({String id = 'camera-full-frame'}) =>
    CameraBody(
      id: id,
      name: 'Full Frame Camera',
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      defaultCircleOfConfusionMm: 0.03,
      provenance: const EquipmentProvenance(
        source: EquipmentSource.userOverride,
        note: 'Manufacturer specification',
      ),
      createdAt: equipmentFixtureTime,
      updatedAt: equipmentFixtureTime,
    );

Lens standardZoomFixture({String id = 'lens-standard-zoom'}) => Lens(
  id: id,
  name: '24-70 mm f/2.8',
  minimumFocalLengthMm: 24,
  maximumFocalLengthMm: 70,
  minimumAperture: 2.8,
  maximumFocalLengthMinimumAperture: 2.8,
  minimumFocusDistanceMm: 380,
  provenance: const EquipmentProvenance(source: EquipmentSource.user),
  createdAt: equipmentFixtureTime,
  updatedAt: equipmentFixtureTime,
);
