/// Rectilinear panorama frame-grid planning in angular coordinates.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

enum CameraOrientation { landscape, portrait }

final class PanoramaInput {
  const PanoramaInput({
    required this.sensorWidthMm,
    required this.sensorHeightMm,
    required this.focalLengthMm,
    required this.orientation,
    required this.horizontalBoundsDegrees,
    required this.verticalBoundsDegrees,
    required this.horizontalOverlapPercent,
    required this.verticalOverlapPercent,
  });

  final double sensorWidthMm;
  final double sensorHeightMm;
  final double focalLengthMm;
  final CameraOrientation orientation;
  final double horizontalBoundsDegrees;
  final double verticalBoundsDegrees;
  final double horizontalOverlapPercent;
  final double verticalOverlapPercent;
}

final class PanoramaFrame {
  const PanoramaFrame({
    required this.captureIndex,
    required this.row,
    required this.column,
    required this.yawDegrees,
    required this.pitchDegrees,
  });
  final int captureIndex;
  final int row;
  final int column;
  final double yawDegrees;
  final double pitchDegrees;
}

final class PanoramaOutput {
  const PanoramaOutput({
    required this.columns,
    required this.rows,
    required this.frameHorizontalDegrees,
    required this.frameVerticalDegrees,
    required this.horizontalIncrementDegrees,
    required this.verticalIncrementDegrees,
    required this.horizontalCoverageDegrees,
    required this.verticalCoverageDegrees,
    required this.frames,
  });
  final int columns;
  final int rows;
  final double frameHorizontalDegrees;
  final double frameVerticalDegrees;
  final double horizontalIncrementDegrees;
  final double verticalIncrementDegrees;
  final double horizontalCoverageDegrees;
  final double verticalCoverageDegrees;
  final List<PanoramaFrame> frames;
  int get frameCount => rows * columns;
}

final class PanoramaCalculator {
  const PanoramaCalculator();
  static const id = 'panorama';
  static const version = 1;

  CalculationResult<PanoramaOutput> calculate(PanoramaInput input) {
    final errors = <ValidationError>[
      ..._positive('sensorWidthMm', input.sensorWidthMm),
      ..._positive('sensorHeightMm', input.sensorHeightMm),
      ..._positive('focalLengthMm', input.focalLengthMm),
      ..._boundedPositive(
        'horizontalBoundsDegrees',
        input.horizontalBoundsDegrees,
        360,
      ),
      ..._boundedPositive(
        'verticalBoundsDegrees',
        input.verticalBoundsDegrees,
        180,
      ),
      ..._overlap('horizontalOverlapPercent', input.horizontalOverlapPercent),
      ..._overlap('verticalOverlapPercent', input.verticalOverlapPercent),
    ];
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    double fieldOfView(double sensorSize) =>
        2 * math.atan(sensorSize / (2 * input.focalLengthMm)) * 180 / math.pi;
    final horizontalSensor = input.orientation == CameraOrientation.landscape
        ? input.sensorWidthMm
        : input.sensorHeightMm;
    final verticalSensor = input.orientation == CameraOrientation.landscape
        ? input.sensorHeightMm
        : input.sensorWidthMm;
    final frameHorizontal = fieldOfView(horizontalSensor);
    final frameVertical = fieldOfView(verticalSensor);
    final horizontalIncrement =
        frameHorizontal * (1 - input.horizontalOverlapPercent / 100);
    final verticalIncrement =
        frameVertical * (1 - input.verticalOverlapPercent / 100);
    int count(double bounds, double frame, double increment) =>
        bounds <= frame ? 1 : ((bounds - frame) / increment).ceil() + 1;
    final columns = count(
      input.horizontalBoundsDegrees,
      frameHorizontal,
      horizontalIncrement,
    );
    final rows = count(
      input.verticalBoundsDegrees,
      frameVertical,
      verticalIncrement,
    );
    final horizontalCoverage =
        frameHorizontal + (columns - 1) * horizontalIncrement;
    final verticalCoverage = frameVertical + (rows - 1) * verticalIncrement;
    final frames = <PanoramaFrame>[];
    for (var row = 0; row < rows; row++) {
      for (var step = 0; step < columns; step++) {
        final column = row.isEven ? step : columns - step - 1;
        frames.add(
          PanoramaFrame(
            captureIndex: frames.length + 1,
            row: row,
            column: column,
            yawDegrees: (column - (columns - 1) / 2) * horizontalIncrement,
            pitchDegrees: ((rows - 1) / 2 - row) * verticalIncrement,
          ),
        );
      }
    }
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: PanoramaOutput(
        columns: columns,
        rows: rows,
        frameHorizontalDegrees: frameHorizontal,
        frameVerticalDegrees: frameVertical,
        horizontalIncrementDegrees: horizontalIncrement,
        verticalIncrementDegrees: verticalIncrement,
        horizontalCoverageDegrees: horizontalCoverage,
        verticalCoverageDegrees: verticalCoverage,
        frames: List.unmodifiable(frames),
      ),
      assumptions: const [
        CalculationAssumption(key: 'projection', value: 'rectilinear'),
        CalculationAssumption(key: 'rotation', value: 'lensEntrancePupil'),
        CalculationAssumption(key: 'ordering', value: 'serpentineTopToBottom'),
      ],
      warnings: const [
        CalculationWarning(
          code: 'distortion',
          messageKey: 'panorama.warning.distortionAndCropping',
        ),
      ],
    );
  }
}

List<ValidationError> _positive(String field, double value) =>
    value.isFinite && value > 0 ? const [] : [_error(field, 'positive')];

List<ValidationError> _boundedPositive(
  String field,
  double value,
  double maximum,
) => value.isFinite && value > 0 && value <= maximum
    ? const []
    : [_error(field, 'range')];

List<ValidationError> _overlap(String field, double value) =>
    value.isFinite && value >= 0 && value < 100
    ? const []
    : [_error(field, 'overlap')];

ValidationError _error(String field, String code) => ValidationError(
  field: field,
  code: code,
  messageKey: 'panorama.error.$field',
);
