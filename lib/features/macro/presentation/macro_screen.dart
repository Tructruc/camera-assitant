import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../optics/presentation/optics_screens.dart';
import '../domain/macro_calculator.dart';

/// Macro configuration planning, organised around the physical setup.
///
/// The three configurations are a visible segmented choice, each showing the
/// two or three numbers that actually drive it; the sensor width and the
/// lens-native magnification are equipment specifications and stay behind the
/// advanced group.
class MacroScreen extends ConsumerStatefulWidget {
  const MacroScreen({super.key});
  @override
  ConsumerState<MacroScreen> createState() => _MacroScreenState();
}

class _MacroScreenState extends ConsumerState<MacroScreen> {
  static const _focalPresets = <double>[14, 20, 24, 28, 35, 50, 85, 100];
  static const _reversedPresets = <double>[20, 24, 28, 35, 50];
  static const _aperturePresets = <double>[
    1,
    1.4,
    2,
    2.8,
    4,
    5.6,
    8,
    11,
    16,
    22,
    32,
  ];
  static const _extensionPresets = <double>[10, 12, 16, 20, 25, 36, 50];
  static const _magnificationPresets = <double>[0.1, 0.2, 0.5, 1];
  static const _flangePresets = <double>[16, 18, 20, 44, 46.5];
  static const _sensorWidthPresets = <double>[17.3, 23.5, 36];
  // A full-frame-first body; the sensor width is a normal advanced input.
  static const _sensorWidthDefault = '36';

  static const _defaultPrimaryFocal = '50';
  static const _defaultReversedFocal = '28';
  static const _defaultExtension = '25';
  static const _defaultNativeMagnification = '0.2';
  static const _defaultFlangeDistance = '44';
  static const _defaultAperture = '8';

  var _configuration = MacroConfiguration.extensionTube;
  final _primaryFocal = TextEditingController(text: _defaultPrimaryFocal);
  final _reversedFocal = TextEditingController(text: _defaultReversedFocal);
  final _extension = TextEditingController(text: _defaultExtension);
  final _nativeMagnification = TextEditingController(
    text: _defaultNativeMagnification,
  );
  final _flangeDistance = TextEditingController(text: _defaultFlangeDistance);
  final _aperture = TextEditingController(text: _defaultAperture);
  final _sensorWidth = TextEditingController(text: _sensorWidthDefault);
  CalculationResult<MacroOutput>? _result;
  Map<String, String> _errors = const {};
  Lens? _selectedPrimaryLens;
  Lens? _selectedReversedLens;
  OpticalAccessory? _selectedTube;
  CameraBody? _selectedCamera;

