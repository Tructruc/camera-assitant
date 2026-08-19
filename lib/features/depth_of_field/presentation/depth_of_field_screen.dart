import 'package:flutter/material.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/depth_of_field_calculator.dart';

class DepthOfFieldScreen extends StatefulWidget {
  const DepthOfFieldScreen({super.key});

  @override
  State<DepthOfFieldScreen> createState() => _DepthOfFieldScreenState();
}

class _DepthOfFieldScreenState extends State<DepthOfFieldScreen> {
  final _focal = TextEditingController(text: '50');
  final _aperture = TextEditingController(text: '8');
  final _distance = TextEditingController(text: '10000');
  final _coc = TextEditingController(text: '0.03');
  CalculationResult<DepthOfFieldOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _focal.dispose();
    _aperture.dispose();
    _distance.dispose();
    _coc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    children: <Widget>[
      Text('Depth of field', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text(
        'Calculate hyperfocal distance and the acceptable focus range.',
      ),
      const SizedBox(height: 16),
      CalculatorNumberField(
        label: 'Focal length (mm)',
        controller: _focal,
        fieldKey: const Key('dof-focal'),
        errorText: _errors['focalLengthMm'],
      ),
      CalculatorNumberField(
        label: 'Aperture (f-number)',
        controller: _aperture,
        errorText: _errors['aperture'],
      ),
      CalculatorNumberField(
        label: 'Focus distance (mm)',
        controller: _distance,
        errorText: _errors['focusDistanceMm'],
      ),
      CalculatorNumberField(
        label: 'Circle of confusion (mm)',
        controller: _coc,
        errorText: _errors['circleOfConfusionMm'],
      ),
      FilledButton(onPressed: _calculate, child: const Text('Calculate')),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: 'Depth of field result',
          rows: <(String, String)>[
            (
              'Hyperfocal distance',
              _distanceText(output.hyperfocalDistance.millimetres),
            ),
            ('Near limit', _distanceText(output.nearLimit.millimetres)),
            (
              'Far limit',
              output.farLimit.isInfinite
                  ? 'Infinity'
                  : _distanceText(output.farLimit.millimetres),
            ),
            (
              'Total depth',
              output.totalDepth.isInfinite
                  ? 'Infinity'
                  : _distanceText(output.totalDepth.millimetres),
            ),
          ],
          assumptions: const <String>[
            'Thin-lens geometric model',
            'Focus distance measured from the lens principal plane',
            'Circle of confusion controls acceptable sharpness',
          ],
          guidance: _result!.warnings.isEmpty
              ? 'Near and far limits are estimates, not guaranteed sharpness.'
              : 'Close focus reduces thin-lens model accuracy.',
          onSave: () => showSnapshotComingSoon(context),
          onReset: _reset,
        ),
    ],
  );

  void _calculate() {
    final result = const DepthOfFieldCalculator().calculate(
      DepthOfFieldInput(
        focalLengthMm: _number(_focal.text),
        aperture: _number(_aperture.text),
        focusDistanceMm: _number(_distance.text),
        circleOfConfusionMm: _number(_coc.text),
      ),
    );
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors) error.field: _message(error.code),
      };
    });
  }

  void _reset() {
    _focal.text = '50';
    _aperture.text = '8';
    _distance.text = '10000';
    _coc.text = '0.03';
    setState(() {
      _result = null;
      _errors = const {};
    });
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
String _message(String code) => code == 'not_beyond_focal_length'
    ? 'Focus distance must be greater than focal length.'
    : 'Enter a positive finite value.';
String _distanceText(double millimetres) => millimetres >= 1000
    ? '${(millimetres / 1000).toStringAsFixed(2)} m'
    : '${millimetres.toStringAsFixed(1)} mm';
