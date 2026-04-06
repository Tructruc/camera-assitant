import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

enum MacroToolMode { extensionTubes, reverseLens, dualLens }

class MacroCalculatorScreen extends StatefulWidget {
  const MacroCalculatorScreen({
    super.key,
    required this.settings,
    this.initialMode = MacroToolMode.extensionTubes,
  });

  final AppSettings settings;
  final MacroToolMode initialMode;

  @override
  State<MacroCalculatorScreen> createState() => _MacroCalculatorScreenState();
}

class _MacroCalculatorScreenState extends State<MacroCalculatorScreen> {
  final _db = LensDatabase.instance;

  final _extensionFocalMm = TextEditingController(text: '50');
  final _extensionAperture = TextEditingController(text: '2.8');
  final _extensionMinFocusM = TextEditingController(text: '0.45');
  final _extensionTubeMm = TextEditingController(text: '25');

  final _reverseFocalMm = TextEditingController(text: '28');
  final _reverseAperture = TextEditingController(text: '2.8');
  final _reverseExtraExtensionMm = TextEditingController(text: '0');
  final _dualTakingFocalMm = TextEditingController(text: '100');
  final _dualTakingAperture = TextEditingController(text: '5.6');
  final _dualFrontFocalMm = TextEditingController(text: '50');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
  int? _selectedDualTakingLensId;
  int? _selectedDualFrontLensId;
  String? _selectedMountId;

  String? _extensionError;
  ExtensionTubeResult? _extensionResult;

  String? _reverseError;
  ReverseLensResult? _reverseResult;
  String? _dualError;
  DualLensMacroResult? _dualResult;

  bool get _showExtensionTool =>
      widget.initialMode == MacroToolMode.extensionTubes;

  bool get _showDualLensTool => widget.initialMode == MacroToolMode.dualLens;

  @override
  void initState() {
    super.initState();
    _loadLenses();
  }

  @override
  void dispose() {
    _extensionFocalMm.dispose();
    _extensionAperture.dispose();
    _extensionMinFocusM.dispose();
    _extensionTubeMm.dispose();
    _reverseFocalMm.dispose();
    _reverseAperture.dispose();
    _reverseExtraExtensionMm.dispose();
    _dualTakingFocalMm.dispose();
    _dualTakingAperture.dispose();
    _dualFrontFocalMm.dispose();
    super.dispose();
  }

  List<MountPreset> get _availableMounts {
    final enabled = widget.settings.enabledMountIds.toSet();
    final mounts = mountPresets
        .where((mount) => enabled.isEmpty || enabled.contains(mount.id))
        .toList();
    return mounts.isEmpty ? mountPresets.toList() : mounts;
  }

  MountPreset? get _selectedMount {
    for (final mount in _availableMounts) {
      if (mount.id == _selectedMountId) {
        return mount;
      }
    }
    return null;
  }

  Future<void> _loadLenses() async {
    final lenses = await _db.getLenses();
    if (!mounted) {
      return;
    }

    final selectedExists = lenses.any((lens) => lens.id == _selectedLensId);
    setState(() {
      _lenses = lenses;
      if (!selectedExists) {
        _selectedLensId = null;
      }
      final mounts = _availableMounts;
      if (mounts.isNotEmpty &&
          !mounts.any((mount) => mount.id == _selectedMountId)) {
        _selectedMountId = mounts.first.id;
      }
    });
  }

  void _applyLens(Lens lens) {
    if (_showExtensionTool) {
      _applyLensToExtension(lens);
    } else if (_showDualLensTool) {
      _applyLensToDualTaking(lens);
    } else {
      _applyLensToReverse(lens);
    }
  }

  void _applyLensToExtension(Lens lens) {
    final focal = lens.minFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    setState(() {
      _selectedLensId = lens.id;
      _extensionFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _extensionAperture.text = aperture.toStringAsFixed(1);
      _extensionMinFocusM.text = lens.minFocusDistanceM.toStringAsFixed(2);
    });
    _calculateExtension();
  }

  void _applyLensToReverse(Lens lens) {
    final focal = lens.minFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    setState(() {
      _selectedLensId = lens.id;
      _reverseFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _reverseAperture.text = aperture.toStringAsFixed(1);
    });
    _calculateReverse();
  }

  void _applyLensToDualTaking(Lens lens) {
    final focal = lens.maxFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    setState(() {
      _selectedDualTakingLensId = lens.id;
      _dualTakingFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _dualTakingAperture.text = aperture.toStringAsFixed(1);
    });
    _calculateDualLens();
  }

