import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../../core/presentation/formatters/conventional_shutter_formatter.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../equipment/presentation/equipment_specs.dart';
import '../../exposure_comparison/presentation/capture_field_controls.dart';
import '../domain/long_exposure_calculator.dart';
import 'exposure_timer_panel.dart';

/// Long exposure / ND: the two controls a photographer actually works with -
/// the metered shutter and the filter stack - with the resulting exposure time
/// answered as either one changes.
///
/// A saved ND filter (and the whole kit) only fills the stack in; the stack
/// itself stays editable, and no kit means nothing optional is shown at all.
class LongExposureScreen extends ConsumerStatefulWidget {
  const LongExposureScreen({super.key});

  @override
  ConsumerState<LongExposureScreen> createState() => _LongExposureScreenState();
}

class _LongExposureScreenState extends ConsumerState<LongExposureScreen> {
  static const _defaultBase = '1/30';
  static const _defaultStops = '10';

  /// Full-stop shutters from 1/1000 s to 30 s: the range a metered base time
  /// and its filtered result are read from.
  static final List<(String, double)> _shutterStops = commonShutterStops
      .where((stop) => stop.$2 >= 0.001)
      .toList(growable: false);

  final _base = TextEditingController(text: _defaultBase);
  final _stops = TextEditingController(text: _defaultStops);
  final _target = TextEditingController();
  CalculationResult<LongExposureOutput>? _result;
  Map<String, String> _errors = const {};
  NdFilter? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Seed the answer for the default shot so the screen opens on a result
    // rather than an empty slot.
    _calculate();
  }

  @override
  void dispose() {
    _base.dispose();
    _stops.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences =
        ref.watch(preferencesProvider).valueOrNull ?? const AppPreferences();
    // activeItems, not items: the inventory's Kit kind filter must not empty
    // this picker of the saved ND filters.
    final filters = ref
        .watch(equipmentControllerProvider)
        .activeItems
        .where((entry) => entry.kind == EquipmentKind.filter)
        .map((entry) => entry.item)
        .whereType<NdFilter>()
        .toList(growable: false);
    final nearestStop = _nearestShutterStop();
    return CalculatorPage(
      inputControllers: [_base, _stops, _target],
      // Which filter supplied the stack is part of the result's provenance, so
      // it belongs in the value signature even when the numbers do not move.
      calculationKey: <String>[
        _selectedFilter?.id ?? '',
        _selectedFilter?.strengthStops.toString() ?? '',
        preferences.shutterDisplay.name,
        preferences.fractionStep.name,
      ].join('|'),
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
          icon: Icons.timer_outlined,
          description:
              'Meter a base shutter, stack ND filters, and read the exposure time you need.',
        ),
        const SizedBox(height: AppGap.lg),
        // The picker hides itself when the kit holds no filters: an optional
        // control with nothing to pick must not take a row.
        EquipmentPicker<NdFilter>(
          label: 'Saved ND filter (optional)',
          items: filters,
          itemLabel: (filter) => filter.name,
          itemDetail: filterSpecSummary,
          value: _selectedFilter,
          onSelected: _applyFilter,
        ),
        if (_selectedFilter case final filter?)
          AppliedEquipmentNotice(
            equipmentName: filter.name,
            sourceLabel: filter.provenance.source.label,
            // The calculation applies the editable field, which may already be
            // a one-off override of the saved filter strength.
            appliedValues: _stops.text.trim().isEmpty
                ? 'no stops applied yet'
                : '${_stops.text.trim()} stops applied',
          ),
        CaptureSectionHeading(
          title: 'Base shutter',
          caption: 'The metered time before any filter goes on.',
          action: _stopButtons(nearestStop),
        ),
        TextField(
          key: const Key('long-base'),
          controller: _base,
          style: Theme.of(context).textTheme.titleMedium,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Base shutter time (seconds)',
            // Photographers read shutters as fractions; the calculation still
            // receives seconds.
            helperText: 'Accepts 1/30, 1/125 or 0.008',
            errorText: _errors['baseTimeSeconds'],
          ),
        ),
        CaptureChipRow(
          caption: 'Full stops',
          chips: <Widget>[
            for (final (label, seconds) in _shutterStops)
              CaptureChoiceChip<double>(
                label: label,
                value: seconds,
                selected: matchesValue(_number(_base.text), seconds),
                tooltip: 'Set the base shutter to $label s',
                onSelected: _setBaseShutter,
              ),
          ],
        ),
        CaptureSectionHeading(
          title: 'ND filter stack',
          caption:
              'Stacked strengths add up; tap a strength to add or remove it.',
        ),
        TextField(
          key: const Key('long-stops'),
          controller: _stops,
          style: Theme.of(context).textTheme.titleMedium,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            labelText: 'ND filter strengths (stops)',
            helperText: 'Example: 3, 7',
            errorText: _filterError,
          ),
        ),
        const SizedBox(height: AppGap.sm),
        CaptureChipRow(
          trailing: _stops.text.trim().isEmpty
              ? null
              : TextButton(
                  onPressed: _clearStack,
                  child: const Text('Clear stack'),
                ),
          chips: <Widget>[
            for (final stops in commonNdStops)
              CaptureChoiceChip<double>(
                label: stops == 1
                    ? '1 stop'
                    : '${stops.toStringAsFixed(0)} stops',
                value: stops,
                selected: _stackHas(stops),
                tooltip:
                    '${_stackHas(stops) ? 'Remove' : 'Add'} '
                    '${stops.toStringAsFixed(0)} stops of ND',
                onSelected: _toggleStack,
              ),
          ],
        ),
        const CaptureLiveHint(),
        // The timer is offered with the answer it would time: above the full
        // result details, with the filter stack that produced it. It is absent
        // whenever the calculation is invalid, so nothing ever offers to time a
        // number that does not exist, and the canonical filtered seconds - not
        // the rounded display - are what the panel is handed.
        if (_result?.output case final output?)
          ExposureTimerAction(seconds: output.filteredTime.seconds),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Long exposure result',
            highlight: (
              'Filtered exposure time',
              _humanDuration(output.filteredTime.seconds),
            ),
            highlightCaption:
                'From ${_baseLabel()} at '
                '${output.totalStrength.stops.toStringAsFixed(0)} stops of ND.',
            tiles: <(String, String)>[
              if (preferences.shutterDisplay == ShutterDisplay.conventional)
                (
                  // The label a photographer actually dials in. In exact mode
                  // the hero already carries the time and the six-decimal
                  // string would be noise.
                  'Shutter to set',
                  _shutterLabel(output, preferences),
                ),
              (
                'Total ND strength',
                '${output.totalStrength.stops.toStringAsFixed(1)} stops',
              ),
              if (output.requiredStrength case final required?)
                (
                  'Required strength',
                  '${required.stops.toStringAsFixed(1)} stops',
                ),
              (
                'Shutter mode',
                output.requiresBulbOrTimer ? 'Bulb or timer' : 'Standard range',
              ),
            ],
            details: <(String, String)>[
              (
                'Filtered time (exact)',
                '${output.filteredTime.seconds.toStringAsFixed(6)} s',
              ),
              ('Shutter display', _shutterLabel(output, preferences)),
              (
                'Base time (exact)',
                _base.text.contains('/')
                    ? '${_base.text.trim()} · '
                          '${_number(_base.text).toStringAsFixed(6)} s'
                    : '${_number(_base.text).toStringAsFixed(6)} s',
              ),
              (
                'Total ND strength (exact)',
                '${output.totalStrength.stops.toStringAsFixed(2)} stops',
              ),
              if (output.requiredStrength case final required?)
                (
                  'Required strength (exact)',
                  '${required.stops.toStringAsFixed(2)} stops',
                ),
            ],
            inputs: <(String, String)>[
              ('Base shutter time', '${_base.text.trim()} s'),
              ('ND filter strengths', '${_stops.text.trim()} stops'),
              if (_target.text.trim().isNotEmpty)
                ('Target time', '${_target.text.trim()} s'),
            ],
            assumptions: const <String>[
              'Each ND stop doubles exposure time',
              'Stacked filters use ideal multiplicative attenuation',
            ],
            guidance: output.requiresBulbOrTimer
                ? 'Use Bulb or timer mode; conventional shutter ranges usually end at 30 seconds.'
                : 'Use the nearest supported shutter time and review the raw value.',
            onSave: () => _save(output, preferences),
            onReset: _reset,
          ),
        // A target time only reframes the answer; the exposure itself comes
        // from the base time and the stacked filters. It stays one disclosure
        // down, where the convention lives.
        CalculatorAdvancedSection(
          key: const ValueKey('advanced'),
          subtitle:
              'A target time never changes the exposure, only the framing',
          children: <Widget>[
            CalculatorNumberField(
              label: 'Optional target time (seconds)',
              controller: _target,
              errorText: _errors['targetTimeSeconds'],
              presets: const <double>[1, 2, 4, 8, 15, 30, 60, 120, 300],
              step: 1,
              min: 0.001,
              max: 86400,
              logarithmic: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Whole-stop stepping on the dial's own values.
  ///
  /// A wrapped pair rather than a row, so it re-flows instead of squeezing at
  /// 200 percent text, and it sits with the heading so the chips below stay
  /// next to the field they write.
  Widget _stopButtons(int? nearestStop) => Wrap(
    spacing: AppGap.sm,
    runSpacing: AppGap.xs,
    children: <Widget>[
      Tooltip(
        message: 'One stop faster: half the shutter time',
        child: OutlinedButton(
          onPressed: nearestStop == null || nearestStop == 0
              ? null
              : () => _stepShutter(-1),
          child: const Text('-1 stop'),
        ),
      ),
      Tooltip(
        message: 'One stop slower: double the shutter time',
        child: OutlinedButton(
          onPressed:
              nearestStop == null || nearestStop == _shutterStops.length - 1
              ? null
              : () => _stepShutter(1),
          child: const Text('+1 stop'),
        ),
      ),
    ],
  );

  /// The shutter wording the result and the snapshot both report.
  String _shutterLabel(LongExposureOutput output, AppPreferences preferences) =>
      preferences.shutterDisplay == ShutterDisplay.conventional
      ? formatConventionalShutter(
          output.filteredTime.seconds,
          preferences.fractionStep,
        )
      : '${output.filteredTime.seconds.toStringAsFixed(6)} seconds';

  String? get _filterError {
    for (final entry in _errors.entries) {
      // A per-filter error is indexed; an error about the stack as a whole uses
      // the bare field name.
      if (entry.key == 'filters' || entry.key.startsWith('filters[')) {
        return entry.value;
      }
    }
    return null;
  }

  /// The index of the full stop the base shutter is nearest to, or null when
  /// the field does not hold a usable time.
  int? _nearestShutterStop() {
    final seconds = _number(_base.text);
    if (!seconds.isFinite || seconds <= 0) return null;
    var nearest = 0;
    var smallest = double.infinity;
    for (var index = 0; index < _shutterStops.length; index++) {
      final distance = (math.log(seconds / _shutterStops[index].$2)).abs();
      if (distance < smallest) {
        smallest = distance;
        nearest = index;
      }
    }
    return nearest;
  }

  /// Move the base shutter one whole stop, in the dial's own values.
  void _stepShutter(int direction) {
    final nearest = _nearestShutterStop();
    if (nearest == null) return;
    final next = nearest + direction;
    if (next < 0 || next >= _shutterStops.length) return;
    _base.text = familiarShutterValue(_shutterStops[next].$2);
  }

  void _setBaseShutter(double seconds) {
    _base.text = familiarShutterValue(seconds);
  }

  bool _stackHas(double stops) => _stops.text
      .split(',')
      .map((token) => double.tryParse(token.trim()))
      .any((value) => matchesValue(value, stops));

  /// Toggle one strength in the stack without touching the keyboard.
  void _toggleStack(double stops) {
    _stops.text = toggledNdStack(_stops.text, stops).join(', ');
  }

  void _clearStack() {
    _stops.text = '';
  }

  void _applyFilter(NdFilter? filter) {
    setState(() {
      _result = null;
      _selectedFilter = filter;
      if (filter != null) {
        _stops.text = filter.strengthStops.toString();
      }
    });
    // Applying a saved filter is an input change: the answer must be the one
    // for the stack that is now in the field.
    _calculate();
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
    final errors = <String, String>{
      for (final error in result.errors)
        error.field: switch (error.code) {
          'target_shorter_than_base' =>
            'Target time must not be shorter than base time.',
          'result_out_of_range' =>
            'This stack of filters overflows the exposure time. Reduce the stacked strength.',
          _ => 'Enter a valid non-negative ND value.',
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

  Future<void> _save(
    LongExposureOutput output,
    AppPreferences preferences,
  ) async {
    final result = _result!;
    final filters = _stops.text.trim().isEmpty
        ? <double>[]
        : _stops.text.split(',').map((item) => _number(item)).toList();
    await saveCalculationSnapshot(
      context,
      ref,
      CalculationSnapshot(
        id: '${LongExposureCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
        calculatorId: LongExposureCalculator.id,
        formulaVersion: LongExposureCalculator.version,
        createdAt: DateTime.now().toUtc(),
        title: 'Long exposure result',
        canonicalInputs: <String, Object?>{
          'baseTimeSeconds': _number(_base.text),
          'filterStops': filters,
          'targetTimeSeconds': _target.text.trim().isEmpty
              ? null
              : _number(_target.text),
        },
        canonicalOutputs: <String, Object?>{
          'filteredTimeSeconds': output.filteredTime.seconds,
          'totalStrengthStops': output.totalStrength.stops,
          'requiredStrengthStops': output.requiredStrength?.stops,
          'requiresBulbOrTimer': output.requiresBulbOrTimer,
        },
        displayContext: <String, Object?>{
          'shutterDisplay': preferences.shutterDisplay.name,
          'fractionStep': preferences.fractionStep.name,
          'shutterLabel': _shutterLabel(output, preferences),
          'secondsPrecision': 6,
        },
        assumptions: result.assumptions,
        warnings: result.warnings,
        equipment: <AppliedEquipmentSnapshot>[
          if (_selectedFilter case final filter?)
            AppliedEquipmentSnapshot(
              id: filter.id,
              type: SnapshotEquipmentType.filter,
              name: filter.name,
              source: filter.provenance.source.name,
              note: filter.provenance.note,
              values: <String, Object?>{
                'strengthStops': filter.strengthStops,
                'opticalDensity': filter.opticalDensity,
                'filterFactor': filter.filterFactor,
              },
            ),
        ],
      ),
    );
  }

  /// The base shutter as the user typed it when it is a fraction, otherwise a
  /// human duration: an entered `0.0333333333333333` is not a caption.
  String _baseLabel() => _base.text.contains('/')
      ? '${_base.text.trim()} s'
      : _humanDuration(_number(_base.text));

  void _reset() {
    _base.text = _defaultBase;
    _stops.text = _defaultStops;
    _target.clear();
    setState(() {
      _selectedFilter = null;
    });
    // Reset is an input change too: without this the shown answer would still
    // describe the values the user just discarded.
    _calculate();
  }
}

double _number(String text) {
  final trimmed = text.trim();
  final slash = trimmed.indexOf('/');
  if (slash > 0) {
    final numerator = double.tryParse(trimmed.substring(0, slash).trim());
    final denominator = double.tryParse(trimmed.substring(slash + 1).trim());
    if (numerator == null || denominator == null || denominator == 0) {
      return double.nan;
    }
    return numerator / denominator;
  }
  return double.tryParse(trimmed) ?? double.nan;
}

/// A duration a photographer can read at a glance, e.g. `4 min 16 s`.
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
