import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../exposure_comparison/presentation/capture_field_controls.dart';
import '../domain/flash_exposure_calculator.dart';

/// Flash exposure: the speedlight's own power dial, the subject distance and
/// the unit's guide number, with the aperture answered as they change.
///
/// Power is offered as the marked dial positions (1/1 down to 1/128) because
/// that is what the back of a flash shows; the field itself stays a plain
/// fraction, so an unmarked power is still typeable.
class FlashExposureScreen extends ConsumerStatefulWidget {
  const FlashExposureScreen({super.key});
  @override
  ConsumerState<FlashExposureScreen> createState() =>
      _FlashExposureScreenState();
}

class _FlashExposureScreenState extends ConsumerState<FlashExposureScreen> {
  /// Nominal guide numbers at ISO 100 for common speedlights, in metres.
  static const _guideNumbers = <double>[12, 20, 24, 32, 36, 40, 44, 52, 58, 60];

  /// Subject distances a portrait or event flash is usually set to, in metres.
  static const _distances = <double>[1, 2, 3, 5, 10, 15, 20];

  /// Standard ISO settings.
  static const _isos = <double>[100, 200, 400, 800, 1600, 3200, 6400, 12800];

  final _guideNumber = TextEditingController(text: '40');
  final _iso = TextEditingController(text: '100');
  final _power = TextEditingController(text: '1');
  final _distance = TextEditingController(text: '5');
  CalculationResult<FlashExposureOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    // Seed the answer for the default flash so the screen opens with an
    // aperture instead of an empty slot.
    _calculate();
  }

  @override
  void dispose() {
    _guideNumber.dispose();
    _iso.dispose();
    _power.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Distance presentation follows the saved length preference (FR-020) while
    // the canonical inputs and snapshot values stay in metres.
    final lengthDisplay =
        ref.watch(preferencesProvider).valueOrNull?.lengthDisplay ??
        LengthDisplay.metric;
    String distance(double metres) =>
        formatDisplayLength(metres * 1000, lengthDisplay);
    return CalculatorPage(
      inputControllers: [_guideNumber, _iso, _power, _distance],
      onInputsChanged: () {
        if (_result != null || _errors.isNotEmpty) {
          setState(() {
            _result = null;
            _errors = const {};
          });
        }
        _calculate();
      },
      onCalculate: _calculate,
      children: [
        const CalculatorHeader(
          icon: Icons.flash_on_outlined,
          description:
              'Estimate direct-flash aperture from guide number, ISO, power, and distance.',
        ),
        const SizedBox(height: AppGap.lg),
        CalculatorNumberField(
          label: 'Guide number at ISO 100 (metres)',
          controller: _guideNumber,
          errorText: _errors['guideNumberIso100Metres'],
          fieldKey: const Key('flash-guide-number'),
          presets: _guideNumbers,
          // The unit's rating: one step of the dial is the next marked guide
          // number, so the steppers walk the presets.
          min: 1,
          max: 200,
          helperText: 'The rating printed on the flash, converted to metres',
        ),
        CalculatorNumberField(
          label: 'Power fraction',
          controller: _power,
          errorText: _errors['powerFraction'],
          // 1/256 to full power: the range a speedlight dial covers. The chips
          // write the marked positions, the slider sweeps between them.
          min: 0.00390625,
          max: 1,
          logarithmic: true,
          helperText: 'Fraction of full power - 0.5 is half power',
        ),
        CaptureChipRow(
          caption: 'Flash power (fraction of full power)',
          chips: <Widget>[
            for (final (label, fraction) in commonFlashPowerFractions)
              CaptureChoiceChip<double>(
                label: label,
                value: fraction,
                selected: matchesValue(
                  double.tryParse(_power.text.trim()),
                  fraction,
                ),
                tooltip: 'Set the flash to $label power',
                onSelected: _setPower,
              ),
          ],
        ),
        CalculatorNumberField(
          label: 'Subject distance (metres)',
          controller: _distance,
          errorText: _errors['subjectDistanceMetres'],
          presets: _distances,
          min: 0.1,
          max: 200,
          step: 0.5,
          helperText: 'Direct distance to the subject',
        ),
        // ISO scales the guide number but is set once per shoot, so it lives
        // with the other conventions; the value used stays visible in the
        // result caption.
        CalculatorAdvancedSection(
          // Stable identity: applying equipment above must not collapse
          // the section the user is working in.
          key: const ValueKey('advanced'),
          subtitle: 'ISO scales the guide number; it is set once per shoot',
          children: <Widget>[
            CalculatorNumberField(
              label: 'ISO',
              controller: _iso,
              errorText: _errors['iso'],
              presets: _isos,
              min: 25,
              max: 409600,
              logarithmic: true,
            ),
          ],
        ),
        const CaptureLiveHint(),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Flash exposure result',
            highlight: (
              'Recommended aperture',
              'f/${_apertureLabel(output.recommendedAperture)}',
            ),
            highlightCaption:
                'At ${distance(_number(_distance))} on ISO '
                '${_iso.text.trim()} at ${_powerLabel()}.',
            tiles: <(String, String)>[
              (
                'Effective guide number',
                distance(output.effectiveGuideNumberMetres),
              ),
              (
                'Power reduction',
                _stopsText(output.powerReductionStops, fractionDigits: 1),
              ),
              (
                'Full-power range',
                distance(output.fullPowerRangeAtRecommendedApertureMetres),
              ),
            ],
            details: <(String, String)>[
              (
                'Recommended aperture (exact)',
                'f/${output.recommendedAperture.toStringAsFixed(2)}',
              ),
              (
                'Effective guide number (exact)',
                '${output.effectiveGuideNumberMetres.toStringAsFixed(2)} m',
              ),
              (
                'Power reduction (exact)',
                _stopsText(output.powerReductionStops, fractionDigits: 2),
              ),
              (
                'Full-power range (exact)',
                '${output.fullPowerRangeAtRecommendedApertureMetres.toStringAsFixed(2)} m',
              ),
            ],
            inputs: [
              (
                'Guide number at ISO 100',
                distance(
                  double.tryParse(_guideNumber.text.trim()) ?? double.nan,
                ),
              ),
              ('ISO', _iso.text.trim()),
              ('Power fraction', _power.text.trim()),
              (
                'Subject distance',
                distance(double.tryParse(_distance.text.trim()) ?? double.nan),
              ),
            ],
            assumptions: const [
              'Direct flash aimed at the subject',
              'Guide number is a nominal manufacturer rating',
              'Modifiers, bounce loss, ambient light, and TTL metering are not modeled',
            ],
            guidance:
                'Use this as a starting exposure. Check the histogram and highlights, especially with bounce or modifiers.',
            warnings: <String>[
              for (final warning in _result!.warnings)
                calculationWarningText(warning.code),
            ],
            onSave: () => _save(output),
            onReset: _reset,
          ),
      ],
    );
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;

  void _setPower(double fraction) {
    _power.text = textFromCanonicalValue(fraction);
  }

  /// Plain-language power wording: `full power`, `half power`, else the dial
  /// position (`1/128`) or, for an unmarked value, its exact fraction.
  String _powerLabel() {
    final value = _number(_power);
    if (matchesValue(value, 1)) return 'full power';
    if (matchesValue(value, 0.5)) return 'half power';
    final marked = flashPowerValueLabel(value);
    if (marked != null) return '$marked power';
    return '${_power.text.trim()} power';
  }

  void _calculate() {
    final result = const FlashExposureCalculator().calculate(
      FlashExposureInput(
        guideNumberIso100Metres: _number(_guideNumber),
        iso: _number(_iso),
        powerFraction: _number(_power),
        subjectDistanceMetres: _number(_distance),
      ),
    );
    final errors = <String, String>{
      for (final error in result.errors)
        error.field: switch (error.code) {
          'power_range' =>
            'Enter a power fraction above 0 and no greater than 1.',
          'result_out_of_range' =>
            'These values produce a result outside the representable range. '
                'Reduce the extreme value and try again.',
          _ => 'Enter a positive finite value.',
        },
    };
    if (mounted) {
      setState(() {
        _result = result;
        _errors = errors;
      });
    } else {
      _result = result;
      _errors = errors;
    }
  }

  LengthDisplay get _lengthDisplay =>
      ref.read(preferencesProvider).valueOrNull?.lengthDisplay ??
      LengthDisplay.metric;

  Future<void> _save(FlashExposureOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${FlashExposureCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: FlashExposureCalculator.id,
      formulaVersion: FlashExposureCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title: 'Flash exposure result',
      canonicalInputs: {
        'guideNumberIso100Metres': _number(_guideNumber),
        'iso': _number(_iso),
        'powerFraction': _number(_power),
        'subjectDistanceMetres': _number(_distance),
      },
      canonicalOutputs: {
        'effectiveGuideNumberMetres': output.effectiveGuideNumberMetres,
        'recommendedAperture': output.recommendedAperture,
        'powerReductionStops': output.powerReductionStops,
        'fullPowerRangeAtRecommendedApertureMetres':
            output.fullPowerRangeAtRecommendedApertureMetres,
      },
      displayContext: {'distanceUnit': _lengthDisplay.name},
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
    ),
  );

  void _reset() {
    _guideNumber.text = '40';
    _iso.text = '100';
    _power.text = '1';
    _distance.text = '5';
    // Reset is an input change too: without this the shown aperture would
    // still describe the values the user just discarded.
    _calculate();
  }
}

/// A stop figure without the misleading `-0.0` that `-log(1)` produces.
String _stopsText(double stops, {required int fractionDigits}) {
  final normalized = stops == 0 ? 0.0 : stops;
  return '${normalized.toStringAsFixed(fractionDigits)} stops';
}

/// Photographers write whole f-stops as `f/8`, not `f/8.0`.
String _apertureLabel(double aperture) => aperture == aperture.roundToDouble()
    ? aperture.toStringAsFixed(0)
    : aperture.toStringAsFixed(1);
