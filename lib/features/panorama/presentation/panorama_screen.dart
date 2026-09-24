import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../domain/panorama_calculator.dart';

class PanoramaScreen extends ConsumerStatefulWidget {
  const PanoramaScreen({super.key});

  @override
  ConsumerState<PanoramaScreen> createState() => _PanoramaScreenState();
}

class _PanoramaScreenState extends ConsumerState<PanoramaScreen> {
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
      inputControllers: [
        _sensorWidth,
        _sensorHeight,
        _focalLength,
        _horizontalBounds,
        _verticalBounds,
        _horizontalOverlap,
        _verticalOverlap,
      ],
      onInputsChanged: () {
        if (_result != null || _errors.isNotEmpty) {
          setState(() {
            _result = null;
            _errors = const {};
          });
        }
      },
      children: <Widget>[
        const CalculatorHeader(
          icon: Icons.panorama_horizontal_outlined,
          description:
              'Build a gap-free horizontal, vertical, or multi-row capture grid with a serpentine shooting order.',
        ),
        const SizedBox(height: 16),
        EquipmentPicker<Lens>(
          label: 'Saved lens (optional)',
          items: lenses,
          itemLabel: (item) => item.name,
          value: _selectedLens,
          onSelected: _applyLens,
        ),
        if (_selectedLens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            sourceLabel: lens.provenance.source.label,
            appliedValues: '${_focalLength.text} mm focal length',
          ),
        CalculatorNumberField(
          label: 'Focal length (mm)',
          controller: _focalLength,
          errorText: _errors['focalLengthMm'],
        ),
        DropdownButtonFormField<CameraOrientation>(
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Camera orientation'),
          initialValue: _orientation,
          items: const [
            DropdownMenuItem(
              value: CameraOrientation.landscape,
              child: Text('Landscape'),
            ),
            DropdownMenuItem(
              value: CameraOrientation.portrait,
              child: Text('Portrait'),
            ),
          ],
          onChanged: (value) => setState(() {
            _orientation = value ?? _orientation;
            _result = null;
          }),
        ),
        const SizedBox(height: 12),
        CalculatorFieldPair(
          first: CalculatorNumberField(
            label: 'Horizontal scene bounds (degrees)',
            controller: _horizontalBounds,
            errorText: _errors['horizontalBoundsDegrees'],
          ),
          second: CalculatorNumberField(
            label: 'Vertical scene bounds (degrees)',
            controller: _verticalBounds,
            errorText: _errors['verticalBoundsDegrees'],
          ),
        ),
        CalculatorAdvancedSection(
          // Stable identity: applying equipment above must not collapse
          // the section the user is working in.
          key: const ValueKey('advanced'),
          children: <Widget>[
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
                appliedValues:
                    '${_sensorWidth.text} × ${_sensorHeight.text} mm sensor',
              ),
            const SizedBox(height: 12),
            CalculatorFieldPair(
              first: CalculatorNumberField(
                label: 'Sensor width (mm)',
                controller: _sensorWidth,
                errorText: _errors['sensorWidthMm'],
              ),
              second: CalculatorNumberField(
                label: 'Sensor height (mm)',
                controller: _sensorHeight,
                errorText: _errors['sensorHeightMm'],
              ),
            ),
            CalculatorFieldPair(
              first: CalculatorNumberField(
                label: 'Horizontal overlap (%)',
                controller: _horizontalOverlap,
                errorText: _errors['horizontalOverlapPercent'],
              ),
              second: CalculatorNumberField(
                label: 'Vertical overlap (%)',
                controller: _verticalOverlap,
                errorText: _errors['verticalOverlapPercent'],
              ),
            ),
          ],
        ),
        FilledButton(onPressed: _calculate, child: const Text('Plan panorama')),
        const SizedBox(height: 16),
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
      ],
    );
  }

  double _value(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;

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
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors) error.field: _message(error.code),
      };
    });
  }

  String _message(String code) => code == 'positive'
      ? 'Enter a positive finite value.'
      : code == 'overlap'
      ? 'Enter overlap from 0 up to (but not including) 100%.'
      : code == 'plan_too_large'
      ? 'Too many frames: reduce the coverage or use a wider lens.'
      : 'Enter an angle within the supported range.';

  void _applyCamera(CameraBody? camera) => setState(() {
    _selectedCamera = camera;
    if (camera != null) {
      _sensorWidth.text = camera.sensorWidthMm.toString();
      _sensorHeight.text = camera.sensorHeightMm.toString();
    }
    _result = null;
  });

  void _applyLens(Lens? lens) => setState(() {
    _selectedLens = lens;
    if (lens != null) _focalLength.text = lens.minimumFocalLengthMm.toString();
    _result = null;
  });

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
      _result = null;
      _errors = const {};
    });
  }

  String _degrees(double value) => '${value.toStringAsFixed(1)}°';
  String _signed(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}°';
}
