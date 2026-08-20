/// Offline timelapse sequence and delivery planning.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

final class TimelapseInput {
  const TimelapseInput({
    required this.intervalSeconds,
    required this.captureDurationSeconds,
    required this.playbackFps,
    required this.megabytesPerFrame,
    required this.startExposureSeconds,
    required this.endExposureSeconds,
  });

  final double intervalSeconds;
  final double captureDurationSeconds;
  final double playbackFps;
  final double megabytesPerFrame;
  final double startExposureSeconds;
  final double endExposureSeconds;
}

final class TimelapseOutput {
  const TimelapseOutput({
    required this.frameCount,
    required this.playbackDurationSeconds,
    required this.storageMegabytes,
    required this.exposureRampStops,
    required this.maximumDutyCycle,
  });

  final int frameCount;
  final double playbackDurationSeconds;
  final double storageMegabytes;
  final double exposureRampStops;
  final double maximumDutyCycle;
}

final class TimelapseCalculator {
  const TimelapseCalculator();

  static const id = 'timelapse';
  static const version = 1;

  CalculationResult<TimelapseOutput> calculate(TimelapseInput input) {
    final errors = <ValidationError>[];
    for (final entry in <String, double>{
      'intervalSeconds': input.intervalSeconds,
      'captureDurationSeconds': input.captureDurationSeconds,
      'playbackFps': input.playbackFps,
      'megabytesPerFrame': input.megabytesPerFrame,
      'startExposureSeconds': input.startExposureSeconds,
      'endExposureSeconds': input.endExposureSeconds,
    }.entries) {
      if (!entry.value.isFinite || entry.value <= 0) {
        errors.add(
          ValidationError(
            field: entry.key,
            code: 'positive_finite_required',
            messageKey: 'timelapse.error.${entry.key}',
          ),
        );
      }
    }
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final frameCount =
        (input.captureDurationSeconds / input.intervalSeconds).floor() + 1;
    final maximumExposure = math.max(
      input.startExposureSeconds,
      input.endExposureSeconds,
    );
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: TimelapseOutput(
        frameCount: frameCount,
        playbackDurationSeconds: frameCount / input.playbackFps,
        storageMegabytes: frameCount * input.megabytesPerFrame,
        exposureRampStops:
            math.log(input.endExposureSeconds / input.startExposureSeconds) /
            math.ln2,
        maximumDutyCycle: maximumExposure / input.intervalSeconds,
      ),
      assumptions: const [
        CalculationAssumption(key: 'schedule', value: 'inclusiveEndpoints'),
        CalculationAssumption(key: 'frameSize', value: 'constantEstimate'),
        CalculationAssumption(key: 'processingGap', value: 'notModeled'),
      ],
      warnings: maximumExposure >= input.intervalSeconds
          ? const [
              CalculationWarning(
                code: 'exposure_exceeds_interval',
                messageKey: 'timelapse.warning.exposureInterval',
              ),
            ]
          : const [],
    );
  }
}
