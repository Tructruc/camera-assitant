import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart';

void main() {
  const calculator = PanoramaCalculator();

  test('plans a single horizontal row with minimum covering frames', () {
    final result = calculator.calculate(
      const PanoramaInput(
        sensorWidthMm: 36,
        sensorHeightMm: 24,
        focalLengthMm: 50,
        orientation: CameraOrientation.landscape,
        horizontalBoundsDegrees: 90,
        verticalBoundsDegrees: 20,
        horizontalOverlapPercent: 30,
        verticalOverlapPercent: 30,
      ),
    );

    expect(result.errors, isEmpty);
    expect(result.output!.columns, 3);
    expect(result.output!.rows, 1);
    expect(result.output!.frameCount, 3);
    expect(result.output!.horizontalIncrementDegrees, closeTo(27.718, 0.001));
    expect(result.output!.horizontalCoverageDegrees, greaterThanOrEqualTo(90));
  });

  test(
    'portrait orientation swaps frame axes and creates a multi-row grid',
    () {
      final result = calculator.calculate(
        const PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.portrait,
          horizontalBoundsDegrees: 100,
          verticalBoundsDegrees: 60,
          horizontalOverlapPercent: 25,
          verticalOverlapPercent: 25,
        ),
      );

      final output = result.output!;
      expect(output.frameHorizontalDegrees, closeTo(26.991, 0.001));
      expect(output.frameVerticalDegrees, closeTo(39.598, 0.001));
      expect(output.columns, 5);
      expect(output.rows, 2);
      expect(output.frames, hasLength(10));
      expect(
        output.frames.map((frame) => frame.captureIndex),
        orderedEquals(List.generate(10, (i) => i + 1)),
      );
      expect(output.frames[5].column, 4); // second row reverses direction
    },
  );

  test('one frame covers bounds smaller than the lens field of view', () {
    final output = calculator
        .calculate(
          const PanoramaInput(
            sensorWidthMm: 36,
            sensorHeightMm: 24,
            focalLengthMm: 24,
            orientation: CameraOrientation.landscape,
            horizontalBoundsDegrees: 20,
            verticalBoundsDegrees: 10,
            horizontalOverlapPercent: 40,
            verticalOverlapPercent: 40,
          ),
        )
        .output!;
    expect((output.columns, output.rows, output.frameCount), (1, 1, 1));
    expect(output.frames.single.yawDegrees, 0);
    expect(output.frames.single.pitchDegrees, 0);
  });

  test('rejects impossible bounds, overlap, and optical inputs', () {
    final result = calculator.calculate(
      const PanoramaInput(
        sensorWidthMm: 0,
        sensorHeightMm: 24,
        focalLengthMm: 50,
        orientation: CameraOrientation.landscape,
        horizontalBoundsDegrees: 361,
        verticalBoundsDegrees: 181,
        horizontalOverlapPercent: 100,
        verticalOverlapPercent: -1,
      ),
    );
    expect(result.output, isNull);
    expect(
      result.errors.map((error) => error.field),
      containsAll(<String>[
        'sensorWidthMm',
        'horizontalBoundsDegrees',
        'verticalBoundsDegrees',
        'horizontalOverlapPercent',
        'verticalOverlapPercent',
      ]),
    );
  });
}
