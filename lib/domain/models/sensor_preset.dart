class SensorPreset {
  const SensorPreset(this.name, this.cocMm);
  final String name;
  final double cocMm;
}

const sensorPresets = [
  SensorPreset('Full Frame (CoC 0.030 mm)', 0.030),
  SensorPreset('APS-C Canon (CoC 0.019 mm)', 0.019),
  SensorPreset('APS-C Nikon/Sony (CoC 0.020 mm)', 0.020),
  SensorPreset('Micro Four Thirds (CoC 0.015 mm)', 0.015),
  SensorPreset('1-inch (CoC 0.011 mm)', 0.011),
];
