import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
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

  /// How many of [_fields] define the capture plan itself.
  static const primaryFieldCount = 3;
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
    inputControllers: _controllers,
    onInputsChanged: () {
      if (_result != null || _errors.isNotEmpty) {
        setState(() {
          _result = null;
          _errors = const {};
        });
      }
    },
    children: [
      const CalculatorHeader(
        icon: Icons.movie_creation_outlined,
        description:
            'Plan capture cadence, playback length, storage, and an exposure ramp.',
      ),
      const SizedBox(height: 16),
      // Cadence, duration, and playback rate define the plan; per-frame size
      // and the exposure ramp refine it.
      for (var index = 0; index < primaryFieldCount; index++)
        CalculatorNumberField(
          label: _fields[index].$1,
          controller: _controllers[index],
          errorText: _errors[_fields[index].$2],
          fieldKey: Key('timelapse-${_fields[index].$2}'),
        ),
      CalculatorAdvancedSection(
        // Stable identity: applying equipment above must not collapse
        // the section the user is working in.
        key: const ValueKey('advanced'),
        children: <Widget>[
          for (var index = primaryFieldCount; index < _fields.length; index++)
            CalculatorNumberField(
              label: _fields[index].$1,
              controller: _controllers[index],
              errorText: _errors[_fields[index].$2],
              fieldKey: Key('timelapse-${_fields[index].$2}'),
            ),
        ],
      ),
      FilledButton(onPressed: _calculate, child: const Text('Plan timelapse')),
      const SizedBox(height: 16),
      if (_result?.output case final output?)
        CalculationResultView(
          title: 'Timelapse plan',
          highlight: ('Frames', '${output.frameCount}'),
          highlightCaption:
              'At a ${_controllers[0].text.trim()} s interval across '
              '${_humanDuration(_value(1))}.',
          tiles: <(String, String)>[
            (
              'Playback duration',
              _humanDuration(output.playbackDurationSeconds),
            ),
            ('Estimated storage', _storage(output.storageMegabytes)),
            (
              'Exposure ramp',
              '${_signed(output.exposureRampStops, fractionDigits: 1)} stops',
            ),
          ],
          details: <(String, String)>[
            (
              'Playback duration (exact)',
              '${output.playbackDurationSeconds.toStringAsFixed(3)} s',
            ),
            (
              'Estimated storage (exact)',
              '${output.storageMegabytes.toStringAsFixed(2)} MB',
            ),
            (
              'Exposure ramp (exact)',
              '${_signed(output.exposureRampStops)} stops',
            ),
            (
              'Maximum exposure duty cycle',
              '${(output.maximumDutyCycle * 100).toStringAsFixed(0)}%',
            ),
            ('Starting exposure', '${_controllers[4].text.trim()} s'),
            ('Ending exposure', '${_controllers[5].text.trim()} s'),
          ],
          inputs: [
            for (var index = 0; index < _fields.length; index++)
              (_fields[index].$1, _controllers[index].text.trim()),
          ],
          assumptions: const [
            'A frame is captured at both sequence endpoints',
            'File size remains constant across the sequence',
            'Camera write time and intervalometer latency are not modeled',
          ],
          guidance: output.maximumDutyCycle >= 1
              ? 'The longest exposure does not fit inside the interval. Increase the interval or shorten the exposure.'
              : 'Leave additional interval margin for image processing and storage writes.',
          warnings: <String>[
            for (final warning in _result!.warnings)
              calculationWarningText(warning.code),
          ],
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
          error.field: error.code == 'result_out_of_range'
              ? 'This duration and interval need more frames than the model can represent. Increase the interval.'
              : 'Enter a positive finite value.',
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
  String _signed(double value, {int fractionDigits = 2}) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(fractionDigits)}';
}

/// A duration a photographer can read at a glance, e.g. `1 h 30 min`.
///
/// The exact seconds stay in the result details; this is the human summary.
String _humanDuration(double seconds) {
  if (!seconds.isFinite) return 'Beyond the model';
  if (seconds < 1) return '${seconds.toStringAsFixed(2)} s';
  if (seconds < 60) return '${seconds.toStringAsFixed(1)} s';
  final total = seconds.round();
  if (total < 3600) {
    final minutes = total ~/ 60;
    final rest = total % 60;
    return rest == 0 ? '$minutes min' : '$minutes min $rest s';
  }
  if (total < 86400) {
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
  final days = total ~/ 86400;
  final hours = (total % 86400) ~/ 3600;
  return hours == 0 ? '$days d' : '$days d $hours h';
}
