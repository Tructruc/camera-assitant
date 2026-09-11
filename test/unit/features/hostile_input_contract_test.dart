import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/depth_of_field/domain/depth_of_field_calculator.dart';
import 'package:photography_assistant/features/exposure_comparison/domain/exposure_calculator.dart';
import 'package:photography_assistant/features/flash_exposure/domain/flash_exposure_calculator.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';
import 'package:photography_assistant/features/optics/domain/optics_calculators.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart';
import 'package:photography_assistant/features/timelapse/domain/timelapse_calculator.dart';

/// The common calculator contract: "Validation never throws for user-entered
/// values; it returns field-specific recovery guidance." Each calculator is fed
/// hostile but representable numbers through every numeric input it reads.
///
/// Two invariants are checked for every combination:
///  * a null output always comes with at least one error, a usable result never
///    carries errors, so a division or inverse-trigonometry domain slip cannot
///    hide behind a status;
///  * a usable result never publishes a non-finite number, so an overflow that
///    survived validation is caught here instead of on screen.
///
/// [expectSurvives] requires an explicit `numbers` extractor: a calculator
/// cannot be added to this suite without declaring which of its outputs are
/// supposed to be finite, so the finiteness invariant cannot silently lapse.
void main() {
  const hostile = <double>[
    0,
    -1,
    double.nan,
    double.infinity,
    double.negativeInfinity,
    1e12,
    1e-12,
    1e308,
    1e-308,
  ];

  void expectSurvives(
    String label,
    CalculationResult<Object?> Function(double) build,
    List<double> Function(Object output) numbers,
  ) {
    for (final value in hostile) {
      late final CalculationResult<Object?> result;
      expect(
        () => result = build(value),
        returnsNormally,
        reason: '$label threw for $value',
      );
      final output = result.output;
      if (output == null) {
        expect(
          result.errors,
          isNotEmpty,
          reason: '$label returned no output and no error for $value',
        );
      } else {
        expect(
          result.errors,
          isEmpty,
          reason: '$label returned an output alongside errors for $value',
        );
        final values = numbers(output);
        expect(
          values,
          isNotEmpty,
          reason: '$label exposed no numeric output to check for $value',
        );
        for (final number in values) {
          expect(
            number.isFinite,
            isTrue,
            reason: '$label published the non-finite value $number for $value',
          );
        }
      }
    }
  }

  test('depth of field survives hostile inputs', () {
    List<double> fields(Object output) {
      final dof = output as DepthOfFieldOutput;
      return [
        dof.hyperfocalDistance.millimetres,
        dof.nearLimit.millimetres,
        dof.frontDepth.millimetres,
        // Far limit and total depth are legitimately infinite at hyperfocal.
        if (!dof.farLimit.isInfinite) dof.farLimit.millimetres,
        if (!dof.totalDepth.isInfinite) dof.totalDepth.millimetres,
        if (!dof.rearDepth.isInfinite) dof.rearDepth.millimetres,
      ];
    }

    expectSurvives(
      'dof focal',
      (v) => const DepthOfFieldCalculator().calculate(
        DepthOfFieldInput(
          focalLengthMm: v,
          aperture: 8,
          focusDistanceMm: 10000,
          circleOfConfusionMm: 0.03,
        ),
      ),
      fields,
    );
    expectSurvives(
      'dof aperture',
      (v) => const DepthOfFieldCalculator().calculate(
        DepthOfFieldInput(
          focalLengthMm: 50,
          aperture: v,
          focusDistanceMm: 10000,
          circleOfConfusionMm: 0.03,
        ),
      ),
      fields,
    );
    expectSurvives(
      'dof distance',
      (v) => const DepthOfFieldCalculator().calculate(
        DepthOfFieldInput(
          focalLengthMm: 50,
          aperture: 8,
          focusDistanceMm: v,
          circleOfConfusionMm: 0.03,
        ),
      ),
      fields,
    );
    expectSurvives(
      'dof circle of confusion',
      (v) => const DepthOfFieldCalculator().calculate(
        DepthOfFieldInput(
          focalLengthMm: 50,
          aperture: 8,
          focusDistanceMm: 10000,
          circleOfConfusionMm: v,
        ),
      ),
      fields,
    );
  });

  test('exposure comparison survives hostile inputs', () {
    List<double> fields(Object output) {
      final comparison = output as ExposureComparisonOutput;
      return [
        comparison.totalDifference.stops,
        comparison.apertureContribution.stops,
        comparison.timeContribution.stops,
        comparison.isoContribution.stops,
        comparison.multiplier,
      ];
    }

    expectSurvives(
      'baseline aperture',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: ExposureTriple(aperture: v, timeSeconds: 0.008, iso: 100),
          candidate: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
        ),
      ),
      fields,
    );
    expectSurvives(
      'candidate shutter',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
          candidate: ExposureTriple(aperture: 4, timeSeconds: v, iso: 100),
        ),
      ),
      fields,
    );
    expectSurvives(
      'candidate iso',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
          candidate: ExposureTriple(aperture: 4, timeSeconds: 0.008, iso: v),
        ),
      ),
      fields,
    );
    expectSurvives(
      'baseline shutter',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: ExposureTriple(aperture: 4, timeSeconds: v, iso: 100),
          candidate: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
        ),
      ),
      fields,
    );
    expectSurvives(
      'baseline iso',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: ExposureTriple(aperture: 4, timeSeconds: 0.008, iso: v),
          candidate: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
        ),
      ),
      fields,
    );
    expectSurvives(
      'candidate aperture',
      (v) => const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: const ExposureTriple(
            aperture: 4,
            timeSeconds: 0.008,
            iso: 100,
          ),
          candidate: ExposureTriple(aperture: v, timeSeconds: 0.008, iso: 100),
        ),
      ),
      fields,
    );
  });

  test('long exposure survives hostile inputs', () {
    List<double> fields(Object output) {
      final long = output as LongExposureOutput;
      return [
        long.totalStrength.stops,
        for (final filter in long.appliedFilterStops) filter.stops,
        long.filteredTime.seconds,
        if (long.requiredStrength != null) long.requiredStrength!.stops,
      ];
    }

    expectSurvives(
      'base time',
      (v) => const LongExposureCalculator().calculate(
        LongExposureInput(
          baseTimeSeconds: v,
          filters: const [NdInput.stops(3)],
        ),
      ),
      fields,
    );
    expectSurvives(
      'filter stops',
      (v) => LongExposureCalculator().calculate(
        LongExposureInput(baseTimeSeconds: 0.03, filters: [NdInput.stops(v)]),
      ),
      fields,
    );
    expectSurvives(
      'filter factor',
      (v) => LongExposureCalculator().calculate(
        LongExposureInput(baseTimeSeconds: 0.03, filters: [NdInput.factor(v)]),
      ),
      fields,
    );
    expectSurvives(
      'filter optical density',
      (v) => LongExposureCalculator().calculate(
        LongExposureInput(
          baseTimeSeconds: 0.03,
          filters: [NdInput.opticalDensity(v)],
        ),
      ),
      fields,
    );
    expectSurvives(
      'target time',
      (v) => LongExposureCalculator().calculate(
        LongExposureInput(
          baseTimeSeconds: 0.03,
          filters: const [NdInput.stops(3)],
          targetTimeSeconds: v,
        ),
      ),
      fields,
    );
  });

  test('optics calculators survive hostile inputs', () {
    expectSurvives(
      'field of view focal',
      (v) => const FieldOfViewCalculator().calculate(
        FieldOfViewInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: v,
          distanceMm: 10000,
        ),
      ),
      (output) {
        final fov = output as FieldOfViewOutput;
        return [
          fov.horizontalDegrees,
          fov.verticalDegrees,
          fov.diagonalDegrees,
          fov.sceneWidthMm,
          fov.sceneHeightMm,
        ];
      },
    );
    expectSurvives(
      'field of view distance',
      (v) => const FieldOfViewCalculator().calculate(
        FieldOfViewInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          distanceMm: v,
        ),
      ),
      (output) {
        final fov = output as FieldOfViewOutput;
        return [fov.sceneWidthMm, fov.sceneHeightMm];
      },
    );
    expectSurvives(
      'diffraction wavelength',
      (v) => const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: 8,
          wavelengthNm: v,
          pixelPitchMicrometres: 4,
        ),
      ),
      (output) {
        final diffraction = output as DiffractionOutput;
        return [
          diffraction.airyDiskMicrometres,
          diffraction.airyRadiusMicrometres,
          diffraction.airyDiskPixels,
        ];
      },
    );
    expectSurvives(
      'diffraction aperture',
      (v) => const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: v,
          wavelengthNm: 550,
          pixelPitchMicrometres: 4,
        ),
      ),
      (output) {
        final diffraction = output as DiffractionOutput;
        return [
          diffraction.airyDiskMicrometres,
          diffraction.airyRadiusMicrometres,
          diffraction.airyDiskPixels,
        ];
      },
    );
    expectSurvives(
      'focus stack overlap',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: v,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
    expectSurvives(
      'focus stack focal',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: v,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: 30,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
    expectSurvives(
      'field of view sensor size',
      (v) => const FieldOfViewCalculator().calculate(
        FieldOfViewInput(
          sensorWidthMm: v,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          distanceMm: 10000,
        ),
      ),
      (output) {
        final fov = output as FieldOfViewOutput;
        return [
          fov.horizontalDegrees,
          fov.diagonalDegrees,
          fov.sceneWidthMm,
          fov.sceneHeightMm,
        ];
      },
    );
    expectSurvives(
      'diffraction pixel pitch',
      (v) => const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: 8,
          wavelengthNm: 550,
          pixelPitchMicrometres: v,
        ),
      ),
      (output) {
        final diffraction = output as DiffractionOutput;
        return [
          diffraction.airyDiskMicrometres,
          diffraction.airyRadiusMicrometres,
          diffraction.airyDiskPixels,
        ];
      },
    );
    expectSurvives(
      'focus stack aperture',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 100,
          aperture: v,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: 30,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
    expectSurvives(
      'focus stack circle of confusion',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: v,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: 30,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
    expectSurvives(
      'focus stack near distance',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: v,
          farDistanceMm: 1000,
          overlapPercent: 30,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
    expectSurvives(
      'focus stack far distance',
      (v) => const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: v,
          overlapPercent: 30,
        ),
      ),
      (output) => [...(output as FocusStackOutput).focusDistancesMm],
    );
  });

  test('flash and timelapse survive hostile inputs', () {
    List<double> flashFields(Object output) {
      final flash = output as FlashExposureOutput;
      return [
        flash.effectiveGuideNumberMetres,
        flash.recommendedAperture,
        flash.powerReductionStops,
        flash.fullPowerRangeAtRecommendedApertureMetres,
      ];
    }

    expectSurvives(
      'flash guide number',
      (v) => const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: v,
          iso: 100,
          powerFraction: 1,
          subjectDistanceMetres: 5,
        ),
      ),
      flashFields,
    );
    expectSurvives(
      'flash power',
      (v) => const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: 100,
          powerFraction: v,
          subjectDistanceMetres: 5,
        ),
      ),
      flashFields,
    );
    expectSurvives(
      'flash iso',
      (v) => const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: v,
          powerFraction: 1,
          subjectDistanceMetres: 5,
        ),
      ),
      flashFields,
    );
    expectSurvives(
      'flash distance',
      (v) => const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: 100,
          powerFraction: 1,
          subjectDistanceMetres: v,
        ),
      ),
      flashFields,
    );
    expectSurvives(
      'timelapse interval',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: v,
          captureDurationSeconds: 3600,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      (output) {
        final timelapse = output as TimelapseOutput;
        return [
          timelapse.playbackDurationSeconds,
          timelapse.storageMegabytes,
          timelapse.exposureRampStops,
          timelapse.maximumDutyCycle,
        ];
      },
    );
    expectSurvives(
      'timelapse capture duration',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: v,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      (output) {
        final timelapse = output as TimelapseOutput;
        return [
          timelapse.playbackDurationSeconds,
          timelapse.storageMegabytes,
          timelapse.exposureRampStops,
          timelapse.maximumDutyCycle,
        ];
      },
    );
    expectSurvives(
      'timelapse playback fps',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 3600,
          playbackFps: v,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      (output) {
        final timelapse = output as TimelapseOutput;
        return [
          timelapse.playbackDurationSeconds,
          timelapse.storageMegabytes,
          timelapse.exposureRampStops,
          timelapse.maximumDutyCycle,
        ];
      },
    );
    expectSurvives(
      'timelapse frame size',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 3600,
          playbackFps: 30,
          megabytesPerFrame: v,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      (output) => [(output as TimelapseOutput).storageMegabytes],
    );
    expectSurvives(
      'timelapse start exposure',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 3600,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: v,
          endExposureSeconds: 4,
        ),
      ),
      (output) {
        final timelapse = output as TimelapseOutput;
        return [timelapse.exposureRampStops, timelapse.maximumDutyCycle];
      },
    );
    expectSurvives(
      'timelapse end exposure',
      (v) => const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 3600,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: v,
        ),
      ),
      (output) {
        final timelapse = output as TimelapseOutput;
        return [timelapse.exposureRampStops, timelapse.maximumDutyCycle];
      },
    );
  });

  test('macro survives hostile inputs in every configuration', () {
    List<double> fields(Object output) {
      final macro = output as MacroOutput;
      return [
        macro.magnification,
        macro.effectiveAperture,
        macro.subjectWidthMm,
        macro.exposureCompensationStops,
      ];
    }

    expectSurvives(
      'macro extension',
      (v) => const MacroCalculator().calculate(
        MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: v,
          nativeMagnification: 0.2,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro reversed',
      (v) => const MacroCalculator().calculate(
        MacroInput.reversedLens(
          reversedFocalLengthMm: 28,
          flangeDistanceMm: v,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro coupled',
      (v) => const MacroCalculator().calculate(
        MacroInput.coupledLenses(
          primaryFocalLengthMm: 50,
          reversedFocalLengthMm: v,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro reversed focal',
      (v) => const MacroCalculator().calculate(
        MacroInput.reversedLens(
          reversedFocalLengthMm: v,
          flangeDistanceMm: 28,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro coupled primary',
      (v) => const MacroCalculator().calculate(
        MacroInput.coupledLenses(
          primaryFocalLengthMm: v,
          reversedFocalLengthMm: 50,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro extension focal',
      (v) => const MacroCalculator().calculate(
        MacroInput.extensionTube(
          focalLengthMm: v,
          extensionLengthMm: 20,
          nativeMagnification: 0.2,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro extension native magnification',
      (v) => const MacroCalculator().calculate(
        MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: 20,
          nativeMagnification: v,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro nominal aperture',
      (v) => const MacroCalculator().calculate(
        MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: 20,
          nativeMagnification: 0.2,
          nominalAperture: v,
          sensorWidthMm: 36,
        ),
      ),
      fields,
    );
    expectSurvives(
      'macro sensor width',
      (v) => const MacroCalculator().calculate(
        MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: 20,
          nativeMagnification: 0.2,
          nominalAperture: 8,
          sensorWidthMm: v,
        ),
      ),
      fields,
    );
  });

  test('panorama survives hostile inputs', () {
    List<double> fields(Object output) {
      final panorama = output as PanoramaOutput;
      return [
        panorama.frameHorizontalDegrees,
        panorama.frameVerticalDegrees,
        panorama.horizontalIncrementDegrees,
        panorama.verticalIncrementDegrees,
        panorama.horizontalCoverageDegrees,
        panorama.verticalCoverageDegrees,
        for (final frame in panorama.frames) ...[
          frame.yawDegrees,
          frame.pitchDegrees,
        ],
      ];
    }

    expectSurvives(
      'panorama overlap',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: v,
          verticalOverlapPercent: 30,
        ),
      ),
      fields,
    );
    expectSurvives(
      'panorama focal',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: v,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      ),
      fields,
    );
    expectSurvives(
      'panorama bounds',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: v,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      ),
      fields,
    );
    expectSurvives(
      'panorama vertical bounds',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: v,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      ),
      fields,
    );
    expectSurvives(
      'panorama vertical overlap',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: v,
        ),
      ),
      fields,
    );
    expectSurvives(
      'panorama sensor size',
      (v) => const PanoramaCalculator().calculate(
        PanoramaInput(
          sensorWidthMm: v,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      ),
      fields,
    );
  });

  test('astronomy survives hostile inputs', () {
    List<double> fields(Object output) {
      final astronomy = output as AstronomyOutput;
      return [
        astronomy.altitudeDegrees,
        astronomy.azimuthDegrees,
        astronomy.rightAscensionDegrees,
        astronomy.declinationDegrees,
        astronomy.rule500Seconds,
        astronomy.npfSeconds,
        astronomy.trailDurationSeconds,
        astronomy.trailRotationDegreesPerHour,
        astronomy.recommendedShutterSeconds,
        if (astronomy.milkyWayOrientationDegrees != null)
          astronomy.milkyWayOrientationDegrees!,
        for (final sample in astronomy.path) ...[
          sample.altitudeDegrees,
          sample.azimuthDegrees,
        ],
      ];
    }

    expectSurvives(
      'astronomy latitude',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: v,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.sirius,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy crop factor',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: 24,
          cropFactor: v,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy focal length',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: v,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy aperture',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: v,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy longitude',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: v,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.sirius,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy observer elevation',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          observerElevationMetres: v,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.sirius,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy pixel pitch',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: v,
          desiredTrailDegrees: 10,
        ),
      ),
      fields,
    );
    expectSurvives(
      'astronomy trail degrees',
      (v) => const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.sirius,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: v,
        ),
      ),
      fields,
    );
  });

  test('extreme but individually valid inputs are refused, not published', () {
    void expectRefused(
      String label,
      CalculationResult<Object?> result,
      String field,
    ) {
      expect(result.isUsable, isFalse, reason: '$label stayed usable');
      expect(result.output, isNull, reason: '$label published an output');
      expect(
        result.errors.map((error) => error.field),
        contains(field),
        reason: '$label blamed the wrong field',
      );
      expect(
        result.errors.every((error) => error.code == 'result_out_of_range'),
        isTrue,
        reason: '$label used an unexpected recovery code',
      );
    }

    expectRefused(
      'field of view scene width',
      const FieldOfViewCalculator().calculate(
        FieldOfViewInput(
          sensorWidthMm: 1e308,
          sensorHeightMm: 1e308,
          focalLengthMm: 1,
          distanceMm: 1e308,
        ),
      ),
      'distanceMm',
    );
    expectRefused(
      'diffraction airy diameter',
      const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: 1e308,
          wavelengthNm: 1e308,
          pixelPitchMicrometres: 4,
        ),
      ),
      'wavelengthNm',
    );
    expectRefused(
      'diffraction sampled diameter',
      const DiffractionCalculator().calculate(
        DiffractionInput(
          aperture: 8,
          wavelengthNm: 550,
          pixelPitchMicrometres: 1e-308,
        ),
      ),
      'pixelPitchMicrometres',
    );
    expectRefused(
      'focus stack hyperfocal',
      const FocusStackCalculator().calculate(
        FocusStackInput(
          focalLengthMm: 1e155,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 1e200,
          farDistanceMm: 1e250,
          overlapPercent: 30,
        ),
      ),
      'focalLengthMm',
    );
    expectRefused(
      'macro magnification',
      const MacroCalculator().calculate(
        MacroInput.coupledLenses(
          primaryFocalLengthMm: 1e-308,
          reversedFocalLengthMm: 1e308,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      'primaryFocalLengthMm',
    );
    expectRefused(
      'macro effective aperture',
      const MacroCalculator().calculate(
        MacroInput.reversedLens(
          reversedFocalLengthMm: 1,
          flangeDistanceMm: 1e308,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      ),
      'nominalAperture',
    );
    expectRefused(
      'flash guide number',
      const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: 1e308,
          iso: 1e308,
          powerFraction: 1,
          subjectDistanceMetres: 5,
        ),
      ),
      'guideNumberIso100Metres',
    );
    expectRefused(
      'astronomy 500 rule',
      const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: 24,
          cropFactor: 1e-308,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      ),
      'cropFactor',
    );
    expectRefused(
      'astronomy npf underflow',
      const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 6, 1),
          target: CelestialTarget.milkyWayCore,
          focalLengthMm: 1e308,
          cropFactor: 1,
          aperture: 1e-308,
          pixelPitchMicrometres: 1e-308,
          desiredTrailDegrees: 10,
        ),
      ),
      'focalLengthMm',
    );
    expectRefused(
      'exposure multiplier underflow',
      const ExposureCalculator().calculate(
        ExposureComparisonInput(
          baseline: ExposureTriple(
            aperture: 1e-308,
            timeSeconds: 0.008,
            iso: 100,
          ),
          candidate: ExposureTriple(aperture: 1, timeSeconds: 0.008, iso: 100),
        ),
      ),
      'baseline.aperture',
    );
    expectRefused(
      'long exposure optical density stops',
      const LongExposureCalculator().calculate(
        LongExposureInput(
          baseTimeSeconds: 0.03,
          filters: [NdInput.opticalDensity(1e308)],
        ),
      ),
      'filters[0]',
    );
    expectRefused(
      'timelapse playback duration',
      const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 3600,
          playbackFps: 1e-308,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      'playbackFps',
    );
    expectRefused(
      'timelapse storage estimate',
      const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 1,
          captureDurationSeconds: 1e6,
          playbackFps: 30,
          megabytesPerFrame: 1e308,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      'megabytesPerFrame',
    );
    expectRefused(
      'timelapse frame count',
      const TimelapseCalculator().calculate(
        TimelapseInput(
          intervalSeconds: 5,
          captureDurationSeconds: 1e308,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      ),
      'intervalSeconds',
    );
  });

  test('the alignment search survives hostile ranges and tolerances', () {
    for (final value in const <double>[
      0,
      -1,
      double.nan,
      double.infinity,
      1e12,
      1e308,
      1e-308,
    ]) {
      late final CalculationResult<AlignmentSearchOutput> result;
      expect(
        () => result = const AlignmentCalculator().search(
          AlignmentSearchInput(
            body: AlignmentBody.sun,
            observerLatitudeDegrees: 51.4779,
            observerLongitudeDegrees: 0,
            observerElevationMetres: 0,
            targetElevationMetres: 100,
            targetDistanceMetres: value,
            desiredBearingDegrees: 180,
            angularToleranceDegrees: 5,
            startUtc: DateTime.utc(2026, 3, 20),
            endUtc: DateTime.utc(2026, 3, 21),
          ),
        ),
        returnsNormally,
        reason: 'alignment search threw for target distance $value',
      );
      final output = result.output;
      if (output == null) {
        expect(
          result.errors,
          isNotEmpty,
          reason: 'alignment search lost its errors for $value',
        );
        continue;
      }
      // The observer-relative position must stay inside the celestial sphere
      // even when rounding pushes the asin argument past 1.
      expect(output.desiredAltitudeDegrees.isFinite, isTrue);
      expect(output.desiredAltitudeDegrees.abs() <= 90, isTrue);
      for (final candidate in output.candidates) {
        expect(candidate.altitudeDegrees.isFinite, isTrue);
        expect(candidate.azimuthDegrees.isFinite, isTrue);
        expect(candidate.angularErrorDegrees.isFinite, isTrue);
        expect(candidate.altitudeDegrees.abs() <= 90, isTrue);
        expect(candidate.azimuthDegrees, inInclusiveRange(0, 360));
      }
    }
  });
}
