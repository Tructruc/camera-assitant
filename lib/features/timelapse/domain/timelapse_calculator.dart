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

  /// Highest frame count this planner will plan for. Beyond it the frame
  /// counter stops being a plan and starts being an arithmetic artefact:
  /// `double.floor()` clamps at the 64-bit integer limit, so a larger quotient
  /// would otherwise silently wrap to a negative frame count.
  static const maximumPlannedFrames = 1000000;

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

    final frames = input.captureDurationSeconds / input.intervalSeconds;
    // An extreme ratio makes the quotient infinite, and floor() throws on a
    // non-finite value; a merely huge quotient clamps at the integer limit and
    // would wrap to a negative frame count. Both are field errors (FR-002).
    if (!frames.isFinite || frames > maximumPlannedFrames) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: const [
          ValidationError(
            field: 'intervalSeconds',
            code: 'result_out_of_range',
            messageKey: 'timelapse.error.resultOutOfRange',
          ),
        ],
      );
    }
    final frameCount = frames.floor() + 1;
    final maximumExposure = math.max(
      input.startExposureSeconds,
      input.endExposureSeconds,
    );
    final playbackDurationSeconds = frameCount / input.playbackFps;
    final storageMegabytes = frameCount * input.megabytesPerFrame;
    final exposureRampStops =
        math.log(input.endExposureSeconds / input.startExposureSeconds) /
        math.ln2;
    final maximumDutyCycle = maximumExposure / input.intervalSeconds;
    // A finite frame count can still overflow the derived playback, storage,
    // ramp, or duty-cycle figures; name the field that drives each (FR-002).
    final outOfRange = switch ((
      playbackDurationSeconds,
      storageMegabytes,
      exposureRampStops,
      maximumDutyCycle,
    )) {
      (final playback, _, _, _) when !playback.isFinite || playback <= 0 =>
        'playbackFps',
      (_, final storage, _, _) when !storage.isFinite || storage <= 0 =>
        'megabytesPerFrame',
      (_, _, final ramp, _) when !ramp.isFinite => 'endExposureSeconds',
      (_, _, _, final duty) when !duty.isFinite || duty <= 0 =>
        'intervalSeconds',
      _ => null,
    };
    if (outOfRange != null) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: [
          ValidationError(
            field: outOfRange,
            code: 'result_out_of_range',
            messageKey: 'timelapse.error.resultOutOfRange',
          ),
        ],
      );
    }
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: TimelapseOutput(
        frameCount: frameCount,
        playbackDurationSeconds: playbackDurationSeconds,
        storageMegabytes: storageMegabytes,
        exposureRampStops: exposureRampStops,
        maximumDutyCycle: maximumDutyCycle,
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
