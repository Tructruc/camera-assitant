import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../domain/depth_of_field_calculator.dart';

class DepthOfFieldScreen extends ConsumerStatefulWidget {
  const DepthOfFieldScreen({super.key});

  @override
  ConsumerState<DepthOfFieldScreen> createState() => _DepthOfFieldScreenState();
}

class _DepthOfFieldScreenState extends ConsumerState<DepthOfFieldScreen> {
  final _focal = TextEditingController(text: '50');
  final _aperture = TextEditingController(text: '8');
  final _distance = TextEditingController(text: '10000');
  final _coc = TextEditingController(text: '0.03');
  CalculationResult<DepthOfFieldOutput>? _result;
  Map<String, String> _errors = const {};
  Lens? _selectedLens;
  CameraBody? _selectedCamera;

  @override
  void dispose() {
    _focal.dispose();
    _aperture.dispose();
    _distance.dispose();
    _coc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preferences =
        ref.watch(preferencesProvider).valueOrNull ?? const AppPreferences();
    final equipment = ref.watch(equipmentControllerProvider).items;
    final lenses = equipment
        .where((entry) => entry.kind == EquipmentKind.lens)
        .map((entry) => entry.item)
        .whereType<Lens>()
        .toList(growable: false);
    final cameras = equipment
        .where((entry) => entry.kind == EquipmentKind.camera)
        .map((entry) => entry.item)
        .whereType<CameraBody>()
        .toList(growable: false);
    return CalculatorPage(
      children: <Widget>[
        Text(
          'Depth of field',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Calculate hyperfocal distance and the acceptable focus range.',
        ),
        const SizedBox(height: 16),
        EquipmentPicker<Lens>(
          label: 'Saved lens (optional)',
          items: lenses,
          itemLabel: (lens) => lens.name,
          value: _selectedLens,
          onSelected: _applyLens,
        ),
        const SizedBox(height: 12),
        EquipmentPicker<CameraBody>(
          label: 'Saved camera (optional)',
          items: cameras,
          itemLabel: (camera) => camera.name,
          value: _selectedCamera,
          onSelected: _applyCamera,
        ),
        if (_selectedLens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            appliedValues: '${_focal.text} mm at f/${_aperture.text}',
          ),
        if (_selectedCamera case final camera?)
          AppliedEquipmentNotice(
            equipmentName: camera.name,
            appliedValues: 'circle of confusion ${_coc.text} mm',
          ),
        CalculatorNumberField(
          label: 'Focal length (mm)',
          controller: _focal,
          fieldKey: const Key('dof-focal'),
          errorText: _errors['focalLengthMm'],
        ),
        CalculatorNumberField(
          label: 'Aperture (f-number)',
          controller: _aperture,
          errorText: _errors['aperture'],
        ),
        CalculatorNumberField(
          label: 'Focus distance (mm)',
          controller: _distance,
          errorText: _errors['focusDistanceMm'],
        ),
        CalculatorNumberField(
          label: 'Circle of confusion (mm)',
          controller: _coc,
          errorText: _errors['circleOfConfusionMm'],
        ),
        FilledButton(onPressed: _calculate, child: const Text('Calculate')),
        const SizedBox(height: 16),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Depth of field result',
            rows: <(String, String)>[
              (
                'Hyperfocal distance',
                _distanceText(
                  output.hyperfocalDistance.millimetres,
                  preferences.lengthDisplay,
                ),
              ),
              (
                'Near limit',
                _distanceText(
                  output.nearLimit.millimetres,
                  preferences.lengthDisplay,
                ),
              ),
              (
                'Far limit',
                output.farLimit.isInfinite
                    ? 'Infinity'
                    : _distanceText(
                        output.farLimit.millimetres,
                        preferences.lengthDisplay,
                      ),
              ),
              (
                'Total depth',
                output.totalDepth.isInfinite
                    ? 'Infinity'
                    : _distanceText(
                        output.totalDepth.millimetres,
                        preferences.lengthDisplay,
                      ),
              ),
            ],
            assumptions: const <String>[
              'Thin-lens geometric model',
              'Focus distance measured from the lens principal plane',
              'Circle of confusion controls acceptable sharpness',
            ],
            guidance: _result!.warnings.isEmpty
                ? 'Near and far limits are estimates, not guaranteed sharpness.'
                : 'Close focus reduces thin-lens model accuracy.',
            onSave: () => _save(output, preferences),
            onReset: _reset,
          ),
      ],
    );
  }

  void _applyLens(Lens? lens) {
    setState(() {
      _selectedLens = lens;
      if (lens != null) {
        _focal.text = lens.maximumFocalLengthMm.toString();
        _aperture.text =
            (lens.maximumFocalLengthMinimumAperture ??
                    lens.minimumAperture ??
                    8)
                .toString();
      }
    });
  }

  void _applyCamera(CameraBody? camera) {
    setState(() {
      _selectedCamera = camera;
      if (camera?.defaultCircleOfConfusionMm case final value?) {
        _coc.text = value.toString();
      }
    });
  }

  void _calculate() {
    final result = const DepthOfFieldCalculator().calculate(
      DepthOfFieldInput(
        focalLengthMm: _number(_focal.text),
        aperture: _number(_aperture.text),
        focusDistanceMm: _number(_distance.text),
        circleOfConfusionMm: _number(_coc.text),
      ),
    );
    setState(() {
      _result = result;
      _errors = {
        for (final error in result.errors) error.field: _message(error.code),
      };
    });
  }

  Future<void> _save(
    DepthOfFieldOutput output,
    AppPreferences preferences,
  ) async {
    final result = _result!;
    await saveCalculationSnapshot(
      context,
      ref,
      CalculationSnapshot(
        id: '${DepthOfFieldCalculator.id}_${DateTime.now().microsecondsSinceEpoch}',
        calculatorId: DepthOfFieldCalculator.id,
        formulaVersion: DepthOfFieldCalculator.version,
        createdAt: DateTime.now().toUtc(),
        title: 'Depth of field result',
        canonicalInputs: <String, Object?>{
          'focalLengthMm': _number(_focal.text),
          'aperture': _number(_aperture.text),
          'focusDistanceMm': _number(_distance.text),
          'circleOfConfusionMm': _number(_coc.text),
        },
        canonicalOutputs: <String, Object?>{
          'hyperfocalDistanceMm': output.hyperfocalDistance.millimetres,
          'nearLimitMm': output.nearLimit.millimetres,
          'farLimitMm': output.farLimit.isInfinite
              ? 'infinity'
              : output.farLimit.millimetres,
          'totalDepthMm': output.totalDepth.isInfinite
              ? 'infinity'
              : output.totalDepth.millimetres,
        },
        displayContext: <String, Object?>{
          'distanceUnit': preferences.lengthDisplay.name,
          'infinityLabel': 'Infinity',
        },
        assumptions: result.assumptions,
        warnings: result.warnings,
        equipment: <AppliedEquipmentSnapshot>[
          if (_selectedLens case final lens?)
            AppliedEquipmentSnapshot(
              id: lens.id,
              type: SnapshotEquipmentType.lens,
              name: lens.name,
              source: lens.provenance.source.name,
              note: lens.provenance.note,
              values: <String, Object?>{
                'focalLengthMm': _number(_focal.text),
                'aperture': _number(_aperture.text),
              },
            ),
          if (_selectedCamera case final camera?)
            AppliedEquipmentSnapshot(
              id: camera.id,
              type: SnapshotEquipmentType.camera,
              name: camera.name,
              source: camera.provenance.source.name,
              note: camera.provenance.note,
              values: <String, Object?>{
                'circleOfConfusionMm': _number(_coc.text),
              },
            ),
        ],
      ),
    );
  }

  void _reset() {
    _focal.text = '50';
    _aperture.text = '8';
    _distance.text = '10000';
    _coc.text = '0.03';
    setState(() {
      _result = null;
      _errors = const {};
      _selectedLens = null;
      _selectedCamera = null;
    });
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
String _message(String code) => code == 'not_beyond_focal_length'
    ? 'Focus distance must be greater than focal length.'
    : 'Enter a positive finite value.';
String _distanceText(double millimetres, LengthDisplay display) {
  if (display == LengthDisplay.imperial) {
    final inches = millimetres / 25.4;
    return inches >= 12
        ? '${(inches / 12).toStringAsFixed(2)} ft'
        : '${inches.toStringAsFixed(2)} in';
  }
  return millimetres >= 1000
      ? '${(millimetres / 1000).toStringAsFixed(2)} m'
      : '${millimetres.toStringAsFixed(1)} mm';
}
