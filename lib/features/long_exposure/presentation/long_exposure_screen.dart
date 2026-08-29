import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../../core/presentation/formatters/conventional_shutter_formatter.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../domain/long_exposure_calculator.dart';

class LongExposureScreen extends ConsumerStatefulWidget {
  const LongExposureScreen({super.key});

  @override
  ConsumerState<LongExposureScreen> createState() => _LongExposureScreenState();
}

class _LongExposureScreenState extends ConsumerState<LongExposureScreen> {
  final _base = TextEditingController(text: '0.0333333333');
  final _stops = TextEditingController(text: '10');
  final _target = TextEditingController();
  CalculationResult<LongExposureOutput>? _result;
  Map<String, String> _errors = const {};
  NdFilter? _selectedFilter;

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
    final filters = ref
        .watch(equipmentControllerProvider)
        .items
        .where((entry) => entry.kind == EquipmentKind.filter)
        .map((entry) => entry.item)
        .whereType<NdFilter>()
        .toList(growable: false);
    return CalculatorPage(
      children: <Widget>[
        Text(
          'Long exposure / ND',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Enter stacked ND strengths as comma-separated stops.'),
        const SizedBox(height: 16),
        EquipmentPicker<NdFilter>(
          label: 'Saved ND filter (optional)',
          items: filters,
          itemLabel: (filter) => filter.name,
          value: _selectedFilter,
          onSelected: (filter) {
            setState(() {
              _selectedFilter = filter;
              if (filter != null) {
                _stops.text = filter.strengthStops.toString();
              }
            });
          },
        ),
        if (_selectedFilter case final filter?)
          AppliedEquipmentNotice(
            equipmentName: filter.name,
            appliedValues: '${filter.strengthStops} stops',
          ),
        const SizedBox(height: 12),
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
            title: preferences.shutterDisplay == ShutterDisplay.conventional
                ? formatConventionalShutter(
                    output.filteredTime.seconds,
                    preferences.fractionStep,
                  )
                : '${output.filteredTime.seconds.toStringAsFixed(6)} seconds',
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
            onSave: () => _save(output, preferences),
            onReset: _reset,
          ),
      ],
    );
  }

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
          'shutterLabel':
              preferences.shutterDisplay == ShutterDisplay.conventional
              ? formatConventionalShutter(
                  output.filteredTime.seconds,
                  preferences.fractionStep,
                )
              : '${output.filteredTime.seconds.toStringAsFixed(6)} seconds',
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

  void _reset() {
    _base.text = '0.0333333333';
    _stops.text = '10';
    _target.clear();
    setState(() {
      _result = null;
      _errors = const {};
      _selectedFilter = null;
    });
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
