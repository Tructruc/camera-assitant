import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../exposure_comparison/presentation/capture_field_controls.dart';
import '../domain/timelapse_calculator.dart';

/// Timelapse planner: how often the camera fires, for how long, and at what
/// playback rate - the three answers a photographer decides in the field.
///
/// Per-frame size and the exposure ramp are assumptions about the camera and
/// the light, not shot settings, so they stay one disclosure down with a
/// subtitle that says so.
class TimelapseScreen extends ConsumerStatefulWidget {
  const TimelapseScreen({super.key});
  @override
  ConsumerState<TimelapseScreen> createState() => _TimelapseScreenState();
}

class _TimelapseScreenState extends ConsumerState<TimelapseScreen> {
  /// Cadences a timelapse is usually shot at, in seconds.
  static const _intervals = <double>[1, 2, 5, 10, 15, 30, 60, 120];

  /// Capture lengths photographers plan in, RAW seconds (shown as minutes).
  static const _durations = <double>[300, 600, 1800, 3600, 7200, 14400];

  /// Playback rates in common use.
  static const _rates = <double>[12, 15, 24, 25, 30, 60];

  /// Typical per-frame sizes for a still camera, in megabytes.
  static const _frameSizes = <double>[20, 24, 30, 45, 60, 100];

  /// Ramp endpoints in seconds, from a fast sunset exposure to a long one.
  static const _exposures = <double>[0.25, 0.5, 1, 2, 4, 8, 15, 30];

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
    ('Capture duration', 'captureDurationSeconds'),
    ('Playback frame rate (fps)', 'playbackFps'),
    ('Estimated size per frame (MB)', 'megabytesPerFrame'),
    ('Starting exposure (seconds)', 'startExposureSeconds'),
    ('Ending exposure (seconds)', 'endExposureSeconds'),
  ];

  CalculationResult<TimelapseOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    // Seed the answer for the default plan so the screen opens on a result.
    _calculate();
  }

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
      _calculate();
    },
    onCalculate: _calculate,
    children: [
      const CalculatorHeader(
        icon: Icons.movie_creation_outlined,
        description:
            'Plan capture cadence, playback length, storage, and an exposure ramp.',
      ),
      const SizedBox(height: AppGap.lg),
      // Cadence, duration, and playback rate define the plan; per-frame size
      // and the exposure ramp refine it.
      CalculatorNumberField(
        label: _fields[0].$1,
        controller: _controllers[0],
        errorText: _errors[_fields[0].$2],
        fieldKey: Key('timelapse-${_fields[0].$2}'),
        presets: _intervals,
        min: 0.1,
        max: 3600,
        logarithmic: true,
        helperText: 'One frame every 1 s to 2 min covers most sequences',
      ),
      CalculatorNumberField(
        label: _fields[1].$1,
        controller: _controllers[1],
        errorText: _errors[_fields[1].$2],
        fieldKey: Key('timelapse-${_fields[1].$2}'),
        presets: _durations,
        // The controller is canonical seconds; the field, its presets and its
        // steppers are all read and written in minutes.
        displayDivisor: 60,
        displayUnit: 'min',
        min: 60,
        max: 86400,
        logarithmic: true,
        helperText: 'Entered in minutes; recorded in seconds',
      ),
      CalculatorNumberField(
        label: _fields[2].$1,
        controller: _controllers[2],
        errorText: _errors[_fields[2].$2],
        fieldKey: Key('timelapse-${_fields[2].$2}'),
        presets: _rates,
        min: 1,
        max: 120,
        helperText: '24, 25 and 30 are the usual delivery rates',
      ),
      const CaptureLiveHint(),
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
              (_fields[index].$1, _indexLabel(index)),
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
      CalculatorAdvancedSection(
        // Stable identity: applying equipment above must not collapse
        // the section the user is working in.
        key: const ValueKey('advanced'),
        subtitle: 'Assumed file size and the exposure ramp across the sequence',
        children: <Widget>[
          CalculatorNumberField(
            label: _fields[3].$1,
            controller: _controllers[3],
            errorText: _errors[_fields[3].$2],
            fieldKey: Key('timelapse-${_fields[3].$2}'),
            presets: _frameSizes,
            step: 1,
            min: 0.1,
            max: 512,
            helperText: 'What one frame occupies on the card',
          ),
          CalculatorFieldPair(
            first: CalculatorNumberField(
              label: _fields[4].$1,
              controller: _controllers[4],
              errorText: _errors[_fields[4].$2],
              fieldKey: Key('timelapse-${_fields[4].$2}'),
              presets: _exposures,
              min: 0.001,
              max: 3600,
              logarithmic: true,
            ),
            second: CalculatorNumberField(
              label: _fields[5].$1,
              controller: _controllers[5],
              errorText: _errors[_fields[5].$2],
              fieldKey: Key('timelapse-${_fields[5].$2}'),
              presets: _exposures,
              min: 0.001,
              max: 3600,
              logarithmic: true,
            ),
          ),
        ],
      ),
    ],
  );

  double _value(int index) =>
      double.tryParse(_controllers[index].text.trim()) ?? double.nan;

  /// The echo of one input in the result's "Values used" list.
  ///
  /// The capture duration is entered and displayed in minutes while the
  /// canonical value stays in seconds, so its echo names both rather than
  /// printing a bare number the reader has to guess the unit of.
  String _indexLabel(int index) => index == 1
      ? '${_humanDuration(_value(index))} · ${_controllers[index].text.trim()} s'
      : _controllers[index].text.trim();

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
    final errors = <String, String>{
      for (final error in result.errors)
        error.field: error.code == 'result_out_of_range'
            ? 'This duration and interval need more frames than the model can represent. Increase the interval.'
            : 'Enter a positive finite value.',
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
    // Reset is an input change too: without this the shown plan would still
    // describe the values the user just discarded.
    _calculate();
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