  @override
  void initState() {
    super.initState();
    // Seed an answer so the screen opens on the default setup instead of a
    // blank slot; the post-frame calculation keeps it current afterwards.
    _calculate();
  }

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
    ref.watch(preferencesProvider);
    // activeItems, not items: the Kit kind filter belongs to the inventory and
    // must not take lenses, tubes or cameras away from this calculator.
    final entries = ref.watch(equipmentControllerProvider).activeItems;
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
    final cameras = entries
        .where((entry) => entry.kind == EquipmentKind.camera)
        .map((entry) => entry.item)
        .whereType<CameraBody>()
        .toList();
    return CalculatorPage(
      inputControllers: [
        _primaryFocal,
        _reversedFocal,
        _extension,
        _nativeMagnification,
        _flangeDistance,
        _aperture,
        _sensorWidth,
      ],
      // Value-equal signature: the configuration is part of it, because
      // choosing a mode changes the calculation even when no text changed.
      calculationKey: [
        _configuration.name,
        _lengthDisplay.name,
        _selectedPrimaryLens?.id ?? '',
        _selectedReversedLens?.id ?? '',
        _selectedTube?.id ?? '',
        _selectedCamera?.id ?? '',
      ].join('|'),
      onInputsChanged: () {
        // Cheap calculation, so the corrected answer is produced in the same
        // frame rather than invalidating the card and waiting for the
        // scheduled pass: an asynchronous gap would briefly show values that
        // no longer match the inputs.
        _calculate();
      },
      onCalculate: _calculate,
      children: [
        const CalculatorHeader(
          icon: Icons.local_florist_outlined,
          description:
              'Compare extension tubes, a reversed lens, or two coupled lenses without implying calibrated optical precision. '
              'Teleconverters are inventory-only: multiply the focal length you enter by the converter factor.',
        ),
        const SizedBox(height: 16),
        // Three modes: visible as segments instead of hidden in a dropdown.
        Semantics(
          container: true,
          label: 'Macro configuration',
          child: SegmentedButton<MacroConfiguration>(
            segments: const [
              ButtonSegment(
                value: MacroConfiguration.extensionTube,
                label: Text('Extension tube'),
              ),
              ButtonSegment(
                value: MacroConfiguration.reversedLens,
                label: Text('Reversed lens'),
              ),
              ButtonSegment(
                value: MacroConfiguration.coupledLenses,
                label: Text('Coupled lenses'),
              ),
            ],
            selected: {_configuration},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                _setConfiguration(selection.first),
          ),
        ),
        const SizedBox(height: AppGap.md),
        Text(
          _configurationDescription,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        // Each mode offers only the pickers that mean something in it. An
        // empty kit shows none of them, so manual entry is never displaced by
        // a picker with nothing to choose.
        if (_configuration == MacroConfiguration.coupledLenses &&
            lenses.isNotEmpty)
          EquipmentPicker<Lens>(
            label: 'Primary lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedPrimaryLens,
            onSelected: _applyPrimaryLens,
          ),
        if (_configuration == MacroConfiguration.coupledLenses)
          if (_selectedPrimaryLens case final lens?)
            AppliedEquipmentNotice(
              equipmentName: lens.name,
              sourceLabel: lens.provenance.source.label,
              appliedValues: '${_primaryFocal.text} mm at f/${_aperture.text}',
            ),
        if (_configuration == MacroConfiguration.reversedLens &&
            lenses.isNotEmpty)
          EquipmentPicker<Lens>(
            label: 'Reversed lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedReversedLens,
            onSelected: _applyReversedLens,
          ),
        if (_configuration == MacroConfiguration.coupledLenses &&
            lenses.isNotEmpty)
          EquipmentPicker<Lens>(
            label: 'Reversed coupling lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            value: _selectedReversedLens,
            onSelected: _applyReversedLens,
          ),
        if (_configuration != MacroConfiguration.extensionTube)
          if (_selectedReversedLens case final lens?)
            AppliedEquipmentNotice(
              equipmentName: lens.name,
              sourceLabel: lens.provenance.source.label,
              appliedValues: '${_reversedFocal.text} mm reversed',
            ),
        if (_configuration == MacroConfiguration.extensionTube &&
            tubes.isNotEmpty)
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
            sourceLabel: tube.provenance.source.label,
            appliedValues: '${_extension.text} mm extension',
          ),
        // A saved camera supplies the sensor width, so it sits with the setup
        // parameters instead of behind the advanced disclosure. It hides itself
        // when the kit holds no camera.
        if (cameras.isNotEmpty)
          EquipmentPicker<CameraBody>(
            label: 'Saved camera (optional)',
            items: cameras,
            itemLabel: (item) => item.name,
            value: _selectedCamera,
            onSelected: _applyCamera,
          ),
        if (_selectedCamera case final camera?)
          AppliedEquipmentNotice(
            equipmentName: camera.name,
            sourceLabel: camera.provenance.source.label,
            appliedValues: '${_sensorWidth.text} mm sensor width',
          ),
        ..._primaryFields,
        CalculatorNumberField(
          label: 'Nominal aperture (f-number)',
          controller: _aperture,
          errorText: _errors['nominalAperture'],
          // The steppers walk the standard f-stops; off-series apertures stay
          // available through exact typed entry.
          presets: _aperturePresets,
        ),
        const CalculatorLiveHint(),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Macro estimate',
            highlight: (
              'Subject width across frame',
              formatDisplayLength(output.subjectWidthMm, _lengthDisplay),
            ),
            highlightCaption:
                'At ${output.magnification.toStringAsFixed(2)}× magnification.',
            tiles: <(String, String)>[
              ('Magnification', '${output.magnification.toStringAsFixed(2)}×'),
              (
                'Effective aperture',
                'f/${output.effectiveAperture.toStringAsFixed(1)}',
              ),
              (
                'Exposure compensation',
                '+${output.exposureCompensationStops.toStringAsFixed(2)} stops',
              ),
            ],
            details: <(String, String)>[
              (
                'Subject width',
                '${output.subjectWidthMm.toStringAsFixed(2)} mm',
              ),
              ('Magnification', '${output.magnification.toStringAsFixed(4)}×'),
              (
                'Effective aperture',
                'f/${output.effectiveAperture.toStringAsFixed(2)}',
              ),
              (
                'Exposure compensation',
                '+${output.exposureCompensationStops.toStringAsFixed(3)} stops',
              ),
            ],
            inputs: _inputSummary,
            assumptions: [
              '${_configurationLabel()} approximation',
              'Thin-lens geometry with pupil magnification 1',
              'Working distance and lens-specific internal focusing are not modeled',
            ],
            guidance:
                'Treat this as configuration guidance. Confirm framing, working distance, and exposure with the actual lenses.',
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
          children: [
            CalculatorNumberField(
              label: 'Sensor width (mm)',
              controller: _sensorWidth,
              errorText: _errors['sensorWidthMm'],
              presets: _sensorWidthPresets,
              helperText: 'Active image area of the camera.',
            ),
            if (_configuration == MacroConfiguration.extensionTube) ...[
              CalculatorNumberField(
                label: 'Lens native magnification (×)',
                controller: _nativeMagnification,
                errorText: _errors['nativeMagnification'],
                presets: _magnificationPresets,
                helperText: 'From the lens specification; 0 for a bare lens.',
              ),
            ],
            if (_configuration == MacroConfiguration.reversedLens)
              CalculatorNumberField(
                label: 'Flange distance / extension (mm)',
                controller: _flangeDistance,
                errorText: _errors['flangeDistanceMm'],
                presets: _flangePresets,
                helperText:
                    'Mount registration distance, or the extension used with '
                    'the reversed lens.',
              ),
          ],
        ),
      ],
    );
  }

  /// The numbers the chosen configuration actually turns on.
  List<Widget> get _primaryFields => switch (_configuration) {
    MacroConfiguration.extensionTube => [
      CalculatorNumberField(
        label: 'Lens focal length (mm)',
        controller: _primaryFocal,
        errorText: _errors['focalLengthMm'],
        presets: _focalPresets,
      ),
      CalculatorNumberField(
        label: 'Extension length (mm)',
        controller: _extension,
        errorText: _errors['extensionLengthMm'],
        presets: _extensionPresets,
      ),
    ],
    MacroConfiguration.reversedLens => [
      CalculatorNumberField(
        label: 'Reversed lens focal length (mm)',
        controller: _reversedFocal,
        errorText: _errors['reversedFocalLengthMm'],
        presets: _reversedPresets,
      ),
      CalculatorNumberField(
        label: 'Extension length (mm)',
        controller: _flangeDistance,
        errorText: _errors['flangeDistanceMm'],
        presets: _extensionPresets,
      ),
    ],
    MacroConfiguration.coupledLenses => [
      CalculatorFieldPair(
        first: CalculatorNumberField(
          label: 'Primary focal length (mm)',
          controller: _primaryFocal,
          errorText: _errors['primaryFocalLengthMm'],
          presets: _focalPresets,
        ),
        second: CalculatorNumberField(
          label: 'Reversed focal length (mm)',
          controller: _reversedFocal,
          errorText: _errors['reversedFocalLengthMm'],
          presets: _reversedPresets,
        ),
      ),
    ],
  };

  /// Plain-language statement of what the chosen approximation assumes.
  String get _configurationDescription => switch (_configuration) {
    MacroConfiguration.extensionTube =>
      'A tube pushes the lens further from the sensor; extension and the '
          'lens-native magnification drive the result.',
    MacroConfiguration.reversedLens =>
      'The lens is mounted backwards on a bellows or tube; the flange '
          'distance sets the magnification.',
    MacroConfiguration.coupledLenses =>
      'A reversed lens is coupled to a primary lens; the focal-length ratio '
          'sets the magnification.',
  };

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;

  List<(String, String)> get _inputSummary => [
    ('Configuration', _configurationLabel()),
    if (_configuration != MacroConfiguration.reversedLens)
      ('Primary focal length', '${_primaryFocal.text.trim()} mm'),
    if (_configuration != MacroConfiguration.extensionTube)
      ('Reversed focal length', '${_reversedFocal.text.trim()} mm'),
    if (_configuration == MacroConfiguration.extensionTube) ...[
      ('Extension length', '${_extension.text.trim()} mm'),
      ('Native magnification', '${_nativeMagnification.text.trim()}×'),
    ],
    if (_configuration == MacroConfiguration.reversedLens)
      ('Flange distance', '${_flangeDistance.text.trim()} mm'),
    ('Nominal aperture', 'f/${_aperture.text.trim()}'),
    ('Sensor width', '${_sensorWidth.text.trim()} mm'),
  ];

  void _setConfiguration(MacroConfiguration configuration) {
    if (configuration == _configuration) return;
    setState(() {
      _configuration = configuration;
      // The pickers mean different things per mode; carrying a selection
      // across would silently apply the wrong item.
      _selectedPrimaryLens = null;
      _selectedReversedLens = null;
      _selectedTube = null;
    });
    // The mode is an input: recompute now so the answer shown always belongs
    // to the configuration that is selected.
    _calculate();
  }

  /// Recompute the shown answer from the current inputs.
  ///
  /// Called from `initState` (where `setState` is illegal) as well as from the
  /// page's live calculation hook, so the state write is inlined while the
  /// element is not mounted yet and goes through `setState` once it is.
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
    final errors = <String, String>{
      for (final error in result.errors)
        error.field: switch (error.code) {
          'non_negative_required' => 'Enter zero or a positive finite value.',
          'result_out_of_range' =>
            'These values produce a result outside the representable range. '
                'Reduce the extreme value and try again.',
          _ => 'Enter a positive finite value.',
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
    _calculate();
  }

  void _applyReversedLens(Lens? lens) {
    setState(() {
      _selectedReversedLens = lens;
      if (lens != null) {
        _reversedFocal.text = lens.minimumFocalLengthMm.toString();
      }
    });
    _calculate();
  }

  void _applyTube(OpticalAccessory? tube) {
    setState(() {
      _selectedTube = tube;
      if (tube != null) _extension.text = tube.value.toString();
    });
    _calculate();
  }

  void _applyCamera(CameraBody? camera) {
    setState(() {
      _selectedCamera = camera;
      if (camera != null) _sensorWidth.text = camera.sensorWidthMm.toString();
    });
    _calculate();
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
      displayContext: {'lengthUnit': _lengthDisplay.name},
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
        if (_selectedCamera case final camera?)
          _equipment(camera, SnapshotEquipmentType.camera, {
            'sensorWidthMm': camera.sensorWidthMm,
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
    _primaryFocal.text = _defaultPrimaryFocal;
    _reversedFocal.text = _defaultReversedFocal;
    _extension.text = _defaultExtension;
    _nativeMagnification.text = _defaultNativeMagnification;
    _flangeDistance.text = _defaultFlangeDistance;
    _aperture.text = _defaultAperture;
    _sensorWidth.text = _sensorWidthDefault;
    setState(() {
      _configuration = MacroConfiguration.extensionTube;
      _selectedPrimaryLens = null;
      _selectedReversedLens = null;
      _selectedTube = null;
      _selectedCamera = null;
    });
    // Reset is an input change like any other: the live answer must follow it
    // instead of still describing the values the user discarded.
    _calculate();
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

  LengthDisplay get _lengthDisplay =>
      ref.read(preferencesProvider).valueOrNull?.lengthDisplay ??
      LengthDisplay.metric;
}
