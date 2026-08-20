import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/timelapse/domain/timelapse_calculator.dart';

void main() {
  const calculator = TimelapseCalculator();

  test('plans an inclusive one-hour ten-second sequence', () {
    final result = calculator.calculate(
      const TimelapseInput(
        intervalSeconds: 10,
        captureDurationSeconds: 3600,
        playbackFps: 30,
        megabytesPerFrame: 25,
        startExposureSeconds: 1,
        endExposureSeconds: 4,
      ),
    );
    final output = result.output!;
    expect(output.frameCount, 361);
    expect(output.playbackDurationSeconds, closeTo(12.033333, 1e-6));
    expect(output.storageMegabytes, 9025);
    expect(output.exposureRampStops, closeTo(2, 1e-12));
    expect(output.maximumDutyCycle, closeTo(0.4, 1e-12));
  });

  test('warns when the longest exposure exceeds the interval', () {
    final result = calculator.calculate(
      const TimelapseInput(
        intervalSeconds: 5,
        captureDurationSeconds: 60,
        playbackFps: 24,
        megabytesPerFrame: 10,
        startExposureSeconds: 2,
        endExposureSeconds: 8,
      ),
    );
    expect(result.status, CalculationStatus.validWithWarning);
    expect(result.warnings.single.code, 'exposure_exceeds_interval');
  });

  test('validates all input fields and exposure ramp endpoints', () {
    final result = calculator.calculate(
      const TimelapseInput(
        intervalSeconds: 0,
        captureDurationSeconds: -1,
        playbackFps: double.infinity,
        megabytesPerFrame: 0,
        startExposureSeconds: -2,
        endExposureSeconds: 0,
      ),
    );
    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.map((error) => error.field), [
      'intervalSeconds',
      'captureDurationSeconds',
      'playbackFps',
      'megabytesPerFrame',
      'startExposureSeconds',
      'endExposureSeconds',
    ]);
  });
}
