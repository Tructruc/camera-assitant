import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/flash_exposure_calculator.dart';

class FlashExposureScreen extends ConsumerStatefulWidget {
  const FlashExposureScreen({super.key});
  @override
  ConsumerState<FlashExposureScreen> createState() =>
      _FlashExposureScreenState();
}

class _FlashExposureScreenState extends ConsumerState<FlashExposureScreen> {
  final _guideNumber = TextEditingController(text: '40');
  final _iso = TextEditingController(text: '100');
  final _power = TextEditingController(text: '1');
  final _distance = TextEditingController(text: '5');
  CalculationResult<FlashExposureOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _guideNumber.dispose();
    _iso.dispose();
    _power.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    children: [
      Text('Flash exposure', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Estimate direct-flash aperture from guide number, ISO, power, and distance.',
      ),
      const SizedBox(height: 16),
      CalculatorNumberField(
        label: 'Guide number at ISO 100 (metres)',
        controller: _guideNumber,
        errorText: _errors['guideNumberIso100Metres'],
        fieldKey: const Key('flash-guide-number'),
      ),
      CalculatorNumberField(
        label: 'ISO',
        controller: _iso,
        errorText: _errors['iso'],
      ),
      CalculatorNumberField(
        label: 'Power fraction (1, 0.5, 0.25…)',
        controller: _power,
        errorText: _errors['powerFraction'],
      ),
      CalculatorNumberField(
        label: 'Subject distance (metres)',
        controller: _distance,
        errorText: _errors['subjectDistanceMetres'],
      ),
      FilledButton(
        onPressed: _calculate,
        child: const Text('Calculate flash exposure'),
      ),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: 'Flash exposure result',
          rows: [
            (
              'Recommended aperture',
              'f/${output.recommendedAperture.toStringAsFixed(1)}',
            ),
            (
              'Effective guide number',
              '${output.effectiveGuideNumberMetres.toStringAsFixed(1)} m',
            ),
            (
              'Power reduction',
              '${output.powerReductionStops.toStringAsFixed(1)} stops',
            ),
            (
              'Full-power range at that aperture',
              '${output.fullPowerRangeAtRecommendedApertureMetres.toStringAsFixed(1)} m',
            ),
          ],
          assumptions: const [
            'Direct flash aimed at the subject',
            'Guide number is a nominal manufacturer rating',
            'Modifiers, bounce loss, ambient light, and TTL metering are not modeled',
          ],
          guidance:
              'Use this as a starting exposure. Check the histogram and highlights, especially with bounce or modifiers.',
          onSave: () => _save(output),
          onReset: _reset,
        ),
    ],
  );

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;
  void _calculate() {
    final result = const FlashExposureCalculator().calculate(
      FlashExposureInput(
        guideNumberIso100Metres: _number(_guideNumber),
        iso: _number(_iso),
        powerFraction: _number(_power),
        subjectDistanceMetres: _number(_distance),
      ),
    );
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors)
          error.field: error.code == 'power_range'
              ? 'Enter a power fraction above 0 and no greater than 1.'
              : 'Enter a positive finite value.',
      };
    });
  }

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
      displayContext: const {'guideNumberUnits': 'metres'},
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
    ),
  );
  void _reset() {
    _guideNumber.text = '40';
    _iso.text = '100';
    _power.text = '1';
    _distance.text = '5';
    setState(() {
      _result = null;
      _errors = const {};
    });
  }
}
