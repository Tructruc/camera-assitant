import 'package:flutter/material.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/long_exposure_calculator.dart';

class LongExposureScreen extends StatefulWidget {
  const LongExposureScreen({super.key});

  @override
  State<LongExposureScreen> createState() => _LongExposureScreenState();
}

class _LongExposureScreenState extends State<LongExposureScreen> {
  final _base = TextEditingController(text: '0.0333333333');
  final _stops = TextEditingController(text: '10');
  final _target = TextEditingController();
  CalculationResult<LongExposureOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _base.dispose();
    _stops.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    children: <Widget>[
      Text(
        'Long exposure / ND',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text('Enter stacked ND strengths as comma-separated stops.'),
      const SizedBox(height: 16),
      CalculatorNumberField(
        label: 'Base shutter time (seconds)',
        controller: _base,
        fieldKey: const Key('long-base'),
        errorText: _errors['baseTimeSeconds'],
      ),
      TextField(
        key: const Key('long-stops'),
        controller: _stops,
        decoration: InputDecoration(
          labelText: 'ND filter strengths (stops)',
          helperText: 'Example: 3, 7',
          errorText: _filterError,
        ),
        keyboardType: TextInputType.text,
      ),
      const SizedBox(height: 12),
      CalculatorNumberField(
        label: 'Optional target time (seconds)',
        controller: _target,
        errorText: _errors['targetTimeSeconds'],
      ),
      FilledButton(
        onPressed: _calculate,
        child: const Text('Calculate exposure'),
      ),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: output.conventionalGuidance,
          rows: <(String, String)>[
            (
              'Raw exposure',
              '${output.filteredTime.seconds.toStringAsFixed(6)} s',
            ),
            (
              'Total ND strength',
              '${output.totalStrength.stops.toStringAsFixed(2)} stops',
            ),
            if (output.requiredStrength case final required?)
              (
                'Required strength',
                '${required.stops.toStringAsFixed(2)} stops',
              ),
          ],
          assumptions: const <String>[
            'Each ND stop doubles exposure time',
            'Stacked filters use ideal multiplicative attenuation',
          ],
          guidance: output.requiresBulbOrTimer
              ? 'Use Bulb or timer mode; conventional shutter ranges usually end at 30 seconds.'
              : 'Use the nearest supported shutter time and review the raw value.',
          onSave: () => showSnapshotComingSoon(context),
          onReset: _reset,
        ),
    ],
  );

  String? get _filterError {
    for (final entry in _errors.entries) {
      if (entry.key.startsWith('filters[')) return entry.value;
    }
    return null;
  }

  void _calculate() {
    final values = _stops.text.trim().isEmpty
        ? <String>[]
        : _stops.text.split(',').map((item) => item.trim()).toList();
    final targetText = _target.text.trim();
    final result = const LongExposureCalculator().calculate(
      LongExposureInput(
        baseTimeSeconds: _number(_base.text),
        filters: <NdInput>[
          for (final value in values) NdInput.stops(_number(value)),
        ],
        targetTimeSeconds: targetText.isEmpty ? null : _number(targetText),
      ),
    );
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors)
          error.field: error.code == 'target_shorter_than_base'
              ? 'Target time must not be shorter than base time.'
              : 'Enter a valid non-negative ND value.',
      };
    });
  }

  void _reset() {
    _base.text = '0.0333333333';
    _stops.text = '10';
    _target.clear();
    setState(() {
      _result = null;
      _errors = const {};
    });
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
