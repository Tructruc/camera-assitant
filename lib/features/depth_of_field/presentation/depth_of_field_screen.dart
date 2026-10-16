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
import '../domain/depth_of_field_calculator.dart';

/// Depth of field, laid out the way it is set on a camera: focal length,
/// aperture and focus distance first, with the answer following immediately.
///
/// The sensor convention (circle of confusion) and the saved camera that
/// supplies it stay in the advanced group, where their default is stated
/// rather than assumed.
class DepthOfFieldScreen extends ConsumerStatefulWidget {
  const DepthOfFieldScreen({super.key});

  @override
  ConsumerState<DepthOfFieldScreen> createState() => _DepthOfFieldScreenState();
}

class _DepthOfFieldScreenState extends ConsumerState<DepthOfFieldScreen> {
  /// Standard focal lengths a photographer reaches for before dialling an
  /// exact value; raw millimetres, like every other value here.
  static const _focalPresets = <double>[14, 24, 35, 50, 85, 135, 200];

  /// Full-stop apertures, including the wide and long ends of the standard
  /// series. The decrement/increment buttons walk exactly this list.
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

  /// Focus distances in millimetres, displayed as metres.
  static const _distancePresets = <double>[
    250,
    500,
    1000,
    2000,
    5000,
    10000,
    30000,
  ];

  static const _defaultFocal = '50';
  static const _defaultAperture = '8';
  static const _defaultDistance = '10000';
  static const _defaultCircleOfConfusion = '0.03';

  final _focal = TextEditingController(text: _defaultFocal);
  final _aperture = TextEditingController(text: _defaultAperture);
  final _distance = TextEditingController(text: _defaultDistance);
  final _coc = TextEditingController(text: _defaultCircleOfConfusion);
  CalculationResult<DepthOfFieldOutput>? _result;
  Map<String, String> _errors = const {};
  Lens? _selectedLens;
  CameraBody? _selectedCamera;

  @override
  void initState() {
    super.initState();
    // Seed an answer so the screen opens on the common case instead of a
    // blank slot; the post-frame calculation keeps it current afterwards.
    _calculate();
  }

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
    // activeItems, not items: the inventory's own Kit kind filter must not take
    // the saved lenses and cameras away from this calculator.
    final equipment = ref.watch(equipmentControllerProvider).activeItems;
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
      inputControllers: [_focal, _aperture, _distance, _coc],
      // Value-equal signature: only a genuine input or unit change re-runs the
      // calculation, and a rebuild alone can never clear the shown result.
      calculationKey: [
        preferences.lengthDisplay.name,
        _selectedLens?.id ?? '',
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
      children: <Widget>[
        const CalculatorHeader(
          icon: Icons.center_focus_strong,
          description:
              'Calculate hyperfocal distance and the acceptable focus range.',
        ),
        const SizedBox(height: 16),
        // A kit with no saved lenses shows no picker at all: manual entry is
        // the primary path and the picker only fills values in.
        if (lenses.isNotEmpty)
          EquipmentPicker<Lens>(
            label: 'Saved lens (optional)',
            items: lenses,
            itemLabel: (lens) => lens.name,
            value: _selectedLens,
            onSelected: _applyLens,
          ),
        if (_selectedLens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            sourceLabel: lens.provenance.source.label,
            appliedValues: '${_focal.text} mm at f/${_aperture.text}',
          ),
        // A saved camera drives the circle of confusion, so it sits with the
        // shot parameters rather than behind the advanced disclosure. Its
        // picker still hides itself when the kit holds no camera.
        if (cameras.isNotEmpty)
          EquipmentPicker<CameraBody>(
            label: 'Saved camera (optional)',
            items: cameras,
            itemLabel: (camera) => camera.name,
            value: _selectedCamera,
            onSelected: _applyCamera,
          ),
        if (_selectedCamera case final camera?)
          AppliedEquipmentNotice(
            equipmentName: camera.name,
            sourceLabel: camera.provenance.source.label,
            appliedValues: 'circle of confusion ${_coc.text} mm',
          ),
        const SizedBox(height: 12),
        CalculatorNumberField(
          label: 'Focal length (mm)',
          controller: _focal,
          fieldKey: const Key('dof-focal'),
          errorText: _errors['focalLengthMm'],
          presets: _focalPresets,
        ),
        CalculatorNumberField(
          label: 'Aperture (f-number)',
          controller: _aperture,
          errorText: _errors['aperture'],
          // Presets are the only stepping: the buttons move between the
          // standard f-stops instead of counting f/8, f/9, f/10. Exact typed
          // entry stays available for apertures off the standard series.
          presets: _aperturePresets,
        ),
        CalculatorNumberField(
          label: 'Focus distance (m)',
          controller: _distance,
          errorText: _errors['focusDistanceMm'],
          presets: _distancePresets,
          min: 100,
          max: 100000,
          step: 100,
          displayDivisor: 1000,
          displayUnit: 'm',
        ),
        const CalculatorLiveHint(),
        if (_result?.output case final output?)
          CalculationResultView(
            title: 'Depth of field result',
            highlight: (
              'Hyperfocal distance',
              _distanceText(
                output.hyperfocalDistance.millimetres,
                preferences.lengthDisplay,
              ),
            ),
            highlightCaption:
                'Sharp from '
                '${_distanceText(output.nearLimit.millimetres, preferences.lengthDisplay)}'
                ' to '
                '${output.farLimit.isInfinite ? 'infinity' : _distanceText(output.farLimit.millimetres, preferences.lengthDisplay)}.',
            tiles: <(String, String)>[
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
            details: <(String, String)>[
              (
                'Depth in front of focus',
                _distanceText(
                  output.frontDepth.millimetres,
                  preferences.lengthDisplay,
                ),
              ),
              (
                'Depth behind focus',
                output.rearDepth.isInfinite
                    ? 'Infinity'
                    : _distanceText(
                        output.rearDepth.millimetres,
                        preferences.lengthDisplay,
                      ),
              ),
            ],
            inputs: [
              ('Focal length', '${_focal.text.trim()} mm'),
              ('Aperture', 'f/${_aperture.text.trim()}'),
              ('Focus distance', _focusDistanceSummary(preferences)),
              ('Circle of confusion', '${_coc.text.trim()} mm'),
            ],
            assumptions: const <String>[
              'Thin-lens geometric model',
              'Focus distance measured from the lens principal plane',
              'Circle of confusion controls acceptable sharpness',
            ],
            // The close-focus limitation arrives as a warning bullet, so the
            // guidance line stays general instead of repeating it.
            guidance:
                'Near and far limits are estimates, not guaranteed sharpness.',
            warnings: <String>[
              for (final warning in _result!.warnings)
                calculationWarningText(warning.code),
            ],
            onSave: () => _save(output, preferences),
            onReset: _reset,
          )
        else
          // The answer keeps its slot even while there is none: a card that
          // appears and disappears renumbers every sibling after it, and the
          // advanced group below holds the field the user is editing. The
          // placeholder is zero-height, so invalid input still ends the page
          // with the group and nothing else.
          const SizedBox.shrink(),
        CalculatorAdvancedSection(
          // Stable identity: applying equipment above must not collapse
          // the section the user is working in.
          key: const ValueKey('advanced'),
          children: <Widget>[
            CalculatorNumberField(
              label: 'Circle of confusion (mm)',
              controller: _coc,
              errorText: _errors['circleOfConfusionMm'],
              helperText:
                  '0.03 mm is the 35 mm sharpness convention; '
                  'a smaller sensor wants a smaller value.',
            ),
            const SizedBox(height: AppGap.sm),
            // The metre field above is the practical view; this writes the
            // same controller in raw millimetres so no precision is hidden.
            // The message is carried by both views of the one value: the
            // inline error belongs on the field being edited, and the other
            // view of it is usually scrolled out of the built range.
            FocusDistanceAdapterField(
              controller: _distance,
              fieldKey: const Key('dof-focus-distance-mm'),
              errorText: _errors['focusDistanceMm'],
            ),
          ],
        ),
      ],
    );
  }

