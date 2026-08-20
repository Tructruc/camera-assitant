import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../domain/macro_calculator.dart';

class MacroScreen extends ConsumerStatefulWidget {
  const MacroScreen({super.key});
  @override
  ConsumerState<MacroScreen> createState() => _MacroScreenState();
}

class _MacroScreenState extends ConsumerState<MacroScreen> {
  var _configuration = MacroConfiguration.extensionTube;
  final _primaryFocal = TextEditingController(text: '50');
  final _reversedFocal = TextEditingController(text: '28');
  final _extension = TextEditingController(text: '25');
  final _nativeMagnification = TextEditingController(text: '0.2');
  final _flangeDistance = TextEditingController(text: '44');
  final _aperture = TextEditingController(text: '8');
  final _sensorWidth = TextEditingController(text: '36');
  CalculationResult<MacroOutput>? _result;
  Map<String, String> _errors = const {};
  Lens? _selectedPrimaryLens;
  Lens? _selectedReversedLens;
  OpticalAccessory? _selectedTube;

  @override
  void dispose() {
    for (final controller in [
      _primaryFocal,
      _reversedFocal,
      _extension,
      _nativeMagnification,
      _flangeDistance,
      _aperture,
      _sensorWidth,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(equipmentControllerProvider).items;
    final lenses = entries
        .where((entry) => entry.kind == EquipmentKind.lens)
        .map((entry) => entry.item)
        .whereType<Lens>()
        .toList();
    final tubes = entries
        .where((entry) => entry.kind == EquipmentKind.accessory)
        .map((entry) => entry.item)
        .whereType<OpticalAccessory>()
        .where((item) => item.kind == OpticalAccessoryKind.extensionTube)
        .toList();
    return CalculatorPage(
      children: [
        Text('Macro planner', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Compare extension tubes, a reversed lens, or two coupled lenses without implying calibrated optical precision.',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<MacroConfiguration>(
          decoration: const InputDecoration(labelText: 'Configuration'),
          initialValue: _configuration,
          items: const [
            DropdownMenuItem(
              value: MacroConfiguration.extensionTube,
              child: Text('Extension tube'),
            ),
            DropdownMenuItem(
              value: MacroConfiguration.reversedLens,
              child: Text('Reversed lens'),
            ),
            DropdownMenuItem(
              value: MacroConfiguration.coupledLenses,
              child: Text('Coupled lenses'),
            ),
          ],
          onChanged: (value) => setState(() {
            _configuration = value ?? _configuration;
            _result = null;
            _errors = const {};
            _selectedPrimaryLens = null;
            _selectedReversedLens = null;
            _selectedTube = null;
          }),
        ),
        const SizedBox(height: 12),
        if (_configuration != MacroConfiguration.reversedLens)
          EquipmentPicker<Lens>(
            label: 'Primary lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedPrimaryLens,
            onSelected: _applyPrimaryLens,
          ),
        if (_selectedPrimaryLens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            appliedValues: '${_primaryFocal.text} mm at f/${_aperture.text}',
          ),
        if (_configuration == MacroConfiguration.extensionTube) ...[
          EquipmentPicker<OpticalAccessory>(
            label: 'Saved extension tube (optional)',
            items: tubes,
            itemLabel: (item) => item.name,
            value: _selectedTube,
            onSelected: _applyTube,
          ),
          if (_selectedTube case final tube?)
            AppliedEquipmentNotice(
              equipmentName: tube.name,
              appliedValues: '${_extension.text} mm extension',
            ),
          CalculatorNumberField(
            label: 'Lens focal length (mm)',
            controller: _primaryFocal,
            errorText: _errors['focalLengthMm'],
          ),
          CalculatorNumberField(
            label: 'Extension length (mm)',
            controller: _extension,
            errorText: _errors['extensionLengthMm'],
          ),
          CalculatorNumberField(
            label: 'Lens native magnification (×)',
            controller: _nativeMagnification,
            errorText: _errors['nativeMagnification'],
          ),
        ],
        if (_configuration == MacroConfiguration.reversedLens) ...[
          EquipmentPicker<Lens>(
            label: 'Reversed lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedReversedLens,
            onSelected: _applyReversedLens,
          ),
          if (_selectedReversedLens case final lens?)
            AppliedEquipmentNotice(
              equipmentName: lens.name,
              appliedValues: '${_reversedFocal.text} mm reversed',
            ),
          CalculatorNumberField(
            label: 'Reversed lens focal length (mm)',
            controller: _reversedFocal,
            errorText: _errors['reversedFocalLengthMm'],
          ),
          CalculatorNumberField(
            label: 'Flange distance / extension (mm)',
            controller: _flangeDistance,
            errorText: _errors['flangeDistanceMm'],
          ),
        ],
        if (_configuration == MacroConfiguration.coupledLenses) ...[
          EquipmentPicker<Lens>(
            label: 'Reversed coupling lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedReversedLens,
            onSelected: _applyReversedLens,
          ),
          if (_selectedReversedLens case final lens?)
            AppliedEquipmentNotice(
              equipmentName: lens.name,
              appliedValues: '${_reversedFocal.text} mm reversed',
            ),
          CalculatorNumberField(
            label: 'Primary focal length (mm)',
            controller: _primaryFocal,
            errorText: _errors['primaryFocalLengthMm'],
          ),
          CalculatorNumberField(
            label: 'Reversed focal length (mm)',
            controller: _reversedFocal,
            errorText: _errors['reversedFocalLengthMm'],
          ),
        ],
        CalculatorNumberField(
          label: 'Nominal aperture (f-number)',
          controller: _aperture,
          errorText: _errors['nominalAperture'],
        ),
        CalculatorNumberField(
          label: 'Sensor width (mm)',
          controller: _sensorWidth,
          errorText: _errors['sensorWidthMm'],
        ),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Calculate macro setup'),
        ),
        const SizedBox(height: 16),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Macro estimate',
            rows: [
              ('Magnification', '${output.magnification.toStringAsFixed(2)}×'),
              (
                'Effective aperture',
                'f/${output.effectiveAperture.toStringAsFixed(1)}',
              ),
              (
                'Subject width across frame',
                '${output.subjectWidthMm.toStringAsFixed(1)} mm',
              ),
              (
                'Exposure compensation',
                '+${output.exposureCompensationStops.toStringAsFixed(2)} stops',
              ),
            ],
            assumptions: [
              '${_configurationLabel()} approximation',
              'Thin-lens geometry with pupil magnification 1',
              'Working distance and lens-specific internal focusing are not modeled',
            ],
            guidance:
                'Treat this as configuration guidance. Confirm framing, working distance, and exposure with the actual lenses.',
            onSave: () => _save(output),
            onReset: _reset,
          ),
      ],
    );
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;
  void _calculate() {
    final input = switch (_configuration) {
      MacroConfiguration.extensionTube => MacroInput.extensionTube(
        focalLengthMm: _value(_primaryFocal),
        extensionLengthMm: _value(_extension),
        nativeMagnification: _value(_nativeMagnification),
        nominalAperture: _value(_aperture),
        sensorWidthMm: _value(_sensorWidth),
      ),
      MacroConfiguration.reversedLens => MacroInput.reversedLens(
        reversedFocalLengthMm: _value(_reversedFocal),
        flangeDistanceMm: _value(_flangeDistance),
        nominalAperture: _value(_aperture),
        sensorWidthMm: _value(_sensorWidth),
      ),
      MacroConfiguration.coupledLenses => MacroInput.coupledLenses(
        primaryFocalLengthMm: _value(_primaryFocal),
        reversedFocalLengthMm: _value(_reversedFocal),
        nominalAperture: _value(_aperture),
        sensorWidthMm: _value(_sensorWidth),
      ),
    };
    final result = const MacroCalculator().calculate(input);
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors)
          error.field: error.code == 'non_negative_required'
              ? 'Enter zero or a positive finite value.'
              : 'Enter a positive finite value.',
      };
    });
  }

  void _applyPrimaryLens(Lens? lens) {
    setState(() {
      _selectedPrimaryLens = lens;
      if (lens != null) {
        _primaryFocal.text = lens.maximumFocalLengthMm.toString();
        _aperture.text =
            (lens.maximumFocalLengthMinimumAperture ??
                    lens.minimumAperture ??
                    8)
                .toString();
      }
    });
  }

  void _applyReversedLens(Lens? lens) {
    setState(() {
      _selectedReversedLens = lens;
      if (lens != null) {
        _reversedFocal.text = lens.minimumFocalLengthMm.toString();
      }
    });
  }

  void _applyTube(OpticalAccessory? tube) {
    setState(() {
      _selectedTube = tube;
      if (tube != null) _extension.text = tube.value.toString();
    });
  }

  Future<void> _save(MacroOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${MacroCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: MacroCalculator.id,
      formulaVersion: MacroCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title: '${_configurationLabel()} macro estimate',
      canonicalInputs: _canonicalInputs,
      canonicalOutputs: {
        'magnification': output.magnification,
        'effectiveAperture': output.effectiveAperture,
        'subjectWidthMm': output.subjectWidthMm,
        'exposureCompensationStops': output.exposureCompensationStops,
      },
      displayContext: const {'lengthUnit': 'millimetres'},
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
      equipment: [
        if (_selectedPrimaryLens case final lens?)
          _equipment(lens, SnapshotEquipmentType.lens, {
            'focalLengthMm': _value(_primaryFocal),
          }),
        if (_selectedReversedLens case final lens?)
          _equipment(lens, SnapshotEquipmentType.lens, {
            'focalLengthMm': _value(_reversedFocal),
          }),
        if (_selectedTube case final tube?)
          _equipment(tube, SnapshotEquipmentType.opticalAccessory, {
            'extensionLengthMm': _value(_extension),
          }),
      ],
    ),
  );
  AppliedEquipmentSnapshot _equipment(
    EquipmentItem item,
    SnapshotEquipmentType type,
    Map<String, Object?> values,
  ) => AppliedEquipmentSnapshot(
    id: item.id,
    type: type,
    name: item.name,
    source: item.provenance.source.name,
    note: item.provenance.note,
    values: values,
  );
  void _reset() {
    _primaryFocal.text = '50';
    _reversedFocal.text = '28';
    _extension.text = '25';
    _nativeMagnification.text = '0.2';
    _flangeDistance.text = '44';
    _aperture.text = '8';
    _sensorWidth.text = '36';
    setState(() {
      _result = null;
      _errors = const {};
      _selectedPrimaryLens = null;
      _selectedReversedLens = null;
      _selectedTube = null;
    });
  }

  String _configurationLabel() => switch (_configuration) {
    MacroConfiguration.extensionTube => 'Extension tube',
    MacroConfiguration.reversedLens => 'Reversed lens',
    MacroConfiguration.coupledLenses => 'Coupled lenses',
  };

  Map<String, Object?> get _canonicalInputs => switch (_configuration) {
    MacroConfiguration.extensionTube => {
      'configuration': _configuration.name,
      'focalLengthMm': _value(_primaryFocal),
      'extensionLengthMm': _value(_extension),
      'nativeMagnification': _value(_nativeMagnification),
      'nominalAperture': _value(_aperture),
      'sensorWidthMm': _value(_sensorWidth),
    },
    MacroConfiguration.reversedLens => {
      'configuration': _configuration.name,
      'reversedFocalLengthMm': _value(_reversedFocal),
      'flangeDistanceMm': _value(_flangeDistance),
      'nominalAperture': _value(_aperture),
      'sensorWidthMm': _value(_sensorWidth),
    },
    MacroConfiguration.coupledLenses => {
      'configuration': _configuration.name,
      'primaryFocalLengthMm': _value(_primaryFocal),
      'reversedFocalLengthMm': _value(_reversedFocal),
      'nominalAperture': _value(_aperture),
      'sensorWidthMm': _value(_sensorWidth),
    },
  };
}
