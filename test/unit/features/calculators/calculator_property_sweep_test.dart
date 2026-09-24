import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/quantities/quantities.dart';
import 'package:photography_assistant/features/depth_of_field/domain/depth_of_field_calculator.dart';
import 'package:photography_assistant/features/optics/domain/optics_calculators.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart';
import 'package:photography_assistant/features/timelapse/domain/timelapse_calculator.dart';

/// Randomized property sweep across the calculators with the most arithmetic.
///
/// The per-calculator tests pin the cases somebody thought of. This pins the
/// rules that have to hold for *every* input the app accepts: a usable result
/// carries finite, self-consistent numbers, and an unusable one carries a
/// named error instead of a crash, a NaN or an infinity. The seed is fixed, so
/// a failure here is reproducible; the ranges are the ones the validators
/// document, spread logarithmically so the extremes get sampled as often as
/// the middle.
void main() {
  final random = math.Random(20260924);

  double logUniform(double min, double max) => min == 0
      ? random.nextDouble() * max
      : min * math.pow(max / min, random.nextDouble());

  void expectFinite(List<String> violations, String label, double value) {
    if (!value.isFinite) violations.add('$label is $value');
  }

  const samples = 500;

  test('depth of field stays finite and ordered for any accepted input', () {
    final violations = <String>[];
    for (var i = 0; i < samples; i++) {
      final focal = logUniform(4, 2000);
      final aperture = logUniform(0.7, 64);
      final coc = logUniform(0.005, 0.1);
      final focus = focal * (1.0001 + logUniform(0.0001, 1000));
      final input = DepthOfFieldInput(
        focalLengthMm: focal,
        aperture: aperture,
        focusDistanceMm: focus,
        circleOfConfusionMm: coc,
      );
      final context = 'focal=$focal N=$aperture coc=$coc focus=$focus';

      final result = const DepthOfFieldCalculator().calculate(input);
      if (!result.isUsable) {
        violations.add('rejected $context');
        continue;
      }

      final output = result.output!;
      final hyperfocal = output.hyperfocalDistance.millimetres;
      final near = output.nearLimit.millimetres;
      final far = output.farLimit.millimetres;
      expectFinite(violations, 'hyperfocal', hyperfocal);
      expectFinite(violations, 'near', near);
      expectFinite(violations, 'frontDepth', output.frontDepth.millimetres);
      if (hyperfocal < focal) violations.add('hyperfocal < focal $context');
      if (near > focus * 1.001) violations.add('near beyond focus $context');

      // Focusing at or beyond the hyperfocal distance is the documented way to
      // reach an infinite far limit: the rear depth and the total depth must be
      // infinite then, and finite before it. Anything else - a NaN, or an
      // infinity that arrives early - is a defect.
      final reachingInfinity = focus >= hyperfocal;
      for (final entry in <String, FocusDistance>{
        'far': output.farLimit,
        'rearDepth': output.rearDepth,
        'totalDepth': output.totalDepth,
      }.entries) {
        final value = entry.value;
        if (value.millimetres.isNaN) {
          violations.add('${entry.key} is NaN $context');
          continue;
        }
        if (value.isInfinite) {
          if (!reachingInfinity) {
            violations.add('${entry.key} infinite before hyperfocal $context');
          }
          continue;
        }
        if (reachingInfinity && entry.key != 'far') {
          violations.add('${entry.key} finite beyond hyperfocal $context');
        }
        if (entry.key == 'far') {
          if (far < near) violations.add('far before near $context');
          if (far < focus * 0.999) violations.add('far before focus $context');
        }
      }
    }
    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
  });

  test('optics stay finite and ordered for any accepted input', () {
    final violations = <String>[];
    for (var i = 0; i < samples; i++) {
      final focal = logUniform(4, 3000);
      final sensorWidth = logUniform(3.6, 100);
      final sensorHeight = sensorWidth / logUniform(1, 2.5);

      final fov = const FieldOfViewCalculator().calculate(
        FieldOfViewInput(
          sensorWidthMm: sensorWidth,
          sensorHeightMm: sensorHeight,
          focalLengthMm: focal,
          distanceMm: logUniform(1, 1e9),
        ),
      );
      if (!fov.isUsable) {
        violations.add('field of view rejected');
      } else {
        final output = fov.output!;
        expectFinite(violations, 'horizontal', output.horizontalDegrees);
        expectFinite(violations, 'vertical', output.verticalDegrees);
        expectFinite(violations, 'diagonal', output.diagonalDegrees);
        expectFinite(violations, 'sceneWidth', output.sceneWidthMm);
        expectFinite(violations, 'sceneHeight', output.sceneHeightMm);
        if (output.horizontalDegrees <= 0 || output.horizontalDegrees > 180) {
          violations.add('horizontal field ${output.horizontalDegrees}');
        }
        if (output.diagonalDegrees < output.horizontalDegrees) {
          violations.add('diagonal field below horizontal');
        }
      }

      final diffraction = const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: logUniform(0.7, 64),
          wavelengthNm: logUniform(300, 900),
          pixelPitchMicrometres: logUniform(0.8, 10),
        ),
      );
      if (!diffraction.isUsable) {
        violations.add('diffraction rejected');
      } else {
        final output = diffraction.output!;
        expectFinite(violations, 'airyDisk', output.airyDiskMicrometres);
        expectFinite(violations, 'airyRadius', output.airyRadiusMicrometres);
        expectFinite(violations, 'airyDiskPixels', output.airyDiskPixels);
        if (output.airyDiskMicrometres <= 0) violations.add('airy disk <= 0');
        if (output.airyRadiusMicrometres * 2 < output.airyDiskMicrometres) {
          violations.add('radius below half the disk');
        }
      }

      final near = focal * (1.01 + logUniform(0, 1000));
      final far = near * (1.001 + logUniform(0, 100));
      final stack = const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: focal,
          aperture: logUniform(0.7, 64),
          circleOfConfusionMm: logUniform(0.005, 0.1),
          nearDistanceMm: near,
          farDistanceMm: far,
          overlapPercent: logUniform(0, 99),
        ),
      );
      if (!stack.isUsable) {
        violations.add('focus stack rejected near=$near far=$far focal=$focal');
      } else {
        final distances = stack.output!.focusDistancesMm;
        if (distances.isEmpty) violations.add('focus stack empty');
        for (var index = 0; index < distances.length; index++) {
          expectFinite(violations, 'stack[$index]', distances[index]);
          if (index > 0 && distances[index] <= distances[index - 1]) {
            violations.add('stack distances not increasing at $index');
          }
        }
      }
    }
    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
  });

  test('panorama plans cover their bounds and stay internally consistent', () {
    final violations = <String>[];
    for (var i = 0; i < samples; i++) {
      final horizontal = logUniform(1, 360);
      final vertical = logUniform(1, 180);
      final input = PanoramaInput(
        sensorWidthMm: logUniform(3.6, 100),
        sensorHeightMm: logUniform(3.6, 100),
        focalLengthMm: logUniform(4, 3000),
        orientation: CameraOrientation
            .values[random.nextInt(CameraOrientation.values.length)],
        horizontalBoundsDegrees: horizontal,
        verticalBoundsDegrees: vertical,
        horizontalOverlapPercent: logUniform(0, 99),
        verticalOverlapPercent: logUniform(0, 99),
      );

      final result = const PanoramaCalculator().calculate(input);
      if (!result.isUsable) {
        // A plan that needs more frames than the solver will build is refused
        // on purpose; that refusal is only acceptable if it is named.
        final codes = result.errors.map((error) => error.code).toSet();
        if (codes.isEmpty) violations.add('rejected without a reason');
        if (!codes.every((code) => code == 'plan_too_large')) {
          violations.add('rejected with $codes');
        }
        continue;
      }

      final output = result.output!;
      if (output.columns < 1 || output.rows < 1) {
        violations.add('${output.columns} columns, ${output.rows} rows');
      }
      if (output.frames.length != output.columns * output.rows) {
        violations.add(
          '${output.frames.length} frames for '
          '${output.columns}x${output.rows}',
        );
      }
      expectFinite(
        violations,
        'horizontalIncrement',
        output.horizontalIncrementDegrees,
      );
      expectFinite(
        violations,
        'verticalIncrement',
        output.verticalIncrementDegrees,
      );
      if (output.horizontalIncrementDegrees <= 0) {
        violations.add(
          'horizontal increment ${output.horizontalIncrementDegrees}',
        );
      }
      if (output.horizontalCoverageDegrees < horizontal - 1e-6) {
        violations.add(
          'coverage ${output.horizontalCoverageDegrees} < $horizontal',
        );
      }
      if (output.verticalCoverageDegrees < vertical - 1e-6) {
        violations.add(
          'coverage ${output.verticalCoverageDegrees} < $vertical',
        );
      }
    }
    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
  });

  test(
    'timelapse plans stay finite and warn when the exposure outruns the interval',
    () {
      final violations = <String>[];
      for (var i = 0; i < samples; i++) {
        final interval = logUniform(0.1, 3600);
        final duration = logUniform(interval, 86400 * 30);
        final startExposure = logUniform(0.0005, 600);
        final input = TimelapseInput(
          intervalSeconds: interval,
          captureDurationSeconds: duration,
          playbackFps: logUniform(1, 120),
          megabytesPerFrame: logUniform(0.5, 120),
          startExposureSeconds: startExposure,
          endExposureSeconds: startExposure * logUniform(0.1, 10),
        );

        final result = const TimelapseCalculator().calculate(input);
        if (!result.isUsable) {
          final codes = result.errors.map((error) => error.code).toSet();
          if (codes.isEmpty) violations.add('rejected without a reason');
          if (!codes.every((code) => code == 'result_out_of_range')) {
            violations.add('rejected with $codes');
          }
          continue;
        }

        final output = result.output!;
        expectFinite(
          violations,
          'playbackDuration',
          output.playbackDurationSeconds,
        );
        expectFinite(violations, 'storage', output.storageMegabytes);
        expectFinite(violations, 'exposureRamp', output.exposureRampStops);
        expectFinite(violations, 'maximumDutyCycle', output.maximumDutyCycle);
        if (output.frameCount < 1) {
          violations.add('frame count ${output.frameCount}');
        }
        if (output.playbackDurationSeconds <= 0) {
          violations.add('playback duration ${output.playbackDurationSeconds}');
        }
        if (output.storageMegabytes < 0) {
          violations.add('storage ${output.storageMegabytes}');
        }
        if (output.maximumDutyCycle <= 0) {
          violations.add('duty cycle ${output.maximumDutyCycle}');
        }

        // A duty cycle above 1 means the exposure is longer than the interval:
        // the photographer cannot shoot that plan, and the calculator has to say
        // so rather than let the number speak for itself.
        final warns = result.warnings.any(
          (warning) => warning.code == 'exposure_exceeds_interval',
        );
        if ((output.maximumDutyCycle > 1) != warns) {
          violations.add(
            'duty cycle ${output.maximumDutyCycle} with warning=$warns',
          );
        }
      }
      expect(
        violations.take(5),
        isEmpty,
        reason: '${violations.length} violations',
      );
    },
  );
}
