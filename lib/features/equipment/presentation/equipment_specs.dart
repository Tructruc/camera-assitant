/// Recognizable specifications for saved equipment.
///
/// Inventory rows and the editor both describe the same physical gear, so the
/// standard sensor formats and the number formatting live here once instead of
/// drifting apart in two screens.
library;

import '../domain/equipment.dart';
import 'equipment_controller.dart';

/// The standard sensor formats a photographer recognizes, as the exact
/// physical size the editor preset writes. Ordered largest first.
const List<(String, double, double)> sensorFormats = <(String, double, double)>[
  ('Medium', 44, 33),
  ('Full frame', 36, 24),
  ('APS-H', 28.7, 19),
  ('APS-C', 23.6, 15.7),
  ('Canon APS-C', 22.3, 14.9),
  ('MFT', 17.3, 13),
  ('1 inch', 13.2, 8.8),
];

/// The name of the format a sensor pair is, or `null` when the dimensions are
/// not one of the standard sizes. The tolerance absorbs rounded catalogue
/// figures without mislabelling a genuinely different sensor.
String? sensorFormatName(double widthMm, double heightMm) {
  for (final (name, width, height) in sensorFormats) {
    if ((widthMm - width).abs() <= 0.6 && (heightMm - height).abs() <= 0.6) {
      return name;
    }
  }
  return null;
}

/// A number as a photographer writes it: `36`, `23.5`, `0.03`.
String equipmentNumber(double value) {
  if (!value.isFinite) return '$value';
  final fixed = value.toStringAsFixed(3);
  final trimmed = fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return trimmed.isEmpty ? '0' : trimmed;
}

/// The photographer's own note for an item, or `null` when it has none. The
/// field lives on each concrete kind, so it is read once here.
String? equipmentNotes(EquipmentItem item) => switch (item) {
  CameraBody(notes: final notes) => notes,
  Lens(notes: final notes) => notes,
  NdFilter(notes: final notes) => notes,
  OpticalAccessory(notes: final notes) => notes,
  _ => null,
};

/// One compact line of the specifications that make this item recognizable, or
/// `null` when the stored item carries nothing worth summarizing.
String? equipmentSpecSummary(EquipmentListEntry entry) => switch (entry.item) {
  final CameraBody camera => cameraSpecSummary(camera),
  final Lens lens => lensSpecSummary(lens),
  final NdFilter filter => filterSpecSummary(filter),
  final OpticalAccessory accessory => accessorySpecSummary(accessory),
  _ => null,
};

String cameraSpecSummary(CameraBody camera) => <String>[
  ?sensorFormatName(camera.sensorWidthMm, camera.sensorHeightMm),
  '${equipmentNumber(camera.sensorWidthMm)} × '
      '${equipmentNumber(camera.sensorHeightMm)} mm',
  if (camera.defaultCircleOfConfusionMm case final coc?)
    'CoC ${equipmentNumber(coc)} mm',
].join(' · ');

String lensSpecSummary(Lens lens) => <String>[
  lens.minimumFocalLengthMm == lens.maximumFocalLengthMm
      ? '${equipmentNumber(lens.minimumFocalLengthMm)} mm'
      : '${equipmentNumber(lens.minimumFocalLengthMm)}–'
            '${equipmentNumber(lens.maximumFocalLengthMm)} mm',
  if (lens.minimumAperture case final aperture?)
    'f/${equipmentNumber(aperture)}',
  if (lens.minimumFocusDistanceMm case final distance?)
    'closest ${equipmentNumber(distance)} mm',
].join(' · ');

String filterSpecSummary(NdFilter filter) => <String>[
  '${equipmentNumber(filter.strengthStops)} '
      '${filter.strengthStops == 1 ? 'stop' : 'stops'}',
  if (filter.opticalDensity case final density?)
    'OD ${equipmentNumber(density)}',
  if (filter.filterFactor case final factor?) '×${equipmentNumber(factor)}',
].join(' · ');

String accessorySpecSummary(OpticalAccessory accessory) =>
    switch (accessory.kind) {
      OpticalAccessoryKind.extensionTube =>
        'Extension tube · ${equipmentNumber(accessory.value)} mm',
      OpticalAccessoryKind.teleconverter =>
        'Teleconverter · ${equipmentNumber(accessory.value)}×',
    };
