import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolveEnabledSensorPresets keeps the requested sensor order', () {
    final presets = resolveEnabledSensorPresets([
      'micro_four_thirds',
      'full_frame',
    ]);

    expect(
      presets.map((preset) => preset.id).toList(),
      ['full_frame', 'micro_four_thirds'],
    );
  });

  test('resolveEnabledSensorPresets falls back to all formats when empty', () {
    final presets = resolveEnabledSensorPresets(const []);

    expect(presets, hasLength(sensorPresets.length));
    expect(presets.first.id, sensorPresets.first.id);
  });

  test('resolveEnabledSensorPresets ignores unknown ids', () {
    final presets = resolveEnabledSensorPresets([
      'unknown',
      'aps_c_canon',
    ]);

    expect(
      presets.map((preset) => preset.id).toList(),
      ['aps_c_canon'],
    );
  });
}
