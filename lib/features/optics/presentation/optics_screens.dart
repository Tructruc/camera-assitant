import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/validation/validation.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../domain/optics_calculators.dart';

enum _OpticsTool { fieldOfView, diffraction, focusStack }

class FieldOfViewScreen extends _OpticsScreen {
  const FieldOfViewScreen({super.key}) : super(tool: _OpticsTool.fieldOfView);
}

class DiffractionScreen extends _OpticsScreen {
  const DiffractionScreen({super.key}) : super(tool: _OpticsTool.diffraction);
}

class FocusStackScreen extends _OpticsScreen {
  const FocusStackScreen({super.key}) : super(tool: _OpticsTool.focusStack);
}

class _OpticsScreen extends ConsumerStatefulWidget {
  const _OpticsScreen({required this.tool, super.key});
  final _OpticsTool tool;
  @override
  ConsumerState<_OpticsScreen> createState() => _OpticsScreenState();
}

class _OpticsScreenState extends ConsumerState<_OpticsScreen> {
  late final List<TextEditingController> _controllers;
  Map<String, String> _errors = const {};
  List<(String, String)>? _details;
  (String, String) _highlight = const ('', '');
  String _caption = '';
  List<(String, String)> _tiles = const [];
  List<String> _assumptions = const [];
  List<CalculationWarning> _warnings = const [];
  String _guidance = '';
  Map<String, Object?> _outputs = const {};
  CameraBody? _camera;
  Lens? _lens;

  List<(String, String, String)> get _fields => switch (widget.tool) {
    _OpticsTool.fieldOfView => const [
      ('Sensor width (mm)', '36', 'sensorWidthMm'),
      ('Sensor height (mm)', '24', 'sensorHeightMm'),
      ('Focal length (mm)', '50', 'focalLengthMm'),
      ('Subject distance (mm)', '10000', 'distanceMm'),
    ],
    _OpticsTool.diffraction => const [
      ('Aperture (f-number)', '8', 'aperture'),
      ('Wavelength (nm)', '550', 'wavelengthNm'),
      ('Pixel pitch (µm)', '4', 'pixelPitchMicrometres'),
    ],
    _OpticsTool.focusStack => const [
      ('Focal length (mm)', '100', 'focalLengthMm'),
      ('Aperture (f-number)', '8', 'aperture'),
      ('Circle of confusion (mm)', '0.03', 'circleOfConfusionMm'),
      ('Near distance (mm)', '500', 'nearDistanceMm'),
      ('Far distance (mm)', '1000', 'farDistanceMm'),
      ('Overlap (%)', '20', 'overlapPercent'),
    ],
  };
  String get _title => switch (widget.tool) {
    _OpticsTool.fieldOfView => 'Field of view',
    _OpticsTool.diffraction => 'Diffraction guidance',
    _OpticsTool.focusStack => 'Focus stack planner',
  };
  String get _description => switch (widget.tool) {
    _OpticsTool.fieldOfView =>
      'Estimate rectilinear viewing angles and coverage at a distance.',
    _OpticsTool.diffraction =>
      'Compare the Airy disk with your sensor pixel pitch.',
    _OpticsTool.focusStack =>
      'Generate ordered focus distances with controlled overlap.',
  };

  /// The same icon the catalog tile uses, so the two always agree.
  IconData get _icon => switch (widget.tool) {
    _OpticsTool.fieldOfView => Icons.aspect_ratio,
    _OpticsTool.diffraction => Icons.blur_circular,
    _OpticsTool.focusStack => Icons.layers_outlined,
  };

  /// The two or three inputs a photographer sets for this tool, paired where
  /// the pair reads together (near/far, focal/aperture). Everything else —
  /// sensor dimensions, wavelength, circle of confusion, overlap — is a
  /// convention or a preference and stays behind one expander.
  List<Widget> get _primaryFields => switch (widget.tool) {
    _OpticsTool.fieldOfView => [
      CalculatorFieldPair(first: _fieldFor(2), second: _fieldFor(3)),
    ],
    _OpticsTool.diffraction => [
      CalculatorFieldPair(first: _fieldFor(0), second: _fieldFor(2)),
    ],
    _OpticsTool.focusStack => [
      CalculatorFieldPair(first: _fieldFor(0), second: _fieldFor(1)),
      CalculatorFieldPair(first: _fieldFor(3), second: _fieldFor(4)),
    ],
  };

