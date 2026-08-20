import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/timelapse_calculator.dart';

class TimelapseScreen extends ConsumerStatefulWidget {
  const TimelapseScreen({super.key});
  @override
  ConsumerState<TimelapseScreen> createState() => _TimelapseScreenState();
}

class _TimelapseScreenState extends ConsumerState<TimelapseScreen> {
  final _controllers = [
    TextEditingController(text: '10'),
    TextEditingController(text: '3600'),
    TextEditingController(text: '30'),
    TextEditingController(text: '25'),
    TextEditingController(text: '1'),
    TextEditingController(text: '4'),
  ];
  static const _fields = [
    ('Interval (seconds)', 'intervalSeconds'),
    ('Capture duration (seconds)', 'captureDurationSeconds'),
    ('Playback frame rate (fps)', 'playbackFps'),
    ('Estimated size per frame (MB)', 'megabytesPerFrame'),
    ('Starting exposure (seconds)', 'startExposureSeconds'),
    ('Ending exposure (seconds)', 'endExposureSeconds'),
  ];
  CalculationResult<TimelapseOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CalculatorPage(
    children: [
      Text(
        'Timelapse planner',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Plan capture cadence, playback length, storage, and an exposure ramp.',
      ),
      const SizedBox(height: 16),
      for (var index = 0; index < _fields.length; index++)
        CalculatorNumberField(
          label: _fields[index].$1,
          controller: _controllers[index],
          errorText: _errors[_fields[index].$2],
          fieldKey: Key('timelapse-${_fields[index].$2}'),
        ),
      FilledButton(onPressed: _calculate, child: const Text('Plan timelapse')),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: 'Timelapse plan',
          rows: [
            ('Frames', '${output.frameCount}'),
            (
              'Playback duration',
              '${output.playbackDurationSeconds.toStringAsFixed(2)} seconds',
            ),
            ('Estimated storage', _storage(output.storageMegabytes)),
            ('Exposure ramp', '${_signed(output.exposureRampStops)} stops'),
            (
              'Maximum exposure duty cycle',
              '${(output.maximumDutyCycle * 100).toStringAsFixed(0)}%',
            ),
          ],
          assumptions: const [
            'A frame is captured at both sequence endpoints',
            'File size remains constant across the sequence',
            'Camera write time and intervalometer latency are not modeled',
          ],
          guidance: output.maximumDutyCycle >= 1
              ? 'The longest exposure does not fit inside the interval. Increase the interval or shorten the exposure.'
              : 'Leave additional interval margin for image processing and storage writes.',
          onSave: () => _save(output),
          onReset: _reset,
        ),
    ],
  );
  double _value(int index) =>
      double.tryParse(_controllers[index].text.trim()) ?? double.nan;
  void _calculate() {
    final result = const TimelapseCalculator().calculate(
      TimelapseInput(
        intervalSeconds: _value(0),
        captureDurationSeconds: _value(1),
        playbackFps: _value(2),
        megabytesPerFrame: _value(3),
        startExposureSeconds: _value(4),
        endExposureSeconds: _value(5),
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

  Future<void> _save(TimelapseOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${TimelapseCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: TimelapseCalculator.id,
      formulaVersion: TimelapseCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title: 'Timelapse plan',
      canonicalInputs: {
        for (var index = 0; index < _fields.length; index++)
          _fields[index].$2: _value(index),
      },
      canonicalOutputs: {
        'frameCount': output.frameCount,
        'playbackDurationSeconds': output.playbackDurationSeconds,
        'storageMegabytes': output.storageMegabytes,
        'exposureRampStops': output.exposureRampStops,
        'maximumDutyCycle': output.maximumDutyCycle,
      },
      displayContext: const {'storageUnits': 'binaryMegabytes'},
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
    ),
  );
  void _reset() {
    const defaults = ['10', '3600', '30', '25', '1', '4'];
    for (var index = 0; index < defaults.length; index++) {
      _controllers[index].text = defaults[index];
    }
    setState(() {
      _result = null;
      _errors = const {};
    });
  }

  String _storage(double megabytes) => megabytes >= 1024
      ? '${(megabytes / 1024).toStringAsFixed(2)} GB'
      : '${megabytes.toStringAsFixed(0)} MB';
  String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}';
}
