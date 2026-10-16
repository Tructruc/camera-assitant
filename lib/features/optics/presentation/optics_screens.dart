/// Focus-family optics tools: field of view, diffraction, focus stacking.
///
/// Shared presentation helpers ([CalculatorLiveHint],
/// [FocusDistanceAdapterField]) live in this library so the depth-of-field and
/// macro screens in the same family reuse exactly the same live-answer signal
/// and millimetre adapter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../core/data/repositories/preferences_repository.dart';
import '../../../core/domain/calculation_snapshot.dart';
import '../../../core/domain/validation/validation.dart';
import '../../../core/presentation/calculator/calculation_result_view.dart';
import '../../../core/presentation/calculator/calculation_warning_text.dart';
import '../../../core/presentation/calculator/calculator_components.dart';
import '../../equipment/domain/equipment.dart';
import '../../equipment/presentation/equipment_controller.dart';
import '../../equipment/presentation/equipment_picker.dart';
import '../../equipment/presentation/equipment_specs.dart';
import '../domain/optics_calculators.dart';

/// One-line signal that the answer below tracks the inputs live.
///
/// These tools are cheap to evaluate, so there is no Calculate button to press:
/// every keystroke, preset and slider movement recalculates immediately.
class CalculatorLiveHint extends StatelessWidget {
  const CalculatorLiveHint({this.label = 'Updates as you adjust', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppGap.md),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.bolt_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppGap.xs),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raw millimetre readback of a metre-denominated distance field.
///
/// The canonical calculation input stays the millimetres held by [controller];
/// this control edits and echoes the exact raw value so nothing is lost behind
/// the metre display, and it writes through the same controller the metre
/// field uses.
class FocusDistanceAdapterField extends StatelessWidget {
  const FocusDistanceAdapterField({
    required this.controller,
    this.fieldKey,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final Key? fieldKey;
  final String? errorText;

  static const label = 'Focus distance (raw mm)';

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      controller: controller,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        helperText: FocusDistanceAdapterField.helperFor(
          double.tryParse(controller.text.trim()),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  /// Context line for the raw millimetre field, or `null` when it holds no
  /// usable value.
  static String? helperFor(double? millimetres) {
    if (millimetres == null || !millimetres.isFinite || millimetres <= 0) {
      return null;
    }
    // The field holds the canonical value, so the note names the unit and the
    // rounding of the metre field. It never calls the rounded display exact.
    return 'Stored in millimetres; the metre display is rounded.';
  }
}

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

/// One input of an optics tool, with the camera-standard presets that make it
/// adjustable without opening the keyboard.
class _OpticsField {
  const _OpticsField({
    required this.label,
    required this.initial,
    required this.key,
    this.presets = const <double>[],
    this.min,
    this.max,
    this.step,
    this.displayDivisor = 1,
    this.displayUnit,
    this.helperText,
  });

  /// Visible field label. Test-facing keys stay on [key], not on this string.
  final String label;
  final String initial;

  /// Canonical snapshot key and the stable widget-key suffix.
  final String key;

  /// Raw controller-unit presets (mm for lengths, f-numbers for apertures).
  final List<double> presets;
  final double? min;
  final double? max;
  final double? step;

  /// Raw units per displayed unit (1000 for a metre view of millimetres).
  final double displayDivisor;
  final String? displayUnit;
  final String? helperText;
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

  List<_OpticsField> get _fields => switch (widget.tool) {
    _OpticsTool.fieldOfView => const [
      _OpticsField(
        label: 'Sensor width (mm)',
        initial: '36',
        key: 'sensorWidthMm',
        presets: [17.3, 23.5, 36],
        helperText: 'Active image area, not the lens mount.',
      ),
      _OpticsField(
        label: 'Sensor height (mm)',
        initial: '24',
        key: 'sensorHeightMm',
        presets: [13, 15.6, 24],
      ),
      _OpticsField(
        label: 'Focal length (mm)',
        initial: '50',
        key: 'focalLengthMm',
        presets: [14, 24, 35, 50, 85, 135, 200],
      ),
      _OpticsField(
        label: 'Subject distance (m)',
        initial: '10000',
        key: 'distanceMm',
        presets: [1000, 2000, 5000, 10000, 25000, 50000],
        min: 100,
        max: 100000,
        step: 100,
        displayDivisor: 1000,
        displayUnit: 'm',
        helperText: 'Measured from the lens to the subject.',
      ),
    ],
    _OpticsTool.diffraction => const [
      _OpticsField(
        label: 'Aperture (f-number)',
        initial: '8',
        key: 'aperture',
        // Standard full stops: the buttons step between them instead of
        // counting arbitrary f-numbers.
        presets: [1, 1.4, 2, 2.8, 4, 5.6, 8, 11, 16, 22, 32],
      ),
      _OpticsField(
        label: 'Wavelength (nm)',
        initial: '550',
        key: 'wavelengthNm',
        presets: [450, 550, 650],
        helperText: '550 nm is the mid-daylight convention.',
      ),
      _OpticsField(
        label: 'Pixel pitch (µm)',
        initial: '4',
        key: 'pixelPitchMicrometres',
        presets: [3.76, 4.3, 5.9],
        helperText: 'From the camera specifications.',
      ),
    ],
    _OpticsTool.focusStack => const [
      _OpticsField(
        label: 'Focal length (mm)',
        initial: '100',
        key: 'focalLengthMm',
        presets: [35, 50, 85, 100, 135, 200],
      ),
      _OpticsField(
        label: 'Aperture (f-number)',
        initial: '8',
        key: 'aperture',
        presets: [1, 1.4, 2, 2.8, 4, 5.6, 8, 11, 16, 22, 32],
      ),
      _OpticsField(
        label: 'Near distance (m)',
        initial: '500',
        key: 'nearDistanceMm',
        presets: [300, 500, 1000, 2000, 5000],
        min: 100,
        max: 100000,
        step: 100,
        displayDivisor: 1000,
        displayUnit: 'm',
      ),
      _OpticsField(
        label: 'Far distance (m)',
        initial: '1000',
        key: 'farDistanceMm',
        presets: [500, 1000, 2000, 5000, 10000],
        min: 100,
        max: 100000,
        step: 100,
        displayDivisor: 1000,
        displayUnit: 'm',
      ),
      _OpticsField(
        label: 'Circle of confusion (mm)',
        initial: '0.03',
        key: 'circleOfConfusionMm',
        helperText:
            '0.03 mm is the 35 mm sharpness convention; '
            'a smaller sensor wants a smaller value.',
      ),
      _OpticsField(
        label: 'Overlap (%)',
        initial: '20',
        key: 'overlapPercent',
        presets: [10, 20, 30, 50],
        min: 0,
        max: 100,
        step: 1,
        helperText: 'A preference, not a physical measurement.',
      ),
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
      CalculatorFieldPair(first: _fieldFor(2), second: _fieldFor(3)),
    ],
  };

  List<Widget> get _advancedFields => switch (widget.tool) {
    _OpticsTool.fieldOfView => [
      CalculatorFieldPair(first: _fieldFor(0), second: _fieldFor(1)),
    ],
    _OpticsTool.diffraction => [
      // Only the wavelength is a convention here: the pixel pitch already
      // leads with the aperture above, and one parameter is one field.
      _fieldFor(1),
    ],
    _OpticsTool.focusStack => [
      CalculatorFieldPair(first: _fieldFor(4), second: _fieldFor(5)),
    ],
  };

  Widget _fieldFor(int index) {
    final field = _fields[index];
    return CalculatorNumberField(
      label: field.label,
      controller: _controllers[index],
      errorText: _errors[field.key],
      fieldKey: Key('${widget.tool.name}-${field.key}'),
      presets: field.presets,
      min: field.min,
      max: field.max,
      step: field.step,
      displayDivisor: field.displayDivisor,
      displayUnit: field.displayUnit,
      helperText: field.helperText,
    );
  }

  /// Value-equal signature of everything that changes the answer.
  ///
  /// A fresh object here would re-trigger the calculation on every rebuild and
  /// could clear a result the inputs still match, so this is a plain string.
  String get _signature => [
    widget.tool.name,
    _lengthDisplay.name,
    _camera?.id ?? '',
    _lens?.id ?? '',
    for (final controller in _controllers) controller.text.trim(),
  ].join('|');

  @override
  void initState() {
    super.initState();
    _controllers = [
      for (final field in _fields) TextEditingController(text: field.initial),
    ];
    // Seed the first answer so the screen leads with a result instead of an
    // empty space; the post-frame calculation keeps it fresh afterwards.
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
  Widget build(BuildContext context) {
    ref.watch(preferencesProvider);
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
      inputControllers: _controllers,
      calculationKey: _signature,
      onInputsChanged: () {
        // Cheap calculation, so the corrected answer is produced in the same
        // frame rather than invalidating the card and waiting for the
        // scheduled pass: an asynchronous gap would briefly show values that
        // no longer match the inputs.
        _calculate();
      },
      onCalculate: _calculate,
      children: [
        CalculatorHeader(icon: _icon, description: _description),
        const SizedBox(height: 16),
        // An empty equipment picker is not shown at all: manual entry is always
        // the primary path and the kit only fills values in.
        if (lenses.isNotEmpty)
          EquipmentPicker<Lens>(
            label: 'Saved lens (optional)',
            items: lenses,
            itemLabel: (item) => item.name,
            itemDetail: lensSpecSummary,
            value: _lens,
            onSelected: _applyLens,
          ),
        if (_lens case final lens?)
          AppliedEquipmentNotice(
            equipmentName: lens.name,
            sourceLabel: lens.provenance.source.label,
            appliedValues: _lensAppliedValues,
          ),
        // A saved camera supplies the sensor size (field of view) or the circle
        // of confusion (focus stacking), so it belongs with the shot
        // parameters. Diffraction reads a pixel pitch and a wavelength, which a
        // saved camera does not carry, so it keeps no camera picker. The picker
        // hides itself when the kit holds no camera.
        if (widget.tool != _OpticsTool.diffraction && cameras.isNotEmpty) ...[
          EquipmentPicker<CameraBody>(
            label: 'Saved camera (optional)',
            items: cameras,
            itemLabel: (item) => item.name,
            itemDetail: cameraSpecSummary,
            value: _camera,
            onSelected: _applyCamera,
          ),
          if (_camera case final camera?)
            AppliedEquipmentNotice(
              equipmentName: camera.name,
              sourceLabel: camera.provenance.source.label,
              appliedValues: widget.tool == _OpticsTool.fieldOfView
                  ? '${_controllers[0].text} × ${_controllers[1].text} mm sensor'
                  : '${_controllers[4].text} mm circle of confusion',
            ),
          const SizedBox(height: 12),
        ],
        ..._primaryFields,
        const CalculatorLiveHint(),
        if (_details case final details?) _resultView(details),
        CalculatorAdvancedSection(
          // Stable identity: applying equipment above must not collapse
          // the section the user is working in.
          key: const ValueKey('advanced'),
          children: _advancedFields,
        ),
      ],
    );
  }

  Widget _resultView(List<(String, String)> details) => CalculationResultView(
    title: '$_title result',
    highlight: _highlight,
    highlightCaption: _caption,
    tiles: _tiles,
    details: details,
    inputs: [
      for (var index = 0; index < _fields.length; index++)
        (_fields[index].label, _controllers[index].text.trim()),
    ],
    assumptions: _assumptions,
    warnings: _warningMessages,
    guidance: _guidance,
    onSave: _save,
    onReset: _reset,
  );

  double _value(int index) =>
      double.tryParse(_controllers[index].text.trim()) ?? double.nan;

  /// Recompute the shown answer from the current inputs.
  ///
  /// Called from `initState` (where `setState` is illegal) as well as from the
  /// page's live calculation hook, so the state write is inlined when the
  /// element is not mounted yet and goes through `setState` once it is.
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
            circleOfConfusionMm: _value(4),
            nearDistanceMm: _value(2),
            farDistanceMm: _value(3),
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
    if (mounted) {
      setState(() {});
    }
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
          _fields[index].key: _value(index),
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
              'circleOfConfusionMm': _value(4),
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
      _controllers[index].text = _fields[index].initial;
    }
    setState(() {
      _camera = null;
      _lens = null;
    });
    // Reset is an input change like any other: the live answer must reflect it
    // rather than the values the user just left behind.
    _calculate();
  }

  LengthDisplay get _lengthDisplay =>
      ref.read(preferencesProvider).valueOrNull?.lengthDisplay ??
      LengthDisplay.metric;

  String _distance(double mm) => formatDisplayLength(mm, _lengthDisplay);

  void _applyCamera(CameraBody? camera) {
    setState(() {
      _camera = camera;
      if (camera != null) {
        if (widget.tool == _OpticsTool.fieldOfView) {
          _controllers[0].text = camera.sensorWidthMm.toString();
          _controllers[1].text = camera.sensorHeightMm.toString();
        } else if (widget.tool == _OpticsTool.focusStack &&
            camera.defaultCircleOfConfusionMm != null) {
          _controllers[4].text = camera.defaultCircleOfConfusionMm.toString();
        }
      }
    });
    // Equipment provenance is part of the answer: even when the numeric text is
    // unchanged, a different saved item must be reflected in the live result.
    _calculate();
  }

  void _applyLens(Lens? lens) {
    setState(() {
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
    });
    // Applying equipment changes the values the answer is built on; recompute
    // now so the shown result always corresponds to the current inputs.
    _calculate();
  }

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
