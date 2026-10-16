import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../domain/exposure_calculator.dart';
import 'capture_field_controls.dart';

/// Exposure comparison, laid out the way the two setups are metered: the
/// baseline (A) the photographer already trusts, then the candidate (B), with
/// the stop difference answered as the settings change.
///
/// Both triples are direct camera settings - aperture, shutter, ISO - named the
/// way they are written on a camera, so the A/B pair reads as a shot list
/// instead of a form.
class ExposureComparisonScreen extends ConsumerStatefulWidget {
  const ExposureComparisonScreen({super.key});

  @override
  ConsumerState<ExposureComparisonScreen> createState() =>
      _ExposureComparisonScreenState();
}

class _ExposureComparisonScreenState
    extends ConsumerState<ExposureComparisonScreen> {
  /// Full-stop apertures a photographer reaches for. The field's steppers walk
  /// exactly this list, so they move f/8 to f/11 instead of counting f/9, f/10.
  static const _apertures = <double>[1, 1.4, 2, 2.8, 4, 5.6, 8, 11, 16, 22, 32];

  /// Standard ISO settings.
  static const _isos = <double>[100, 200, 400, 800, 1600, 3200];

  /// Full-stop shutters in the range an ambient comparison is usually made in.
  /// The controller keeps RAW seconds; the chips carry the dial wording.
  static final List<(String, double)> _shutters = commonShutterStops
      .where((stop) => stop.$2 >= 0.002 && stop.$2 <= 1)
      .toList(growable: false);

  static const _defaults = <String>['4', '0.008', '100', '4', '0.008', '100'];

  static const _fields = <(String, String)>[
    ('Baseline aperture (f-number)', 'baseline.aperture'),
    ('Baseline shutter (seconds)', 'baseline.timeSeconds'),
    ('Baseline ISO', 'baseline.iso'),
    ('Candidate aperture (f-number)', 'candidate.aperture'),
    ('Candidate shutter (seconds)', 'candidate.timeSeconds'),
    ('Candidate ISO', 'candidate.iso'),
  ];

  /// How many of [_fields] describe the reference exposure.
  static const baselineFieldCount = 3;

  final _controllers = <TextEditingController>[
    for (final value in _defaults) TextEditingController(text: value),
  ];
  CalculationResult<ExposureComparisonOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    // Seed the answer so the screen opens on the common case - two identical
    // settings read as equivalent - instead of an empty slot.
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
    // Both sides are one calculation over the same six controllers, so every
    // edit belongs to the same live answer.
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
    children: <Widget>[
      const CalculatorHeader(
        icon: Icons.exposure,
        description:
            'Compare how aperture, shutter time, and ISO change exposure.',
      ),
      const SizedBox(height: AppGap.lg),
      // A is the reference the comparison is judged against, so it keeps the
      // standard camera values visible; B is a deliberate alternative and
      // carries the same controls one copy down.
      const CaptureSectionHeading(
        title: 'Baseline (A)',
        caption: 'The settings you are shooting now.',
      ),
      _apertureField(0, _fields[0].$1),
      _shutterField(1, _fields[1].$1),
      _isoField(2, _fields[2].$1),
      CaptureSectionHeading(
        title: 'Candidate (B)',
        caption: 'The change you are considering.',
        action: TextButton.icon(
          onPressed: _copyBaselineToCandidate,
          icon: const Icon(Icons.content_copy_outlined, size: 18),
          label: const Text('Use A for B'),
        ),
      ),
      _apertureField(3, _fields[3].$1),
      _shutterField(4, _fields[4].$1),
      _isoField(5, _fields[5].$1),
      const CaptureLiveHint(),
      // The candidate triple was a collapsed "Candidate settings" group. It is
      // shown directly now: the two sides have to be readable together for the
      // comparison to mean anything, and nothing was removed to do it.
      if (_result?.output case final output?)
        CalculationResultView(
          title: switch (output.direction) {
            ExposureDirection.brighter => 'Candidate is brighter',
            ExposureDirection.equivalent => 'Equivalent exposure',
            ExposureDirection.darker => 'Candidate is darker',
          },
          highlight: (
            'Total difference',
            _heroStops(output.totalDifference.stops),
          ),
          highlightCaption: _caption(output),
          tiles: <(String, String)>[
            ('Aperture', _signedStops(output.apertureContribution.stops)),
            ('Shutter', _signedStops(output.timeContribution.stops)),
            ('ISO', _signedStops(output.isoContribution.stops)),
          ],
          details: <(String, String)>[
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
            (
              'Exposure multiplier (exact)',
              '${output.multiplier.toStringAsFixed(2)}×',
            ),
          ],
          inputs: [
            for (var index = 0; index < _fields.length; index++)
              (_fields[index].$1, _controllers[index].text.trim()),
          ],
          assumptions: const <String>[
            'Each stop doubles or halves exposure',
            'Scene light and transmission remain unchanged',
          ],
          guidance:
              'Limitation: this comparison ignores lens transmission, sensor noise behaviour, '
              'reciprocity failure on long exposures, and any change in scene light or flash '
              'output between the two settings.',
          onSave: () => _save(output),
          onReset: _reset,
        ),
    ],
  );

  Widget _apertureField(int index, String label) => CalculatorNumberField(
    label: label,
    controller: _controllers[index],
    errorText: _errors[_fields[index].$2],
    // Presets are the only stepping here. An aperture slider added no control a
    // photographer does not already have from the standard stops, and exact
    // entry outside the series is still accepted.
    presets: _apertures,
  );

  /// Shutter seconds with the dial's own wording one rail away.
  ///
  /// The field keeps exact numeric entry (the canonical unit is seconds), and
  /// the chip rail writes those same seconds through the same controller. A
  /// continuous slider is deliberately absent: it repeats the dial the rail
  /// already carries, and on a phone its row is what pushed the answer off the
  /// screen.
  Widget _shutterField(int index, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      CalculatorNumberField(
        label: label,
        controller: _controllers[index],
        errorText: _errors[_fields[index].$2],
        helperText: 'Seconds - 0.008 is 1/125 s',
      ),
      CaptureChipRow(
        caption: 'Full stops',
        chips: <Widget>[
          for (final (chipLabel, seconds) in _shutters)
            CaptureChoiceChip<double>(
              label: chipLabel,
              value: seconds,
              selected: matchesValue(
                _number(_controllers[index].text),
                seconds,
              ),
              tooltip: 'Set $label to $chipLabel s',
              onSelected: (value) => _setShutter(index, value),
            ),
        ],
      ),
    ],
  );

  /// ISO with the standard settings as one-tap presets.
  ///
  /// Exact entry is unchanged, and the presets already step the field; the
  /// redundant continuous slider was removed with the shutter one.
  Widget _isoField(int index, String label) => CalculatorNumberField(
    label: label,
    controller: _controllers[index],
    errorText: _errors[_fields[index].$2],
    presets: _isos,
  );

  void _setShutter(int index, double seconds) {
    _controllers[index].text = shutterSecondsText(seconds);
  }

  /// Copy A's three settings into B, through the same controllers.
  void _copyBaselineToCandidate() {
    for (var index = 0; index < baselineFieldCount; index++) {
      _controllers[baselineFieldCount + index].text = _controllers[index].text;
    }
  }

  /// The direction in words plus the A/B pair the stop figure came from.
  String _caption(ExposureComparisonOutput output) {
    final direction = switch (output.direction) {
      ExposureDirection.equivalent => 'Both settings give the same exposure.',
      ExposureDirection.brighter =>
        'Candidate is ${_linearFactor(output.multiplier)} brighter.',
      ExposureDirection.darker =>
        'Candidate is ${_linearFactor(output.multiplier)} darker.',
    };
    return '$direction\nA ${_triple(0)}  →  B ${_triple(baselineFieldCount)}';
  }

  /// One setup as a photographer writes it: `f/4 · 1/125 s · ISO 100`.
  String _triple(int start) => <String>[
    'f/${textFromCanonicalValue(_number(_controllers[start].text))}',
    '${familiarShutterValue(_number(_controllers[start + 1].text))} s',
    'ISO ${textFromCanonicalValue(_number(_controllers[start + 2].text))}',
  ].join(' · ');

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
    final errors = <String, String>{
      for (final error in result.errors)
        error.field: error.code == 'result_out_of_range'
            ? 'This pair of settings differs by more stops than the model can represent.'
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

  Future<void> _save(ExposureComparisonOutput output) async {
    final result = _result!;
    final values = _controllers.map((item) => _number(item.text)).toList();
    await saveCalculationSnapshot(
      context,
      ref,
      CalculationSnapshot(
        id: '${ExposureCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
        calculatorId: ExposureCalculator.id,
        formulaVersion: ExposureCalculator.version,
        createdAt: DateTime.now().toUtc(),
        title: 'Exposure comparison result',
        canonicalInputs: <String, Object?>{
          'baseline': <String, Object?>{
            'aperture': values[0],
            'timeSeconds': values[1],
            'iso': values[2],
          },
          'candidate': <String, Object?>{
            'aperture': values[3],
            'timeSeconds': values[4],
            'iso': values[5],
          },
        },
        canonicalOutputs: <String, Object?>{
          'totalDifferenceStops': output.totalDifference.stops,
          'apertureContributionStops': output.apertureContribution.stops,
          'timeContributionStops': output.timeContribution.stops,
          'isoContributionStops': output.isoContribution.stops,
          'multiplier': output.multiplier,
          'direction': output.direction.name,
        },
        displayContext: const <String, Object?>{
          'stopPrecision': 2,
          'multiplierPrecision': 2,
        },
        assumptions: result.assumptions,
        warnings: result.warnings,
      ),
    );
  }

  void _reset() {
    for (var index = 0; index < _defaults.length; index++) {
      _controllers[index].text = _defaults[index];
    }
    setState(() {
      _result = null;
      _errors = const {};
    });
    // Reset is an input change too: without this the shown answer would still
    // describe the values the user just discarded.
    _calculate();
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;

/// The hero number: one rounded stop figure a photographer can act on.
String _heroStops(double stops) => stops == 0
    ? '0.0 stops'
    : '${stops > 0 ? '+' : ''}${stops.toStringAsFixed(1)} stops';

/// A tile-sized contribution, rounded to one decimal place.
String _signedStops(double stops) =>
    '${stops > 0 ? '+' : ''}${stops.toStringAsFixed(1)} stops';

String _linearFactor(double multiplier) => multiplier >= 10
    ? '${multiplier.toStringAsFixed(0)}×'
    : '${multiplier.toStringAsFixed(1)}×';
