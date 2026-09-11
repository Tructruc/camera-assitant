/// Versioned long-exposure and neutral-density calculation.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/quantities/quantities.dart';
import '../../../core/domain/validation/validation.dart';

enum NdInputKind { stops, factor, opticalDensity }

/// One ND filter value with its original convention preserved.
final class NdInput {
  const NdInput.stops(double value) : this._(NdInputKind.stops, value);

  const NdInput.factor(double value) : this._(NdInputKind.factor, value);

  const NdInput.opticalDensity(double value)
    : this._(NdInputKind.opticalDensity, value);

  const NdInput._(this.kind, this.value);

  final NdInputKind kind;
  final double value;
}

final class LongExposureInput {
  const LongExposureInput({
    required this.baseTimeSeconds,
    required this.filters,
    this.targetTimeSeconds,
  });

  final double baseTimeSeconds;
  final List<NdInput> filters;
  final double? targetTimeSeconds;
}

final class LongExposureOutput {
  LongExposureOutput({
    required this.totalStrength,
    required List<FilterStrength> appliedFilterStops,
    required this.filteredTime,
    required this.requiredStrength,
    required this.requiresBulbOrTimer,
  }) : appliedFilterStops = List.unmodifiable(appliedFilterStops);

  final FilterStrength totalStrength;
  final List<FilterStrength> appliedFilterStops;
  final ExposureTime filteredTime;
  final FilterStrength? requiredStrength;
  final bool requiresBulbOrTimer;
}

final class LongExposureCalculator {
  const LongExposureCalculator();

  static const id = 'long_exposure_nd';
  static const version = 1;

  CalculationResult<LongExposureOutput> calculate(LongExposureInput input) {
    final errors = _validate(input);
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final appliedStops = input.filters
        .map((filter) => FilterStrength(_toStops(filter)))
        .toList(growable: false);
    final totalStops = appliedStops.fold<double>(
      0,
      (total, strength) => total + strength.stops,
    );
    final filteredSeconds =
        input.baseTimeSeconds * math.pow(2, totalStops).toDouble();
    // A physically representable stack can still overflow the filtered time.
    // Report it as a field error instead of letting the ExposureTime value
    // object throw, which the contract forbids for user-entered values.
    if (!filteredSeconds.isFinite) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: const [
          ValidationError(
            field: 'filters',
            code: 'result_out_of_range',
            messageKey: 'longExposure.error.resultOutOfRange',
          ),
        ],
      );
    }
    final targetSeconds = input.targetTimeSeconds;
    final requiredStops = targetSeconds == null
        ? null
        : _log2(targetSeconds / input.baseTimeSeconds);
    // A representable base and target can still differ by more stops than a
    // double can hold; the surplus filter strength would throw, so report the
    // target field instead (FR-002).
    if (requiredStops != null && !requiredStops.isFinite) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: const [
          ValidationError(
            field: 'targetTimeSeconds',
            code: 'result_out_of_range',
            messageKey: 'longExposure.error.resultOutOfRange',
          ),
        ],
      );
    }

    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: LongExposureOutput(
        totalStrength: FilterStrength(totalStops),
        appliedFilterStops: appliedStops,
        filteredTime: ExposureTime.seconds(filteredSeconds),
        requiredStrength: requiredStops == null
            ? null
            : FilterStrength(requiredStops),
        requiresBulbOrTimer: filteredSeconds > 30,
      ),
      assumptions: const [
        CalculationAssumption(key: 'stopBase', value: '2'),
        CalculationAssumption(key: 'opticalDensityBase', value: '10'),
        CalculationAssumption(
          key: 'filterStacking',
          value: 'idealMultiplicativeAttenuation',
        ),
      ],
    );
  }

  List<ValidationError> _validate(LongExposureInput input) {
    final errors = <ValidationError>[];
    if (!_isPositiveFinite(input.baseTimeSeconds)) {
      errors.add(_error('baseTimeSeconds', 'positive_finite_required'));
    }
    for (var index = 0; index < input.filters.length; index++) {
      final filter = input.filters[index];
      final valid = switch (filter.kind) {
        NdInputKind.stops || NdInputKind.opticalDensity =>
          filter.value.isFinite && filter.value >= 0,
        NdInputKind.factor => filter.value.isFinite && filter.value >= 1,
      };
      if (!valid) {
        errors.add(_error('filters[$index]', 'invalid_filter_strength'));
      } else if (!_toStops(filter).isFinite) {
        // An in-range optical density can still overflow the derived stop
        // count, which would make FilterStrength throw (FR-002).
        errors.add(_error('filters[$index]', 'result_out_of_range'));
      }
    }
    final target = input.targetTimeSeconds;
    if (target != null) {
      if (!_isPositiveFinite(target)) {
        errors.add(_error('targetTimeSeconds', 'positive_finite_required'));
      } else if (_isPositiveFinite(input.baseTimeSeconds) &&
          target < input.baseTimeSeconds) {
        errors.add(_error('targetTimeSeconds', 'target_shorter_than_base'));
      }
    }
    return errors;
  }

  ValidationError _error(String field, String code) => ValidationError(
    field: field,
    code: code,
    messageKey: 'longExposure.error.$code',
  );

  bool _isPositiveFinite(double value) => value.isFinite && value > 0;

  double _toStops(NdInput input) => switch (input.kind) {
    NdInputKind.stops => input.value,
    NdInputKind.factor => _log2(input.value),
    NdInputKind.opticalDensity => input.value * math.log(10) / math.ln2,
  };

  double _log2(double value) => math.log(value) / math.ln2;
}
