import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/design_tokens.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../equipment/presentation/equipment_specs.dart';
import '../../exposure_comparison/presentation/capture_field_controls.dart';
import '../domain/panorama_calculator.dart';

/// Panorama planner: orientation, focal length, how much of the scene to cover
/// and how far the frames overlap - the shooting decisions - with the frame
/// grid and coverage answered as they change.
///
/// A saved camera fills the sensor size from the primary controls; the raw
/// sensor dimensions stay behind the advanced disclosure for manual entry.
class PanoramaScreen extends ConsumerStatefulWidget {
  const PanoramaScreen({super.key});

  @override
  ConsumerState<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends ConsumerState<PanoramaScreen> {
  /// Focal lengths a panorama is usually stitched from.
  static const _focalPresets = <double>[14, 16, 20, 24, 28, 35, 50, 85];

  /// Scene sweeps a panorama is usually planned around, in degrees.
  static const _horizontalPresets = <double>[45, 90, 180, 270, 360];
  static const _verticalPresets = <double>[30, 45, 90, 180];

  /// Stitch overlaps: the range a hand-held or geared head actually delivers.
  static const _overlapPresets = <double>[0, 25, 30, 50, 70];

  final _sensorWidth = TextEditingController(text: '36');
  final _sensorHeight = TextEditingController(text: '24');
  final _focalLength = TextEditingController(text: '50');
  final _horizontalBounds = TextEditingController(text: '90');
  final _verticalBounds = TextEditingController(text: '45');
  final _horizontalOverlap = TextEditingController(text: '30');
  final _verticalOverlap = TextEditingController(text: '30');
  var _orientation = CameraOrientation.landscape;
  CameraBody? _selectedCamera;
  Lens? _selectedLens;
  CalculationResult<PanoramaOutput>? _result;
  Map<String, String> _errors = const {};

  @override
  void initState() {
    super.initState();
    // Seed the answer for the default sweep so the screen opens on a grid.
    _calculate();
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _sensorWidth,
      _sensorHeight,
      _focalLength,
      _horizontalBounds,
      _verticalBounds,
      _horizontalOverlap,
      _verticalOverlap,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // activeItems, not items: the inventory's Kit kind filter must not hide the
    // saved cameras and lenses from this calculator.
    final equipment = ref.watch(equipmentControllerProvider).activeItems;
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
      inputControllers: [
        _sensorWidth,
        _sensorHeight,
        _focalLength,
        _horizontalBounds,
        _verticalBounds,
        _horizontalOverlap,
        _verticalOverlap,
      ],
      // Orientation and the applied kit change the answer without touching any
      // controller text, so they carry the recalculation signature.
      calculationKey: <String>[
        _orientation.name,
        _selectedCamera?.id ?? '',
        _selectedLens?.id ?? '',
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
          icon: Icons.panorama_horizontal_outlined,
          description:
              'Build a gap-free horizontal, vertical, or multi-row capture grid with a serpentine shooting order.',
        ),
        const SizedBox(height: AppGap.lg),
        // The pickers hide themselves when the kit is empty: an optional
        // control with nothing to pick must not take a row.
        EquipmentPicker<Lens>(
          label: 'Saved lens (optional)',
          items: lenses,
          itemLabel: (item) => item.name,
          itemDetail: lensSpecSummary,
          value: _selectedLens,
          onSelected: _applyLens,
        ),
        if (_selectedLens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            sourceLabel: lens.provenance.source.label,
            appliedValues: '${_focalLength.text} mm focal length',
          ),
        // A saved camera supplies the sensor size the grid is built from, so it
        // sits with the shot parameters rather than behind the advanced
        // disclosure. Its picker hides itself when the kit holds no camera.
        if (cameras.isNotEmpty)
          EquipmentPicker<CameraBody>(
            label: 'Saved camera (optional)',
            items: cameras,
            itemLabel: (item) => item.name,
            itemDetail: cameraSpecSummary,
            value: _selectedCamera,
            onSelected: _applyCamera,
          ),
        if (_selectedCamera case final camera?)
          AppliedEquipmentNotice(
            equipmentName: camera.name,
            sourceLabel: camera.provenance.source.label,
            appliedValues:
                '${_sensorWidth.text} × ${_sensorHeight.text} mm sensor',
          ),
        CalculatorNumberField(
          label: 'Focal length (mm)',
          controller: _focalLength,
          errorText: _errors['focalLengthMm'],
          presets: _focalPresets,
          // Wider than any rectilinear lens, wider than any panorama uses:
          // exact entry outside the slider range is still accepted.
          min: 4,
          max: 1200,
          logarithmic: true,
          helperText: 'Longer lenses need more frames for the same sweep',
        ),
        CaptureChipRow(
          caption: 'Camera orientation',
          chips: <Widget>[
            for (final orientation in CameraOrientation.values)
              CaptureChoiceChip<CameraOrientation>(
                label: _orientationLabel(orientation),
                value: orientation,
                selected: _orientation == orientation,
                tooltip:
                    'Set the camera to '
                    '${_orientationLabel(orientation).toLowerCase()} '
                    'orientation',
                onSelected: _setOrientation,
              ),
          ],
        ),
        CalculatorFieldPair(
          first: CalculatorNumberField(
            label: 'Horizontal scene bounds (degrees)',
            controller: _horizontalBounds,
            errorText: _errors['horizontalBoundsDegrees'],
            presets: _horizontalPresets,
            // A full turn is the widest meaningful sweep; beyond it the plan
            // would wrap onto itself.
            min: 1,
            max: 360,
            step: 5,
            helperText: 'How far the panorama sweeps left to right',
          ),
          second: CalculatorNumberField(
            label: 'Vertical scene bounds (degrees)',
            controller: _verticalBounds,
            errorText: _errors['verticalBoundsDegrees'],
            presets: _verticalPresets,
            min: 1,
            max: 180,
            step: 5,
            helperText: 'How far it sweeps top to bottom',
          ),
        ),
        CalculatorFieldPair(
          first: CalculatorNumberField(
            label: 'Horizontal overlap (%)',
            controller: _horizontalOverlap,
            errorText: _errors['horizontalOverlapPercent'],
            presets: _overlapPresets,
            // The stitcher needs something to match on, so 100% is refused by
            // the calculator and the slider stops short of it.
            min: 0,
            max: 90,
            step: 5,
            helperText: 'What neighbouring columns share',
          ),
          second: CalculatorNumberField(
            label: 'Vertical overlap (%)',
            controller: _verticalOverlap,
            errorText: _errors['verticalOverlapPercent'],
            presets: _overlapPresets,
            min: 0,
            max: 90,
            step: 5,
            helperText: 'What neighbouring rows share',
          ),
        ),
        const CaptureLiveHint(),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Panorama capture plan',
            highlight: ('Frames to shoot', '${output.frameCount}'),
            highlightCaption:
                '${output.columns} columns × ${output.rows} rows covering '
                '${_degrees(output.horizontalCoverageDegrees)} × ${_degrees(output.verticalCoverageDegrees)}.',
            tiles: <(String, String)>[
              ('Columns', '${output.columns}'),
              ('Rows', '${output.rows}'),
              (
                'Coverage',
                '${_degrees(output.horizontalCoverageDegrees)} × ${_degrees(output.verticalCoverageDegrees)}',
              ),
              (
                'Frame field of view',
                '${_degrees(output.frameHorizontalDegrees)} × ${_degrees(output.frameVerticalDegrees)}',
              ),
              ('Column step', _degrees(output.horizontalIncrementDegrees)),
              ('Row step', _degrees(output.verticalIncrementDegrees)),
            ],
            details: <(String, String)>[
              (
                'Frame field of view',
                '${_degrees(output.frameHorizontalDegrees)} × ${_degrees(output.frameVerticalDegrees)}',
              ),
              ('Yaw increment', _degrees(output.horizontalIncrementDegrees)),
              ('Pitch increment', _degrees(output.verticalIncrementDegrees)),
              (
                'Requested overlap',
                '${_value(_horizontalOverlap).toStringAsFixed(0)}% horizontal, ${_value(_verticalOverlap).toStringAsFixed(0)}% vertical',
              ),
              // The full capture grid is the longest list in the app, so it is
              // collapsed with the other exact values instead of printed under
              // the result.
              for (final frame in output.frames)
                (
                  'Frame ${frame.captureIndex}',
                  'Row ${frame.row + 1}, column ${frame.column + 1}: '
                      'yaw ${_signed(frame.yawDegrees)}, '
                      'pitch ${_signed(frame.pitchDegrees)}',
                ),
            ],
            inputs: [
              (
                'Sensor',
                '${_sensorWidth.text.trim()} × ${_sensorHeight.text.trim()} mm',
              ),
              ('Focal length', '${_focalLength.text.trim()} mm'),
              ('Camera orientation', _orientation.name),
              (
                'Scene bounds',
                '${_horizontalBounds.text.trim()}° × ${_verticalBounds.text.trim()}°',
              ),
              (
                'Overlap',
                '${_horizontalOverlap.text.trim()}% horizontal, ${_verticalOverlap.text.trim()}% vertical',
              ),
            ],
            assumptions: const [
              'Rectilinear lens field of view',
              'Rotate around the lens entrance pupil to limit parallax',
              'Capture rows top-to-bottom in alternating directions',
            ],
            guidance:
                'Coverage includes a minimum geometric margin. Allow extra room for lens distortion, leveling errors, and the final crop.',
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
          subtitle: 'Active image area used for the frame grid',
          children: <Widget>[
            CalculatorFieldPair(
              first: CalculatorNumberField(
                label: 'Sensor width (mm)',
                controller: _sensorWidth,
                errorText: _errors['sensorWidthMm'],
                step: 0.1,
                min: 1,
                max: 100,
              ),
              second: CalculatorNumberField(
                label: 'Sensor height (mm)',
                controller: _sensorHeight,
                errorText: _errors['sensorHeightMm'],
                step: 0.1,
                min: 1,
                max: 100,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _orientationLabel(CameraOrientation orientation) =>
      switch (orientation) {
        CameraOrientation.landscape => 'Landscape',
        CameraOrientation.portrait => 'Portrait',
      };

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;

  void _setOrientation(CameraOrientation orientation) {
    if (_orientation == orientation) return;
    setState(() {
      _orientation = orientation;
    });
    // Orientation changes the frame the grid is built from, and no controller
    // text moves, so the answer is recomputed here.
    _calculate();
  }

  void _calculate() {
    final result = const PanoramaCalculator().calculate(
      PanoramaInput(
        sensorWidthMm: _value(_sensorWidth),
        sensorHeightMm: _value(_sensorHeight),
        focalLengthMm: _value(_focalLength),
        orientation: _orientation,
        horizontalBoundsDegrees: _value(_horizontalBounds),
        verticalBoundsDegrees: _value(_verticalBounds),
        horizontalOverlapPercent: _value(_horizontalOverlap),
        verticalOverlapPercent: _value(_verticalOverlap),
      ),
    );
    final errors = <String, String>{
      for (final error in result.errors) error.field: _message(error.code),
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

  String _message(String code) => code == 'positive'
      ? 'Enter a positive finite value.'
      : code == 'overlap'
      ? 'Enter overlap from 0 up to (but not including) 100%.'
      : code == 'plan_too_large'
      ? 'Too many frames: reduce the coverage or use a wider lens.'
      : 'Enter an angle within the supported range.';

  void _applyCamera(CameraBody? camera) {
    setState(() {
      _selectedCamera = camera;
      if (camera != null) {
        _sensorWidth.text = camera.sensorWidthMm.toString();
        _sensorHeight.text = camera.sensorHeightMm.toString();
      }
    });
    // Applying a saved camera is an input change: the answer must be the one
    // for the sensor that is now in the fields.
    _calculate();
  }

  void _applyLens(Lens? lens) {
    setState(() {
      _selectedLens = lens;
      if (lens != null) {
        _focalLength.text = lens.minimumFocalLengthMm.toString();
      }
    });
    _calculate();
  }

  Future<void> _save(PanoramaOutput output) => saveCalculationSnapshot(
    context,
    ref,
    CalculationSnapshot(
      id: '${PanoramaCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
      calculatorId: PanoramaCalculator.id,
      formulaVersion: PanoramaCalculator.version,
      createdAt: DateTime.now().toUtc(),
      title: '${output.columns} × ${output.rows} panorama',
      canonicalInputs: _canonicalInputs,
      canonicalOutputs: {
        'columns': output.columns,
        'rows': output.rows,
        'frameCount': output.frameCount,
        'frameHorizontalDegrees': output.frameHorizontalDegrees,
        'frameVerticalDegrees': output.frameVerticalDegrees,
        'horizontalIncrementDegrees': output.horizontalIncrementDegrees,
        'verticalIncrementDegrees': output.verticalIncrementDegrees,
        'horizontalCoverageDegrees': output.horizontalCoverageDegrees,
        'verticalCoverageDegrees': output.verticalCoverageDegrees,
        'frames': [
          for (final frame in output.frames)
            {
              'captureIndex': frame.captureIndex,
              'row': frame.row,
              'column': frame.column,
              'yawDegrees': frame.yawDegrees,
              'pitchDegrees': frame.pitchDegrees,
            },
        ],
      },
      displayContext: const {
        'angleUnit': 'degrees',
        'positionOrigin': 'gridCentre',
      },
      assumptions: _result!.assumptions,
      warnings: _result!.warnings,
      equipment: [
        if (_selectedCamera case final camera?)
          _equipment(camera, SnapshotEquipmentType.camera, {
            'sensorWidthMm': _value(_sensorWidth),
            'sensorHeightMm': _value(_sensorHeight),
          }),
        if (_selectedLens case final lens?)
          _equipment(lens, SnapshotEquipmentType.lens, {
            'focalLengthMm': _value(_focalLength),
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

  Map<String, Object?> get _canonicalInputs => {
    'sensorWidthMm': _value(_sensorWidth),
    'sensorHeightMm': _value(_sensorHeight),
    'focalLengthMm': _value(_focalLength),
    'orientation': _orientation.name,
    'horizontalBoundsDegrees': _value(_horizontalBounds),
    'verticalBoundsDegrees': _value(_verticalBounds),
    'horizontalOverlapPercent': _value(_horizontalOverlap),
    'verticalOverlapPercent': _value(_verticalOverlap),
  };

  void _reset() {
    _sensorWidth.text = '36';
    _sensorHeight.text = '24';
    _focalLength.text = '50';
    _horizontalBounds.text = '90';
    _verticalBounds.text = '45';
    _horizontalOverlap.text = '30';
    _verticalOverlap.text = '30';
    setState(() {
      _orientation = CameraOrientation.landscape;
      _selectedCamera = null;
      _selectedLens = null;
    });
    // Reset is an input change too: without this the shown grid would still
    // describe the values the user just discarded.
    _calculate();
  }

  String _degrees(double value) => '${value.toStringAsFixed(1)}°';
  String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}°';
}
