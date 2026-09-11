/// Approximate macro configuration planning with explicit model limitations.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

enum MacroConfiguration { extensionTube, reversedLens, coupledLenses }

final class MacroInput {
  const MacroInput._({
    required this.configuration,
    required this.nominalAperture,
    required this.sensorWidthMm,
    this.focalLengthMm,
    this.extensionLengthMm,
    this.nativeMagnification,
    this.reversedFocalLengthMm,
    this.flangeDistanceMm,
    this.primaryFocalLengthMm,
  });
  const MacroInput.extensionTube({
    required double focalLengthMm,
    required double extensionLengthMm,
    required double nativeMagnification,
    required double nominalAperture,
    required double sensorWidthMm,
  }) : this._(
         configuration: MacroConfiguration.extensionTube,
         focalLengthMm: focalLengthMm,
         extensionLengthMm: extensionLengthMm,
         nativeMagnification: nativeMagnification,
         nominalAperture: nominalAperture,
         sensorWidthMm: sensorWidthMm,
       );
  const MacroInput.reversedLens({
    required double reversedFocalLengthMm,
    required double flangeDistanceMm,
    required double nominalAperture,
    required double sensorWidthMm,
  }) : this._(
         configuration: MacroConfiguration.reversedLens,
         reversedFocalLengthMm: reversedFocalLengthMm,
         flangeDistanceMm: flangeDistanceMm,
         nominalAperture: nominalAperture,
         sensorWidthMm: sensorWidthMm,
       );
  const MacroInput.coupledLenses({
    required double primaryFocalLengthMm,
    required double reversedFocalLengthMm,
    required double nominalAperture,
    required double sensorWidthMm,
  }) : this._(
         configuration: MacroConfiguration.coupledLenses,
         primaryFocalLengthMm: primaryFocalLengthMm,
         reversedFocalLengthMm: reversedFocalLengthMm,
         nominalAperture: nominalAperture,
         sensorWidthMm: sensorWidthMm,
       );

  final MacroConfiguration configuration;
  final double nominalAperture;
  final double sensorWidthMm;
  final double? focalLengthMm;
  final double? extensionLengthMm;
  final double? nativeMagnification;
  final double? reversedFocalLengthMm;
  final double? flangeDistanceMm;
  final double? primaryFocalLengthMm;
}

final class MacroOutput {
  const MacroOutput({
    required this.magnification,
    required this.effectiveAperture,
    required this.subjectWidthMm,
    required this.exposureCompensationStops,
  });
  final double magnification;
  final double effectiveAperture;
  final double subjectWidthMm;
  final double exposureCompensationStops;
}

final class MacroCalculator {
  const MacroCalculator();
  static const id = 'macro';
  static const version = 1;

  CalculationResult<MacroOutput> calculate(MacroInput input) {
    final values = switch (input.configuration) {
      MacroConfiguration.extensionTube => <String, double>{
        'focalLengthMm': input.focalLengthMm!,
        'extensionLengthMm': input.extensionLengthMm!,
        'nativeMagnification': input.nativeMagnification!,
        'nominalAperture': input.nominalAperture,
        'sensorWidthMm': input.sensorWidthMm,
      },
      MacroConfiguration.reversedLens => <String, double>{
        'reversedFocalLengthMm': input.reversedFocalLengthMm!,
        'flangeDistanceMm': input.flangeDistanceMm!,
        'nominalAperture': input.nominalAperture,
        'sensorWidthMm': input.sensorWidthMm,
      },
      MacroConfiguration.coupledLenses => <String, double>{
        'primaryFocalLengthMm': input.primaryFocalLengthMm!,
        'reversedFocalLengthMm': input.reversedFocalLengthMm!,
        'nominalAperture': input.nominalAperture,
        'sensorWidthMm': input.sensorWidthMm,
      },
    };
    final errors = <ValidationError>[];
    for (final entry in values.entries) {
      final allowZero = entry.key == 'nativeMagnification';
      if (!entry.value.isFinite ||
          (allowZero ? entry.value < 0 : entry.value <= 0)) {
        errors.add(
          ValidationError(
            field: entry.key,
            code: allowZero
                ? 'non_negative_required'
                : 'positive_finite_required',
            messageKey: 'macro.error.${entry.key}',
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

    final magnification = switch (input.configuration) {
      MacroConfiguration.extensionTube =>
        input.nativeMagnification! +
            input.extensionLengthMm! / input.focalLengthMm!,
      MacroConfiguration.reversedLens =>
        input.flangeDistanceMm! / input.reversedFocalLengthMm!,
      MacroConfiguration.coupledLenses =>
        input.primaryFocalLengthMm! / input.reversedFocalLengthMm!,
    };
    // Extreme but individually valid inputs can collapse the magnification to
    // zero (dividing by it) or overflow the effective aperture. Report the
    // driving field rather than returning non-finite results (FR-002).
    if (!magnification.isFinite || magnification <= 0) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: [
          ValidationError(
            field: _magnificationField(input.configuration),
            code: 'result_out_of_range',
            messageKey: 'macro.error.resultOutOfRange',
          ),
        ],
      );
    }
    final apertureFactor = 1 + magnification;
    final effectiveAperture = input.nominalAperture * apertureFactor;
    final subjectWidth = input.sensorWidthMm / magnification;
    if (!effectiveAperture.isFinite || effectiveAperture <= 0) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: const [
          ValidationError(
            field: 'nominalAperture',
            code: 'result_out_of_range',
            messageKey: 'macro.error.resultOutOfRange',
          ),
        ],
      );
    }
    if (!subjectWidth.isFinite || subjectWidth <= 0) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: const [
          ValidationError(
            field: 'sensorWidthMm',
            code: 'result_out_of_range',
            messageKey: 'macro.error.resultOutOfRange',
          ),
        ],
      );
    }
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: MacroOutput(
        magnification: magnification,
        effectiveAperture: effectiveAperture,
        subjectWidthMm: subjectWidth,
        exposureCompensationStops: 2 * math.log(apertureFactor) / math.ln2,
      ),
      assumptions: [
        CalculationAssumption(
          key: 'configuration',
          value: input.configuration.name,
        ),
        const CalculationAssumption(
          key: 'optics',
          value: 'thinLensApproximation',
        ),
        const CalculationAssumption(key: 'pupilMagnification', value: 'one'),
      ],
      warnings: const [
        CalculationWarning(
          code: 'configuration_estimate',
          messageKey: 'macro.warning.configurationEstimate',
        ),
      ],
    );
  }
}

/// The user-entered field that drives magnification for [configuration].
String _magnificationField(MacroConfiguration configuration) =>
    switch (configuration) {
      MacroConfiguration.extensionTube => 'extensionLengthMm',
      MacroConfiguration.reversedLens => 'reversedFocalLengthMm',
      MacroConfiguration.coupledLenses => 'primaryFocalLengthMm',
    };