  /// Echo of the focus input in the metre field's own unit.
  String _focusDistanceSummary(AppPreferences preferences) {
    final millimetres = double.tryParse(_distance.text.trim());
    if (millimetres == null || !millimetres.isFinite || millimetres <= 0) {
      return '${_distance.text.trim()} mm';
    }
    return formatDisplayLength(millimetres, preferences.lengthDisplay);
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
    // The equipment is part of the result's provenance, so the answer is
    // recomputed now rather than waiting for a numeric edit.
    _calculate();
  }

  void _applyCamera(CameraBody? camera) {
    setState(() {
      _selectedCamera = camera;
      if (camera?.defaultCircleOfConfusionMm case final value?) {
        _coc.text = value.toString();
      }
    });
    _calculate();
  }

  /// Recompute the shown answer from the current inputs.
  ///
  /// Called from `initState` (where `setState` is illegal) as well as from the
  /// page's live calculation hook, so the state write is inlined while the
  /// element is not mounted yet and goes through `setState` once it is.
  void _calculate() {
    final result = const DepthOfFieldCalculator().calculate(
      DepthOfFieldInput(
        focalLengthMm: _number(_focal.text),
        aperture: _number(_aperture.text),
        focusDistanceMm: _number(_distance.text),
        circleOfConfusionMm: _number(_coc.text),
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
    _focal.text = _defaultFocal;
    _aperture.text = _defaultAperture;
    _distance.text = _defaultDistance;
    _coc.text = _defaultCircleOfConfusion;
    setState(() {
      _selectedLens = null;
      _selectedCamera = null;
    });
    // Reset is an input change too: without this the shown answer would still
    // describe the values the user just discarded.
    _calculate();
  }
}

double _number(String text) => double.tryParse(text.trim()) ?? double.nan;
String _message(String code) => switch (code) {
  'not_beyond_focal_length' =>
    'Focus distance must be greater than focal length.',
  'result_out_of_range' => 'Increase the aperture or circle of confusion.',
  _ => 'Enter a positive finite value.',
};
String _distanceText(double millimetres, LengthDisplay display) =>
    formatDisplayLength(millimetres, display);
