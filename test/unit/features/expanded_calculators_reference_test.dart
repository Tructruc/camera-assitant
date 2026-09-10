import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/flash_exposure/domain/flash_exposure_calculator.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';
import 'package:photography_assistant/features/optics/domain/optics_calculators.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart';
import 'package:photography_assistant/features/timelapse/domain/timelapse_calculator.dart';

/// Cited reference fixtures for the expanded calculators (SC-001, FR-022).
///
/// Every expectation below is derived from the closed-form expression named in
/// its comment and cross-checked against the acceptance scenario of the same
/// number in `specs/001-photography-assistant/quickstart.md`. The assertions use
/// tolerances rather than exact equality so a formula change fails loudly while
/// floating-point noise does not. Boundary cases sit next to the reference case
/// that they stress.
void main() {
  // Rectilinear field of view: theta = 2 * atan(dimension / (2 * focalLength)).
  // Quickstart scenario 9.
  group('field of view reference', () {
    test('36 x 24 mm sensor at 50 mm gives the documented angles', () {
      final result = const FieldOfViewCalculator().calculate(
        const FieldOfViewInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          distanceMm: 10000,
        ),
      );
      final output = result.output!;
      expect(output.horizontalDegrees, closeTo(39.6, 0.1));
      expect(output.verticalDegrees, closeTo(27.0, 0.1));
      expect(output.sceneWidthMm / 1000, closeTo(7.2, 0.1));
    });

    test(
      'focal length equal to half the sensor width gives exactly 90 degrees',
      () {
        final result = const FieldOfViewCalculator().calculate(
          const FieldOfViewInput(
            sensorWidthMm: 36,
            sensorHeightMm: 24,
            focalLengthMm: 18,
            distanceMm: 1000,
          ),
        );
        expect(result.output!.horizontalDegrees, closeTo(90, 0.001));
      },
    );
  });

  // Airy disk: d = 2.44 * wavelength * f-number. Quickstart scenario 10.
  group('diffraction reference', () {
    test('f/8 at 550 nm and 4 um pixels matches the documented sampling', () {
      final result = const DiffractionCalculator().calculate(
        const DiffractionInput(
          aperture: 8,
          wavelengthNm: 550,
          pixelPitchMicrometres: 4,
        ),
      );
      final output = result.output!;
      expect(output.airyDiskMicrometres, closeTo(10.736, 0.01));
      expect(output.airyDiskPixels, closeTo(2.684, 0.01));
    });

    test('the Airy disk scales linearly with wavelength', () {
      DiffractionOutput at(double wavelengthNm) => const DiffractionCalculator()
          .calculate(
            DiffractionInput(
              aperture: 8,
              wavelengthNm: wavelengthNm,
              pixelPitchMicrometres: 4,
            ),
          )
          .output!;
      expect(
        at(1100).airyDiskMicrometres,
        closeTo(at(550).airyDiskMicrometres * 2, 0.001),
      );
    });
  });

  // Thin-lens extension: m = m0 + extension / focalLength, N_eff = N * (1 + m).
  // Quickstart scenario 14.
  group('macro reference', () {
    test(
      '25 mm on a 50 mm lens at 0.2x native gives the documented result',
      () {
        final result = const MacroCalculator().calculate(
          const MacroInput.extensionTube(
            focalLengthMm: 50,
            extensionLengthMm: 25,
            nativeMagnification: 0.2,
            nominalAperture: 8,
            sensorWidthMm: 36,
          ),
        );
        final output = result.output!;
        expect(output.magnification, closeTo(0.70, 0.01));
        expect(output.effectiveAperture, closeTo(13.6, 0.1));
        expect(output.subjectWidthMm, closeTo(51.4, 0.5));
      },
    );

    test('a negligible extension reproduces the native magnification', () {
      // The model rejects a zero extension as invalid input, so the boundary is
      // approached from above.
      final result = const MacroCalculator().calculate(
        const MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: 0.001,
          nativeMagnification: 0.2,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      );
      expect(result.output!.magnification, closeTo(0.2, 0.001));
    });
  });

  // Frame grid from covered angle divided by the per-frame angle reduced by the
  // requested overlap. Quickstart scenario 16.
  group('panorama reference', () {
    test('90 x 45 degrees at 30 percent overlap gives a 3 x 2 grid', () {
      final result = const PanoramaCalculator().calculate(
        const PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      );
      final output = result.output!;
      expect(output.columns, 3);
      expect(output.rows, 2);
      expect(output.frames, hasLength(6));
      expect(output.horizontalCoverageDegrees, greaterThanOrEqualTo(90));
      expect(output.verticalCoverageDegrees, greaterThanOrEqualTo(45));
    });

    test('removing overlap never reduces the frame count', () {
      PanoramaOutput at(double overlap) => const PanoramaCalculator()
          .calculate(
            PanoramaInput(
              sensorWidthMm: 36,
              sensorHeightMm: 24,
              focalLengthMm: 50,
              orientation: CameraOrientation.landscape,
              horizontalBoundsDegrees: 90,
              verticalBoundsDegrees: 45,
              horizontalOverlapPercent: overlap,
              verticalOverlapPercent: overlap,
            ),
          )
          .output!;
      // Overlap changes the plan: removing it widens the movement between
      // frames, and both plans must still cover the requested bounds.
      expect(
        at(0).horizontalIncrementDegrees,
        greaterThan(at(30).horizontalIncrementDegrees),
      );
      expect(at(0).frames.length, lessThanOrEqualTo(at(30).frames.length));
      for (final overlap in <double>[0, 30]) {
        expect(at(overlap).horizontalCoverageDegrees, greaterThanOrEqualTo(90));
        expect(at(overlap).verticalCoverageDegrees, greaterThanOrEqualTo(45));
      }
    });
  });

  // Guide number definition: N = GN / distance, with the guide number scaled by
  // the square root of the ISO ratio and the power fraction. Quickstart scenario 12.
  group('flash reference', () {
    test('guide number 40 at ISO 100 and 5 m recommends f/8', () {
      final result = const FlashExposureCalculator().calculate(
        const FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: 100,
          powerFraction: 1,
          subjectDistanceMetres: 5,
        ),
      );
      expect(result.output!.recommendedAperture, closeTo(8, 0.05));
    });

    test('half power costs one stop of guide number', () {
      final result = const FlashExposureCalculator().calculate(
        const FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: 100,
          powerFraction: 0.5,
          subjectDistanceMetres: 5,
        ),
      );
      final output = result.output!;
      expect(output.powerReductionStops, closeTo(1, 0.001));
      expect(output.recommendedAperture, closeTo(5.66, 0.1));
    });
  });

  // frames = duration / interval + 1, storage = frames * frame size.
  // Quickstart scenario 13.
  group('timelapse reference', () {
    test('one hour at ten second intervals produces the documented plan', () {
      final result = const TimelapseCalculator().calculate(
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
      expect(output.playbackDurationSeconds, closeTo(12.03, 0.05));
      expect(output.storageMegabytes, closeTo(9025, 1));
      expect(output.exposureRampStops, closeTo(2, 0.01));
    });

    test('an identical start and end exposure is a flat ramp', () {
      final result = const TimelapseCalculator().calculate(
        const TimelapseInput(
          intervalSeconds: 10,
          captureDurationSeconds: 600,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 2,
          endExposureSeconds: 2,
        ),
      );
      expect(result.output!.exposureRampStops, 0);
    });
  });
}
