class SensorPreset {
  const SensorPreset({
    required this.id,
    required this.label,
    required this.cocMm,
  });

  final String id;
  final String label;
  final double cocMm;

  String get displayName => '$label (CoC ${cocMm.toStringAsFixed(3)} mm)';
}

const sensorPresets = [
  SensorPreset(
    id: 'full_frame',
    label: 'Full Frame',
    cocMm: 0.030,
  ),
  SensorPreset(
    id: 'aps_c_canon',
    label: 'APS-C Canon',
    cocMm: 0.019,
  ),
  SensorPreset(
    id: 'aps_c_nikon_sony',
    label: 'APS-C Nikon/Sony',
    cocMm: 0.020,
  ),
  SensorPreset(
    id: 'micro_four_thirds',
    label: 'Micro Four Thirds',
    cocMm: 0.015,
  ),
  SensorPreset(
    id: 'one_inch',
    label: '1-inch',
    cocMm: 0.011,
  ),
];

List<SensorPreset> resolveEnabledSensorPresets(Iterable<String> enabledIds) {
  final enabled = enabledIds.toSet();
  final filtered = sensorPresets
      .where((preset) => enabled.isEmpty || enabled.contains(preset.id))
      .toList(growable: false);
  return filtered.isEmpty ? sensorPresets : filtered;
}
