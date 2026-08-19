import 'package:flutter/material.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/exposure_calculator.dart';

class ExposureComparisonScreen extends StatefulWidget {
  const ExposureComparisonScreen({super.key});

  @override
  State<ExposureComparisonScreen> createState() =>
      _ExposureComparisonScreenState();
}

class _ExposureComparisonScreenState extends State<ExposureComparisonScreen> {
  final _controllers = <TextEditingController>[
    TextEditingController(text: '4'),
    TextEditingController(text: '0.008'),
    TextEditingController(text: '100'),
    TextEditingController(text: '4'),
    TextEditingController(text: '0.008'),
    TextEditingController(text: '100'),
  ];
  CalculationResult<ExposureComparisonOutput>? _result;
  Map<String, String> _errors = const {};

  static const _fields = <(String, String)>[
    ('Baseline aperture (f-number)', 'baseline.aperture'),
    ('Baseline shutter (seconds)', 'baseline.timeSeconds'),
    ('Baseline ISO', 'baseline.iso'),
    ('Candidate aperture (f-number)', 'candidate.aperture'),
    ('Candidate shutter (seconds)', 'candidate.timeSeconds'),
    ('Candidate ISO', 'candidate.iso'),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    children: <Widget>[
      Text(
        'Exposure comparison',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Compare how aperture, shutter time, and ISO change exposure.',
      ),
      const SizedBox(height: 16),
      for (var index = 0; index < _fields.length; index++)
        CalculatorNumberField(
          label: _fields[index].$1,
          controller: _controllers[index],
          errorText: _errors[_fields[index].$2],
        ),
      FilledButton(
        onPressed: _calculate,
        child: const Text('Compare exposures'),
      ),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: switch (output.direction) {
            ExposureDirection.brighter => 'Candidate is brighter',
            ExposureDirection.equivalent => 'Equivalent exposure',
            ExposureDirection.darker => 'Candidate is darker',
          },
          rows: <(String, String)>[
            (
              'Total difference',
              '${output.totalDifference.stops.toStringAsFixed(2)} stops',
            ),
            (
              'Aperture contribution',
              '${output.apertureContribution.stops.toStringAsFixed(2)} stops',
            ),
            (
              'Shutter contribution',
              '${output.timeContribution.stops.toStringAsFixed(2)} stops',
            ),
            (
              'ISO contribution',
              '${output.isoContribution.stops.toStringAsFixed(2)} stops',
            ),
            ('Exposure multiplier', '${output.multiplier.toStringAsFixed(2)}×'),
          ],
          assumptions: const <String>[
            'Each stop doubles or halves exposure',
            'Scene light and transmission remain unchanged',
          ],
          onSave: () => showSnapshotComingSoon(context),
          onReset: _reset,
        ),
    ],
  );

  void _calculate() {
    final result = const ExposureCalculator().calculate(
      ExposureComparisonInput(
        baseline: ExposureTriple(
          aperture: _number(_controllers[0].text),
          timeSeconds: _number(_controllers[1].text),
          iso: _number(_controllers[2].text),
        ),
        candidate: ExposureTriple(
          aperture: _number(_controllers[3].text),
          timeSeconds: _number(_controllers[4].text),
          iso: _number(_controllers[5].text),
        ),
      ),
    );
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors)
          error.field: 'Enter a positive finite value.',
      };
    });
  }

  void _reset() {
    const defaults = <String>['4', '0.008', '100', '4', '0.008', '100'];
    for (var index = 0; index < defaults.length; index++) {
      _controllers[index].text = defaults[index];
    }
    setState(() {
      _result = null;
      _errors = const {};
    });
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
