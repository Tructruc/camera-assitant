import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/models/exposure_solve_mode.dart';
import 'package:camera_assistant/domain/calculators/exposure_calculator.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';

class ExposureCalculatorScreen extends StatefulWidget {
  const ExposureCalculatorScreen({super.key});

  @override
  State<ExposureCalculatorScreen> createState() =>
      _ExposureCalculatorScreenState();
}

class _ExposureCalculatorScreenState extends State<ExposureCalculatorScreen> {
  ExposureSolveMode _mode = ExposureSolveMode.shutter;

  final _iso1 = TextEditingController(text: '100');
  final _aperture1 = TextEditingController(text: '2.8');
  final _shutter1 = TextEditingController(text: '1/60');

  final _iso2 = TextEditingController(text: '100');
  final _aperture2 = TextEditingController(text: '4');
  final _shutter2 = TextEditingController(text: '1/100');

  String _result = 'Your result will appear here.';

  @override
  void dispose() {
    _iso1.dispose();
    _aperture1.dispose();
    _shutter1.dispose();
    _iso2.dispose();
    _aperture2.dispose();
    _shutter2.dispose();
    super.dispose();
  }

  void _calculate() {
    final iso1 = parseDouble(_iso1.text);
    final n1 = parseDouble(_aperture1.text);
    final t1 = parseDouble(_shutter1.text);
    final iso2 = parseDouble(_iso2.text);
    final n2 = parseDouble(_aperture2.text);
    final t2 = parseDouble(_shutter2.text);

    if (iso1 == null ||
        n1 == null ||
        t1 == null ||
        iso1 <= 0 ||
        n1 <= 0 ||
        t1 <= 0) {
      setState(() => _result = 'Enter valid positive reference values.');
      return;
    }

    final k = ExposureCalculator.computeK(n1, t1, iso1);

    switch (_mode) {
      case ExposureSolveMode.shutter:
        if (iso2 == null || n2 == null || iso2 <= 0 || n2 <= 0) {
          setState(() => _result = 'Enter valid ISO2 and aperture2.');
          return;
        }
        final solved = ExposureCalculator.solveShutter(k, n2, iso2);
        final ev100 = ExposureCalculator.computeEV100(n2, solved);
        final fractionLabel = formatFractionalSeconds(solved);
        setState(() {
          _shutter2.text = formatSecondsInput(solved);
          _result =
              'Shutter: $fractionLabel\nEV100: ${ev100.toStringAsFixed(2)}';
        });
        break;
      case ExposureSolveMode.aperture:
        if (iso2 == null || t2 == null || iso2 <= 0 || t2 <= 0) {
          setState(() => _result = 'Enter valid ISO2 and shutter2.');
          return;
        }
        final solved = ExposureCalculator.solveAperture(k, t2, iso2);
        final ev100 = ExposureCalculator.computeEV100(solved, t2);
        setState(() {
          _aperture2.text = solved.toStringAsFixed(2);
          _result =
              'Aperture: f/${solved.toStringAsFixed(2)}\nEV100: ${ev100.toStringAsFixed(2)}';
        });
        break;
      case ExposureSolveMode.iso:
        if (n2 == null || t2 == null || n2 <= 0 || t2 <= 0) {
          setState(() => _result = 'Enter valid aperture2 and shutter2.');
          return;
        }
        final solved = ExposureCalculator.solveISO(k, n2, t2);
        final ev100 = ExposureCalculator.computeEV100(n2, t2);
        setState(() {
          _iso2.text = solved.toStringAsFixed(0);
          _result =
              'ISO: ${solved.toStringAsFixed(0)}\nEV100: ${ev100.toStringAsFixed(2)}';
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionCard(
            title: 'Starting Exposure',
            children: [
              NumField(controller: _iso1, label: 'ISO', suffix: ''),
              NumField(controller: _aperture1, label: 'Aperture', suffix: 'f'),
              NumField(
                controller: _shutter1,
                label: 'Shutter',
                suffix: 'sec',
                allowFractions: true,
              ),
            ],
          ),
          SectionCard(
            title: 'New Exposure',
            children: [
              DropdownButtonFormField<ExposureSolveMode>(
                initialValue: _mode,
                items: const [
                  DropdownMenuItem(
                    value: ExposureSolveMode.shutter,
                    child: Text('Find Shutter'),
                  ),
                  DropdownMenuItem(
                    value: ExposureSolveMode.aperture,
                    child: Text('Find Aperture'),
                  ),
                  DropdownMenuItem(
                    value: ExposureSolveMode.iso,
                    child: Text('Find ISO'),
                  ),
                ],
                onChanged: (v) {
                  if (v == null) {
                    return;
                  }
                  setState(() => _mode = v);
                },
              ),
              const SizedBox(height: 10),
              NumField(controller: _iso2, label: 'ISO', suffix: ''),
              NumField(controller: _aperture2, label: 'Aperture', suffix: 'f'),
              NumField(
                controller: _shutter2,
                label: 'Shutter',
                suffix: 'sec',
                allowFractions: true,
              ),
              FilledButton(
                  onPressed: _calculate, child: const Text('Calculate')),
            ],
          ),
          SectionCard(title: 'Output', children: [Text(_result)]),
        ],
      ),
    );
  }
}