  void _applyLensToDualFront(Lens lens) {
    final focal = lens.minFocalLengthMm;
    setState(() {
      _selectedDualFrontLensId = lens.id;
      _dualFrontFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
    _calculateDualLens();
  }

  void _calculateExtension() {
    final focal = parseDouble(_extensionFocalMm.text);
    final aperture = parseDouble(_extensionAperture.text);
    final minFocusDistance = parseDouble(_extensionMinFocusM.text);
    final tubeLength = parseDouble(_extensionTubeMm.text);

    if (focal == null ||
        aperture == null ||
        minFocusDistance == null ||
        tubeLength == null ||
        focal <= 0 ||
        aperture <= 0 ||
        minFocusDistance <= 0 ||
        tubeLength < 0) {
      setState(() {
        _extensionError =
            'Enter valid values. Tube length may be zero, all other values must be positive.';
        _extensionResult = null;
      });
      return;
    }

    setState(() {
      _extensionError = null;
      _extensionResult = MacroCalculator.calculateExtensionTube(
        focalLengthMm: focal,
        aperture: aperture,
        minimumFocusDistanceM: minFocusDistance,
        extensionLengthMm: tubeLength,
      );
    });
  }

  void _calculateReverse() {
    final focal = parseDouble(_reverseFocalMm.text);
    final aperture = parseDouble(_reverseAperture.text);
    final extraExtension = parseDouble(_reverseExtraExtensionMm.text);
    final mount = _selectedMount;

    if (focal == null ||
        aperture == null ||
        extraExtension == null ||
        mount == null ||
        focal <= 0 ||
        aperture <= 0 ||
        extraExtension < 0) {
      setState(() {
        _reverseError =
            'Select a mount and enter valid focal length, aperture, and extra extension values.';
        _reverseResult = null;
      });
      return;
    }

    final totalExtension = mount.registerDistanceMm + extraExtension;

    setState(() {
      _reverseError = null;
      _reverseResult = MacroCalculator.calculateReverseLens(
        focalLengthMm: focal,
        aperture: aperture,
        extensionBehindLensMm: totalExtension,
      );
    });
  }

  void _calculateDualLens() {
    final takingFocal = parseDouble(_dualTakingFocalMm.text);
    final takingAperture = parseDouble(_dualTakingAperture.text);
    final frontFocal = parseDouble(_dualFrontFocalMm.text);

    if (takingFocal == null ||
        takingAperture == null ||
        frontFocal == null ||
        takingFocal <= 0 ||
        takingAperture <= 0 ||
        frontFocal <= 0) {
      setState(() {
        _dualError =
            'Enter valid taking-lens focal length, aperture, and reversed front-lens focal length values.';
        _dualResult = null;
      });
      return;
    }

    setState(() {
      _dualError = null;
      _dualResult = MacroCalculator.calculateDualLensMacro(
        takingLensFocalLengthMm: takingFocal,
        takingLensAperture: takingAperture,
        frontLensFocalLengthMm: frontFocal,
      );
    });
  }

  String _formatMagnification(double value) => '${value.toStringAsFixed(2)}x';

  String _formatRatio(double value) {
    if (value <= 0) {
      return 'n/a';
    }
    if ((value - 1).abs() < 0.01) {
      return '1:1';
    }
    if (value > 1) {
      return '${value.toStringAsFixed(2)}:1';
    }
    return '1:${(1 / value).toStringAsFixed(1)}';
  }

  String _formatDistance(double valueM) {
    if (!valueM.isFinite) {
      return 'Infinity';
    }
    return '${valueM.toStringAsFixed(2)} m';
  }

  String _formatStops(double value) => '+${value.toStringAsFixed(2)} stops';

  String _formatFactor(double value) => '${value.toStringAsFixed(2)}x';

  Widget _buildLensPicker(
    BuildContext context, {
    required String hint,
    required String helper,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_selectedLensId),
          initialValue: _selectedLensId,
          isExpanded: true,
          hint: Text(hint),
          items: _lenses
              .map(
                (lens) => DropdownMenuItem<int>(
                  value: lens.id,
                  child: Text(
                    lens.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => _lenses
              .map(
                (lens) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lens.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final lensIndex = _lenses.indexWhere((lens) => lens.id == value);
            if (lensIndex >= 0) {
              _applyLens(_lenses[lensIndex]);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _lenses.isEmpty
                    ? 'No saved lenses yet. Enter values manually or add one in Settings.'
                    : helper,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: _loadLenses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDualLensPicker(
    BuildContext context, {
    required int? selectedLensId,
    required String hint,
    required String helper,
    required ValueChanged<Lens> onSelected,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(selectedLensId),
          initialValue: selectedLensId,
          isExpanded: true,
          hint: Text(hint),
          items: _lenses
              .map(
                (lens) => DropdownMenuItem<int>(
                  value: lens.id,
                  child: Text(
                    lens.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final lensIndex = _lenses.indexWhere((lens) => lens.id == value);
            if (lensIndex >= 0) {
              onSelected(_lenses[lensIndex]);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _lenses.isEmpty
                    ? 'No saved lenses yet. Enter values manually or add one in Settings.'
                    : helper,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: _loadLenses,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildExtensionTool(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Extension Tubes',
          subtitle:
              'Estimate close-focus range and magnification with extension tubes.',
          children: [
            _buildLensPicker(
              context,
              hint: 'Start from a saved lens',
              helper: 'A saved lens can fill these values for you.',
            ),
            NumField(
              controller: _extensionFocalMm,
              label: 'Focal length',
              suffix: 'mm',
            ),
            NumField(
              controller: _extensionAperture,
              label: 'Aperture',
              suffix: 'f',
            ),
            NumField(
              controller: _extensionMinFocusM,
              label: 'Lens minimum focus distance',
              suffix: 'm',
            ),
            NumField(
              controller: _extensionTubeMm,
              label: 'Total extension tube length',
              suffix: 'mm',
            ),
            FilledButton(
              onPressed: _calculateExtension,
              child: const Text('Calculate Extension'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_extensionError != null)
              Text(
                _extensionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_extensionResult == null)
              Text(
                'Tap calculate to see focus range, magnification, and light loss.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricTile(
                    label: 'Native close focus',
                    value:
                        '${_formatMagnification(_extensionResult!.nativeMaximumMagnification)} | ${_formatRatio(_extensionResult!.nativeMaximumMagnification)}',
                  ),
                  _MetricTile(
                    label: 'Tube gain',
                    value: _formatMagnification(
                        _extensionResult!.addedMagnification),
                  ),
                  _MetricTile(
                    label: 'Magnification range',
                    value:
                        '${_formatMagnification(_extensionResult!.minimumMagnification)} to ${_formatMagnification(_extensionResult!.maximumMagnification)}',
                  ),
                  _MetricTile(
                    label: 'Macro ratio range',
                    value:
                        '${_formatRatio(_extensionResult!.minimumMagnification)} to ${_formatRatio(_extensionResult!.maximumMagnification)}',
                  ),
                  _MetricTile(
                    label: 'Closest focus',
                    value: _formatDistance(
                        _extensionResult!.closestFocusDistanceM),
                  ),
                  _MetricTile(
                    label: 'Farthest focus',
                    value: _formatDistance(
                        _extensionResult!.farthestFocusDistanceM),
                  ),
                  _MetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_extensionResult!.effectiveApertureAtFarthestFocus.toStringAsFixed(1)} to f/${_extensionResult!.effectiveApertureAtClosestFocus.toStringAsFixed(1)}',
                  ),
                  _MetricTile(
                    label: 'Light loss',
                    value:
                        '${_formatStops(_extensionResult!.lightLossStopsAtFarthestFocus)} to ${_formatStops(_extensionResult!.lightLossStopsAtClosestFocus)}',
                  ),
                  _MetricTile(
                    label: 'Exposure factor',
                    value:
                        '${_formatFactor(_extensionResult!.exposureFactorAtFarthestFocus)} to ${_formatFactor(_extensionResult!.exposureFactorAtClosestFocus)}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'These values are estimates and may vary from real-world results.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReverseTool(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Reverse Lens',
          subtitle: 'Estimate magnification for a reversed lens setup.',
          children: [
            _buildLensPicker(
              context,
              hint: 'Start from a saved lens',
              helper: 'A saved lens can fill focal length and aperture.',
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedMountId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mount'),
              items: _availableMounts
                  .map(
                    (mount) => DropdownMenuItem<String>(
                      value: mount.id,
                      child: Text(mount.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => _selectedMountId = value);
                _calculateReverse();
              },
            ),
            const SizedBox(height: 12),
            NumField(
              controller: _reverseFocalMm,
              label: 'Reversed lens focal length',
              suffix: 'mm',
            ),
            NumField(
              controller: _reverseAperture,
              label: 'Aperture',
              suffix: 'f',
            ),
            NumField(
              controller: _reverseExtraExtensionMm,
              label: 'Extra extension',
              suffix: 'mm',
            ),
            if (_selectedMountId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mount register distance: ${_selectedMount!.registerDistanceMm.toStringAsFixed(1)} mm',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            FilledButton(
              onPressed: _calculateReverse,
              child: const Text('Calculate Reverse Lens'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_reverseError != null)
              Text(
                _reverseError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_reverseResult == null)
              Text(
                'Tap calculate to see magnification, light loss, and focus distance.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricTile(
                    label: 'Magnification',
                    value:
                        '${_formatMagnification(_reverseResult!.magnification)} | ${_formatRatio(_reverseResult!.magnification)}',
                  ),
                  _MetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_reverseResult!.effectiveAperture.toStringAsFixed(1)}',
                  ),
                  _MetricTile(
                    label: 'Light loss',
                    value: _formatStops(_reverseResult!.lightLossStops),
                  ),
                  _MetricTile(
                    label: 'Exposure factor',
                    value: _formatFactor(_reverseResult!.exposureFactor),
                  ),
                  _MetricTile(
                    label: 'Total extension',
                    value:
                        '${(_selectedMount!.registerDistanceMm + (parseDouble(_reverseExtraExtensionMm.text) ?? 0)).toStringAsFixed(1)} mm',
                  ),
                  _MetricTile(
                    label: 'Subject distance',
                    value: _formatDistance(
                      _reverseResult!.subjectDistanceFromLensPlaneM,
                    ),
                  ),
                  _MetricTile(
                    label: 'Sensor-to-subject',
                    value: _formatDistance(
                      _reverseResult!.subjectDistanceFromSensorPlaneM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Focus distance is an estimate and may differ from your real setup.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDualLensTool(BuildContext context) {
    return Column(
      children: [
        SectionCard(
          title: 'Dual Lens Macro',
          subtitle:
              'Estimate a stacked-lens setup with a taking lens focused at infinity and a reversed front lens.',
          children: [
            _buildDualLensPicker(
              context,
              selectedLensId: _selectedDualTakingLensId,
              hint: 'Pick the taking lens',
              helper:
                  'Using a saved lens here fills the taking-lens focal length and aperture.',
              onSelected: _applyLensToDualTaking,
            ),
            NumField(
              controller: _dualTakingFocalMm,
              label: 'Taking lens focal length',
              suffix: 'mm',
            ),
            NumField(
              controller: _dualTakingAperture,
              label: 'Taking lens aperture',
              suffix: 'f',
            ),
            const SizedBox(height: 8),
            _buildDualLensPicker(
              context,
              selectedLensId: _selectedDualFrontLensId,
              hint: 'Pick the reversed front lens',
              helper:
                  'Using a saved lens here fills the reversed front-lens focal length.',
              onSelected: _applyLensToDualFront,
            ),
            NumField(
              controller: _dualFrontFocalMm,
              label: 'Reversed front-lens focal length',
              suffix: 'mm',
            ),
            FilledButton(
              onPressed: _calculateDualLens,
              child: const Text('Calculate Dual Lens Macro'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_dualError != null)
              Text(
                _dualError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_dualResult == null)
              Text(
                'Tap calculate to see magnification, effective aperture, and working distance.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetricTile(
                    label: 'Magnification',
                    value:
                        '${_formatMagnification(_dualResult!.magnification)} | ${_formatRatio(_dualResult!.magnification)}',
                  ),
                  _MetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_dualResult!.effectiveAperture.toStringAsFixed(1)}',
                  ),
                  _MetricTile(
                    label: 'Light loss',
                    value: _formatStops(_dualResult!.lightLossStops),
                  ),
                  _MetricTile(
                    label: 'Exposure factor',
                    value: _formatFactor(_dualResult!.exposureFactor),
                  ),
                  _MetricTile(
                    label: 'Approx. working distance',
                    value: _formatDistance(
                      _dualResult!.workingDistanceFromFrontLensM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This model assumes both lenses are coupled and focused at infinity. Real spacing and adapter thickness can shift the result slightly.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _showExtensionTool
          ? _buildExtensionTool(context)
          : _showDualLensTool
              ? _buildDualLensTool(context)
              : _buildReverseTool(context),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: 172,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
