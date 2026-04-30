class SensorPreset {
  const SensorPreset({
    required this.id,
    required this.label,
    required this.cocMm,
    required this.widthMm,
    required this.heightMm,
  });

  final String id;
  final String label;
  final double cocMm;
  final double widthMm;
  final double heightMm;

  String get displayName => '$label (CoC ${cocMm.toStringAsFixed(3)} mm)';
}

const sensorPresets = [
  SensorPreset(
    id: 'full_frame',
    label: 'Full Frame',
    cocMm: 0.030,
    widthMm: 36.0,
    heightMm: 24.0,
  ),
  SensorPreset(
    id: 'aps_c_canon',
    label: 'APS-C Canon',
    cocMm: 0.019,
    widthMm: 22.3,
    heightMm: 14.9,
  ),
  SensorPreset(
    id: 'aps_c_nikon_sony',
    label: 'APS-C Nikon/Sony',
    cocMm: 0.020,
    widthMm: 23.5,
    heightMm: 15.6,
  ),
  SensorPreset(
    id: 'micro_four_thirds',
    label: 'Micro Four Thirds',
    cocMm: 0.015,
    widthMm: 17.3,
    heightMm: 13.0,
  ),
  SensorPreset(
    id: 'one_inch',
    label: '1-inch',
    cocMm: 0.011,
    widthMm: 13.2,
    heightMm: 8.8,
  ),
];

List<SensorPreset> resolveEnabledSensorPresets(Iterable<String> enabledIds) {
  final enabled = enabledIds.toSet();
  final filtered = sensorPresets
      .where((preset) => enabled.isEmpty || enabled.contains(preset.id))
      .toList(growable: false);
  return filtered.isEmpty ? sensorPresets : filtered;
}