  List<Widget> get _advancedFields => switch (widget.tool) {
    _OpticsTool.fieldOfView => [
      CalculatorFieldPair(first: _fieldFor(0), second: _fieldFor(1)),
    ],
    _OpticsTool.diffraction => [_fieldFor(1)],
    _OpticsTool.focusStack => [
      CalculatorFieldPair(first: _fieldFor(2), second: _fieldFor(5)),
    ],
  };

  Widget _fieldFor(int index) => CalculatorNumberField(
    label: _fields[index].$1,
    controller: _controllers[index],
    errorText: _errors[_fields[index].$3],
    fieldKey: Key('${widget.tool.name}-${_fields[index].$3}'),
  );

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final field in _fields) TextEditingController(text: field.$2),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(preferencesProvider);
    final equipment = ref.watch(equipmentControllerProvider).items;
    final cameras = equipment
        .where((entry) => entry.kind == EquipmentKind.camera)
        .map((entry) => entry.item)
        .whereType<CameraBody>()
        .toList();
    final lenses = equipment
        .where((entry) => entry.kind == EquipmentKind.lens)
        .map((entry) => entry.item)
        .whereType<Lens>()
        .toList();
    return CalculatorPage(
      inputControllers: _controllers,
      onInputsChanged: () {
        if (_details != null || _errors.isNotEmpty) {
          setState(() {
            _details = null;
            _errors = const {};
          });
        }
      },
      children: [
        CalculatorHeader(icon: _icon, description: _description),
        const SizedBox(height: 16),
        EquipmentPicker<Lens>(
          label: 'Saved lens (optional)',
          items: lenses,
          itemLabel: (item) => item.name,
          value: _lens,
          onSelected: _applyLens,
        ),
        if (_lens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            sourceLabel: lens.provenance.source.label,
            appliedValues: _lensAppliedValues,
          ),
        ..._primaryFields,
        CalculatorAdvancedSection(
          // Stable identity: applying equipment above must not collapse
          // the section the user is working in.
          key: const ValueKey('advanced'),
          children: [
            if (widget.tool != _OpticsTool.diffraction) ...[
              EquipmentPicker<CameraBody>(
                label: 'Saved camera (optional)',
                items: cameras,
                itemLabel: (item) => item.name,
                value: _camera,
                onSelected: _applyCamera,
              ),
              if (_camera case final camera?)
                AppliedEquipmentNotice(
                  equipmentName: camera.name,
                  sourceLabel: camera.provenance.source.label,
                  appliedValues: widget.tool == _OpticsTool.fieldOfView
                      ? '${_controllers[0].text} × ${_controllers[1].text} mm sensor'
                      : '${_controllers[2].text} mm circle of confusion',
                ),
              const SizedBox(height: 12),
            ],
            ..._advancedFields,
          ],
        ),
        FilledButton(onPressed: _calculate, child: const Text('Calculate')),
        const SizedBox(height: 16),
        if (_details case final details?)
          CalculationResultView(
            title: '$_title result',
            highlight: _highlight,
            highlightCaption: _caption,
            tiles: _tiles,
            details: details,
            inputs: [
              for (var index = 0; index < _fields.length; index++)
                (_fields[index].$1, _controllers[index].text.trim()),
            ],
            assumptions: _assumptions,
            warnings: _warningMessages,
            guidance: _guidance,
            onSave: _save,
            onReset: _reset,
          ),
      ],
    );
  }

  double _value(int index) =>
      double.tryParse(_controllers[index].text.trim()) ?? double.nan;
  void _calculate() {
    switch (widget.tool) {
      case _OpticsTool.fieldOfView:
        final result = const FieldOfViewCalculator().calculate(
          FieldOfViewInput(
            sensorWidthMm: _value(0),
            sensorHeightMm: _value(1),
            focalLengthMm: _value(2),
            distanceMm: _value(3),
          ),
        );
        _applyErrors(result.errors.map((e) => (e.field, e.code)));
        if (result.output case final value?) {
          _highlight = (
            'Scene width at this distance',
            _distance(value.sceneWidthMm),
          );
          _caption = 'Scene height ${_distance(value.sceneHeightMm)}.';
          _tiles = [
            (
              'Horizontal angle',
              '${value.horizontalDegrees.toStringAsFixed(1)}°',
            ),
            ('Vertical angle', '${value.verticalDegrees.toStringAsFixed(1)}°'),
            ('Diagonal angle', '${value.diagonalDegrees.toStringAsFixed(1)}°'),
          ];
          _details = [
            (
              'Horizontal angle',
              '${value.horizontalDegrees.toStringAsFixed(2)}°',
            ),
            ('Vertical angle', '${value.verticalDegrees.toStringAsFixed(2)}°'),
            ('Diagonal angle', '${value.diagonalDegrees.toStringAsFixed(2)}°'),
            ('Scene width', '${value.sceneWidthMm.toStringAsFixed(1)} mm'),
            ('Scene height', '${value.sceneHeightMm.toStringAsFixed(1)} mm'),
          ];
          _outputs = {
            'horizontalDegrees': value.horizontalDegrees,
            'verticalDegrees': value.verticalDegrees,
            'diagonalDegrees': value.diagonalDegrees,
            'sceneWidthMm': value.sceneWidthMm,
            'sceneHeightMm': value.sceneHeightMm,
          };
          _assumptions = const [
            'Rectilinear lens with nominal focal length',
            'Sensor dimensions define the active image area',
          ];
          _warnings = result.warnings;
          _guidance =
              'Focus breathing, distortion, and lens corrections can change real coverage.';
        }
      case _OpticsTool.diffraction:
        final result = const DiffractionCalculator().calculate(
          DiffractionInput(
            aperture: _value(0),
            wavelengthNm: _value(1),
            pixelPitchMicrometres: _value(2),
          ),
        );
        _applyErrors(result.errors.map((e) => (e.field, e.code)));
        if (result.output case final value?) {
          final visible = value.airyDiskPixels >= 2;
          _highlight = (
            'Airy disk on the sensor',
            '${value.airyDiskPixels.toStringAsFixed(2)} pixels',
          );
          _caption = visible
              ? 'Diffraction is visible at this pixel pitch.'
              : 'Smaller than two pixels: sampling is not the limit here.';
          _tiles = [
            ('Airy disk', '${value.airyDiskMicrometres.toStringAsFixed(2)} µm'),
            (
              'Airy radius',
              '${value.airyRadiusMicrometres.toStringAsFixed(2)} µm',
            ),
            ('Sampling', visible ? 'Visible' : 'Not limiting'),
          ];
          _details = [
            (
              'Airy disk diameter',
              '${value.airyDiskMicrometres.toStringAsFixed(3)} µm',
            ),
            (
              'Airy radius',
              '${value.airyRadiusMicrometres.toStringAsFixed(3)} µm',
            ),
            (
              'Diameter on sensor',
              '${value.airyDiskPixels.toStringAsFixed(3)} pixels',
            ),
          ];
          _outputs = {
            'airyDiskMicrometres': value.airyDiskMicrometres,
            'airyRadiusMicrometres': value.airyRadiusMicrometres,
            'airyDiskPixels': value.airyDiskPixels,
          };
          _assumptions = const [
            'Circular aperture and first Airy minimum',
            'Single selected wavelength; real light is broadband',
          ];
          _warnings = result.warnings;
          _guidance = visible
              ? 'Diffraction spans at least two pixels; compare sharpness against the depth of field you need.'
              : 'Sensor sampling is coarser than the calculated Airy disk at this wavelength.';
        }
      case _OpticsTool.focusStack:
        final result = const FocusStackCalculator().calculate(
          FocusStackInput(
            focalLengthMm: _value(0),
            aperture: _value(1),
            circleOfConfusionMm: _value(2),
            nearDistanceMm: _value(3),
            farDistanceMm: _value(4),
            overlapPercent: _value(5),
          ),
        );
        _applyErrors(result.errors.map((e) => (e.field, e.code)));
        if (result.output case final value?) {
          final distances = value.focusDistancesMm;
          _highlight = ('Frames to shoot', '${value.frameCount}');
          _caption = distances.isEmpty
              ? 'No focus positions were needed.'
              : 'From ${_distance(distances.first)} to '
                    '${_distance(distances.last)}.';
          _tiles = [
            (
              'First frame',
              distances.isEmpty ? '—' : _distance(distances.first),
            ),
            ('Last frame', distances.isEmpty ? '—' : _distance(distances.last)),
            ('Overlap', '${_value(5).toStringAsFixed(1)}%'),
          ];
          // The full near-to-far list is the biggest wall of numbers in the
          // app, so it lives inside the collapsed Details section.
          _details = [
            for (var index = 0; index < distances.length; index++)
              ('Frame ${index + 1}', _distance(distances[index])),
          ];
          _outputs = {
            'frameCount': value.frameCount,
            'focusDistancesMm': value.focusDistancesMm,
          };
          _assumptions = const [
            'Thin-lens depth-of-field model',
            'Distances are measured from the lens principal plane',
            'Focus breathing and rail motion are not modeled',
          ];
          _warnings = result.warnings;
          _guidance =
              'Capture in the listed near-to-far order. Add extra frames for uncertain distance scales or moving subjects.';
        }
    }
    setState(() {});
  }

  void _applyErrors(Iterable<(String, String)> errors) {
    _errors = {for (final error in errors) error.$1: _errorMessage(error.$2)};
    if (_errors.isNotEmpty) {
      _details = null;
      _outputs = const {};
      _warnings = const [];
    }
  }

  String _errorMessage(String code) => switch (code) {
    'greater_than_near' => 'Enter a distance greater than the near distance.',
    'not_beyond_focal_length' =>
      'Enter a distance greater than the focal length.',
    'range' => 'Enter overlap from 0 up to, but not including, 100%.',
    'result_out_of_range' =>
      'Reduce the extreme value: the result is outside the representable range.',
    _ => 'Enter a positive finite value.',
  };

  Future<void> _save() => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${widget.tool.name}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: widget.tool == _OpticsTool.fieldOfView
          ? FieldOfViewCalculator.id
          : widget.tool == _OpticsTool.diffraction
          ? DiffractionCalculator.id
          : FocusStackCalculator.id,
      formulaVersion: 1,
      createdAt: DateTime.now().toUtc(),
      title: '$_title result',
      canonicalInputs: {
        for (var index = 0; index < _fields.length; index++)
          _fields[index].$3: _value(index),
      },
      canonicalOutputs: _outputs,
      displayContext: {'distanceUnit': _lengthDisplay.name},
      assumptions: _snapshotAssumptions,
      warnings: _snapshotWarnings,
      equipment: [
        if (_camera case final camera?)
          _equipment(camera, SnapshotEquipmentType.camera, {
            if (widget.tool == _OpticsTool.fieldOfView) ...{
              'sensorWidthMm': _value(0),
              'sensorHeightMm': _value(1),
            },
            if (widget.tool == _OpticsTool.focusStack)
              'circleOfConfusionMm': _value(2),
          }),
        if (_lens case final lens?)
          _equipment(lens, SnapshotEquipmentType.lens, {
            if (widget.tool == _OpticsTool.fieldOfView)
              'focalLengthMm': _value(2),
            if (widget.tool == _OpticsTool.diffraction) 'aperture': _value(0),
            if (widget.tool == _OpticsTool.focusStack) ...{
              'focalLengthMm': _value(0),
              'aperture': _value(1),
            },
          }),
      ],
    ),
  );
  void _reset() {
    for (var index = 0; index < _fields.length; index++) {
      _controllers[index].text = _fields[index].$2;
    }
    setState(() {
      _errors = const {};
      _details = null;
      _outputs = const {};
      _camera = null;
      _lens = null;
    });
  }

  LengthDisplay get _lengthDisplay =>
      ref.read(preferencesProvider).valueOrNull?.lengthDisplay ??
      LengthDisplay.metric;

  String _distance(double mm) => formatDisplayLength(mm, _lengthDisplay);

  void _applyCamera(CameraBody? camera) => setState(() {
    _camera = camera;
    if (camera != null) {
      if (widget.tool == _OpticsTool.fieldOfView) {
        _controllers[0].text = camera.sensorWidthMm.toString();
        _controllers[1].text = camera.sensorHeightMm.toString();
      } else if (widget.tool == _OpticsTool.focusStack &&
          camera.defaultCircleOfConfusionMm != null) {
        _controllers[2].text = camera.defaultCircleOfConfusionMm.toString();
      }
    }
    _details = null;
  });

  void _applyLens(Lens? lens) => setState(() {
    _lens = lens;
    if (lens != null) {
      switch (widget.tool) {
        case _OpticsTool.fieldOfView:
          _controllers[2].text = lens.minimumFocalLengthMm.toString();
        case _OpticsTool.diffraction:
          if (lens.minimumAperture != null) {
            _controllers[0].text = lens.minimumAperture.toString();
          }
        case _OpticsTool.focusStack:
          _controllers[0].text = lens.maximumFocalLengthMm.toString();
          final aperture =
              lens.maximumFocalLengthMinimumAperture ?? lens.minimumAperture;
          if (aperture != null) _controllers[1].text = aperture.toString();
      }
    }
    _details = null;
  });

  String get _lensAppliedValues => switch (widget.tool) {
    _OpticsTool.fieldOfView => '${_controllers[2].text} mm focal length',
    _OpticsTool.diffraction => 'f/${_controllers[0].text} aperture',
    _OpticsTool.focusStack =>
      '${_controllers[0].text} mm at f/${_controllers[1].text}',
  };

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

  List<CalculationAssumption> get _snapshotAssumptions => switch (widget.tool) {
    _OpticsTool.fieldOfView => const [
      CalculationAssumption(key: 'projection', value: 'rectilinear'),
      CalculationAssumption(key: 'focus', value: 'nominalFocalLength'),
    ],
    _OpticsTool.diffraction => const [
      CalculationAssumption(key: 'criterion', value: 'firstAiryMinimum'),
      CalculationAssumption(key: 'aperture', value: 'circular'),
      CalculationAssumption(key: 'wavelength', value: 'monochromatic'),
    ],
    _OpticsTool.focusStack => const [
      CalculationAssumption(key: 'lensModel', value: 'thinLens'),
      CalculationAssumption(key: 'criterion', value: 'circleOfConfusion'),
      CalculationAssumption(key: 'movement', value: 'focusDistance'),
    ],
  };

  List<CalculationWarning> get _snapshotWarnings => [
    ..._warnings,
    if (widget.tool == _OpticsTool.diffraction &&
        _outputs['airyDiskPixels'] is double &&
        (_outputs['airyDiskPixels']! as double) >= 2)
      const CalculationWarning(
        code: 'sampling_visible',
        messageKey: 'diffraction.warning.samplingVisible',
      ),
  ];

  List<String> get _warningMessages => [
    for (final warning in _warnings) _warningMessage(warning.code),
    if (widget.tool == _OpticsTool.diffraction &&
        _outputs['airyDiskPixels'] is double &&
        (_outputs['airyDiskPixels']! as double) >= 2)
      // The exact sentence a reopened plan renders for this condition, so the
      // live and saved wording cannot drift apart.
      calculationWarningText('sampling_visible'),
  ];

  String _warningMessage(String code) => calculationWarningText(code);
}
