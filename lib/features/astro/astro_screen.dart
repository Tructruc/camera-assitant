import 'package:camera_assistant/app/app_dependencies.dart';
import 'package:camera_assistant/core/formatting/seconds_formatter.dart';
import 'package:camera_assistant/data/lenses/sqlite_lens_repository.dart';
import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/astro/astro_controller.dart';
import 'package:camera_assistant/features/astro/astro_state.dart';
import 'package:camera_assistant/features/astro/widgets/astro_framing_preview.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_controller.dart';
import 'package:camera_assistant/shared/lenses/lens_selection_state.dart';
import 'package:camera_assistant/shared/widgets/info_metric_tile.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

class AstroScreen extends StatefulWidget {
  const AstroScreen({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<AstroScreen> createState() => _AstroScreenState();
}

class _AstroScreenState extends State<AstroScreen> {
  final _controller = const AstroController();
  final _focalMm = TextEditingController(text: '400');

  LensSelectionController? _lensSelection;
  LensSelectionState _lensSelectionState = const LensSelectionState();

  late SensorPreset _selectedSensor;
  AstroToolMode _toolMode = AstroToolMode.framing;
  AstroShutterRule _selectedRule = AstroShutterRule.rule400;
  AstroFramingTarget _selectedTarget = AstroFramingTarget.moon;
  AstroFramingOrientation _selectedOrientation =
      AstroFramingOrientation.landscape;

  String? _errorMessage;
  AstroCalculatorResult? _shutterResult;
  AstroFramingResult? _framingResult;

  List<SensorPreset> get _availableSensors =>
      resolveEnabledSensorPresets(widget.settings.enabledSensorIds);

  List<Lens> get _lenses => _lensSelectionState.lenses;
  int? get _selectedLensId => _lensSelectionState.selectedLensId;
  Lens? get _selectedLens => _lensSelectionState.selectedLens;

  @override
  void initState() {
    super.initState();
    _selectedSensor = _availableSensors.first;
    _focalMm.addListener(_calculateLive);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_lensSelection != null) {
      return;
    }

    _lensSelection = LensSelectionController(
      repository: AppDependenciesScope.maybeOf(context)?.lenses ??
          SqliteLensRepository(),
    );
    _loadLenses();
    _calculate();
  }

  @override
  void dispose() {
    _focalMm.removeListener(_calculateLive);
    _focalMm.dispose();
    super.dispose();
  }

  void _calculateLive() => _calculate(live: true);

  Future<void> _loadLenses() async {
    final controller = _lensSelection;
    if (controller == null) {
      return;
    }

    setState(() {
      _lensSelectionState = controller.state.copyWith(loading: true);
    });

    final state = await controller.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _lensSelectionState = state;
    });
  }

  void _clearSelectedLens() {
    setState(() {
      _lensSelectionState =
          _lensSelection?.clearSelection() ?? const LensSelectionState();
    });
    _calculate(live: true);
  }

  void _applyLens(Lens lens) {
    setState(() {
      _lensSelectionState =
          _lensSelection?.selectLens(lens) ?? _lensSelectionState;
      _focalMm.text = _controller.focalFromSelectedLens(lens);
    });
    _calculate(live: true);
  }

  void _updateLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }

    setState(() {
      _focalMm.text = _controller.clampAndFormatFocalForLens(lens, value);
    });
    _calculate(live: true);
  }

  void _calculate({bool live = false}) {
    final state = _controller.calculateFromForm(
      focalLengthText: _focalMm.text,
      sensor: _selectedSensor,
      rule: _selectedRule,
      target: _selectedTarget,
      orientation: _selectedOrientation,
      live: live,
    );

    setState(() {
      switch (state) {
        case AstroCalculationSuccess(
            :final shutterResult,
            :final framingResult,
          ):
          _errorMessage = null;
          _shutterResult = shutterResult;
          _framingResult = framingResult;
        case AstroCalculationError(:final message):
          _errorMessage = message;
          _shutterResult = null;
          _framingResult = null;
      }
    });
  }

  Future<void> _showRuleHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shutter rule'),
        content: const Text(
          'These are quick star-trailing rules based on full-frame equivalent focal length. '
          '500 is looser, 400 is a safer default, and 300 is stricter for cleaner stars.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTargetHelp() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Celestial framing'),
        content: const Text(
          'Moon and Sun are drawn at their average apparent diameter. A star remains a point source, so focal length mostly changes how much sky fits in the frame.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatMm(double value) {
    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)} mm';
    }
    return '${value.toStringAsFixed(1)} mm';
  }

  String _formatAngle(double value) => '${value.toStringAsFixed(1)}°';
  String _formatPercent(double value) => '${(value * 100).toStringAsFixed(1)}%';
  String _formatScale(double value) => '${value.toStringAsFixed(1)}x';

  Widget _buildToolSelector() {
    return SectionCard(
      title: 'Tool',
      children: [
        SegmentedButton<AstroToolMode>(
          showSelectedIcon: false,
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(
              value: AstroToolMode.framing,
              label: Text('Framing'),
              icon: Icon(Icons.crop_free),
            ),
            ButtonSegment(
              value: AstroToolMode.shutter,
              label: Text('Shutter'),
              icon: Icon(Icons.shutter_speed),
            ),
          ],
          selected: {_toolMode},
          onSelectionChanged: (selection) {
            setState(() => _toolMode = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildLensSection(Lens? lens) {
    return SectionCard(
      title: 'Lens',
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_selectedLensId),
          initialValue: _selectedLensId,
          isExpanded: true,
          hint: const Text('Use a saved lens'),
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
            final selectedLens = _lensSelection?.lensById(value);
            if (selectedLens != null) {
              _applyLens(selectedLens);
            }
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _loadLenses,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh lenses'),
              ),
              if (_selectedLensId != null)
                TextButton.icon(
                  onPressed: _clearSelectedLens,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Enter manually'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (lens == null)
          NumField(
            controller: _focalMm,
            label: 'Focal length',
            suffix: 'mm',
          )
        else if (lens.isZoom)
          LensValueSlider(
            label: 'Focal length',
            minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
            maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
            min: lens.minFocalLengthMm,
            max: lens.maxFocalLengthMm,
            value: (double.tryParse(_focalMm.text) ?? lens.minFocalLengthMm)
                .clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm),
            controller: _focalMm,
            suffix: 'mm',
            onChanged: _updateLensFocal,
          ),
      ],
    );
  }

  Widget _buildInputsSection() {
    return SectionCard(
      title: 'Inputs',
      children: [
        if (_availableSensors.length > 1) ...[
          DropdownButtonFormField<SensorPreset>(
            initialValue: _selectedSensor,
            decoration: const InputDecoration(
              labelText: 'Sensor format',
            ),
            items: _availableSensors
                .map(
                  (sensor) => DropdownMenuItem<SensorPreset>(
                    value: sensor,
                    child: Text(sensor.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedSensor = value);
              _calculate();
            },
          ),
          const SizedBox(height: 12),
        ],
        if (_toolMode == AstroToolMode.shutter) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Shutter rule',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                onPressed: _showRuleHelp,
                icon: const Icon(Icons.help_outline),
                tooltip: 'Shutter rule help',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AstroShutterRule>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: AstroShutterRule.rule500,
                  label: Text('500'),
                ),
                ButtonSegment(
                  value: AstroShutterRule.rule400,
                  label: Text('400'),
                ),
                ButtonSegment(
                  value: AstroShutterRule.rule300,
                  label: Text('300'),
                ),
              ],
              selected: {_selectedRule},
              onSelectionChanged: (selection) {
                setState(() => _selectedRule = selection.first);
                _calculate();
              },
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              IconButton(
                onPressed: _showTargetHelp,
                icon: const Icon(Icons.help_outline),
                tooltip: 'Target help',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AstroFramingTarget>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: AstroFramingTarget.moon,
                  label: Text('Moon'),
                ),
                ButtonSegment(
                  value: AstroFramingTarget.sun,
                  label: Text('Sun'),
                ),
                ButtonSegment(
                  value: AstroFramingTarget.star,
                  label: Text('Star'),
                ),
              ],
              selected: {_selectedTarget},
              onSelectionChanged: (selection) {
                setState(() => _selectedTarget = selection.first);
                _calculate();
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<AstroFramingOrientation>(
              showSelectedIcon: false,
              expandedInsets: EdgeInsets.zero,
              segments: const [
                ButtonSegment(
                  value: AstroFramingOrientation.landscape,
                  label: Text('Landscape'),
                  icon: Icon(Icons.crop_landscape),
                ),
                ButtonSegment(
                  value: AstroFramingOrientation.portrait,
                  label: Text('Portrait'),
                  icon: Icon(Icons.stay_current_portrait),
                ),
              ],
              selected: {_selectedOrientation},
              onSelectionChanged: (selection) {
                setState(() => _selectedOrientation = selection.first);
                _calculate();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShutterOutput() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (_shutterResult == null) {
      return Text(
        'No result',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InfoMetricTile(
          label: 'Max shutter',
          value: formatFractionalSeconds(_shutterResult!.maxShutterSeconds),
          helpText:
              'Estimated longest exposure before star trailing becomes obvious under the selected rule.',
        ),
        InfoMetricTile(
          label: 'FF equivalent',
          value: _formatMm(_shutterResult!.equivalentFocalLengthMm),
          helpText:
              'The full-frame equivalent focal length after crop factor is applied.',
        ),
        InfoMetricTile(
          label: 'Crop factor',
          value: '${_shutterResult!.cropFactor.toStringAsFixed(2)}x',
          helpText:
              'How much smaller this sensor is relative to full frame when using diagonal crop.',
        ),
      ],
    );
  }

  Widget _buildFramingPreview() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (_framingResult == null) {
      return Text(
        'No preview',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final focal = double.tryParse(_focalMm.text) ?? 0;
    return Center(
      child: AstroFramingPreview(
        result: _framingResult!,
        focalLengthMm: focal,
        sensorLabel: _selectedSensor.label,
      ),
    );
  }

  Widget _buildFramingOutput() {
    if (_errorMessage != null) {
      return Text(
        _errorMessage!,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    if (_framingResult == null) {
      return Text(
        'No result',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final coverageTile = _selectedTarget == AstroFramingTarget.star
        ? const InfoMetricTile(
            label: 'Target size',
            value: 'Point-like',
            helpText:
                'A star stays unresolved in normal photography. Focal length narrows the field of view around it but does not reveal a visible disk.',
          )
        : InfoMetricTile(
            label: 'Frame width used',
            value: _formatPercent(_framingResult!.frameWidthCoverage),
            helpText:
                'How much of the frame width the selected target occupies at this focal length and sensor size.',
          );

    final imageSizeTile = _selectedTarget == AstroFramingTarget.star
        ? InfoMetricTile(
            label: 'Relative zoom',
            value: _formatScale(_framingResult!.relativeMagnificationTo50mm),
            helpText:
                'Approximate framing magnification relative to a 50 mm full-frame reference.',
          )
        : InfoMetricTile(
            label: 'Sensor image',
            value: _formatMm(_framingResult!.objectImageDiameterMm),
            helpText:
                'Approximate image diameter projected onto the sensor by the target’s angular size.',
          );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InfoMetricTile(
          label: 'Horizontal FOV',
          value: _formatAngle(_framingResult!.horizontalFovDeg),
          helpText: 'Angle of view across the frame width.',
        ),
        InfoMetricTile(
          label: 'Vertical FOV',
          value: _formatAngle(_framingResult!.verticalFovDeg),
          helpText: 'Angle of view across the frame height.',
        ),
        InfoMetricTile(
          label: 'Diagonal FOV',
          value: _formatAngle(_framingResult!.diagonalFovDeg),
          helpText: 'Angle of view across the frame diagonal.',
        ),
        coverageTile,
        imageSizeTile,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lens = _selectedLens;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildToolSelector(),
          _buildLensSection(lens),
          _buildInputsSection(),
          if (_toolMode == AstroToolMode.framing)
            SectionCard(
              title: 'Preview',
              subtitle:
                  'Frame the ${_selectedTarget.label.toLowerCase()} at ${_focalMm.text.trim()} mm on ${_selectedSensor.label}.',
              children: [_buildFramingPreview()],
            ),
          SectionCard(
            title: 'Output',
            children: [
              if (_toolMode == AstroToolMode.shutter)
                _buildShutterOutput()
              else
                _buildFramingOutput(),
            ],
          ),
        ],
      ),
    );
  }
}
