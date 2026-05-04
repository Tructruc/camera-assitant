import 'dart:math' as math;

import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/info_metric_tile.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

enum AstroToolMode { shutter, framing }

class AstroCalculatorScreen extends StatefulWidget {
  const AstroCalculatorScreen({
    super.key,
    required this.settings,
  });

  final AppSettings settings;

  @override
  State<AstroCalculatorScreen> createState() => _AstroCalculatorScreenState();
}

class _AstroCalculatorScreenState extends State<AstroCalculatorScreen> {
  final _db = LensDatabase.instance;
  final _focalMm = TextEditingController(text: '400');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
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

  Lens? get _selectedLens {
    if (_selectedLensId == null) {
      return null;
    }
    for (final lens in _lenses) {
      if (lens.id == _selectedLensId) {
        return lens;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _selectedSensor = _availableSensors.first;
    _focalMm.addListener(_calculateLive);
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
    });
  }

  void _clearSelectedLens() {
    setState(() {
      _selectedLensId = null;
    });
    _calculate();
  }

  void _applyLens(Lens lens) {
    final focal = lens.minFocalLengthMm;
    setState(() {
      _selectedLensId = lens.id;
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
    _calculate();
  }

  void _updateLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    setState(() {
      _focalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
    _calculate();
  }

  void _calculate({bool live = false}) {
    final focal = parseDouble(_focalMm.text);

    if (focal == null || focal <= 0) {
      setState(() {
        _errorMessage = live ? null : 'Enter a valid focal length.';
        _shutterResult = null;
        _framingResult = null;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _shutterResult = AstroCalculator.calculateMaxShutter(
        focalLengthMm: focal,
        sensorWidthMm: _selectedSensor.widthMm,
        sensorHeightMm: _selectedSensor.heightMm,
        rule: _selectedRule,
      );
      _framingResult = AstroCalculator.calculateFraming(
        focalLengthMm: focal,
        sensorWidthMm: _selectedSensor.widthMm,
        sensorHeightMm: _selectedSensor.heightMm,
        target: _selectedTarget,
        orientation: _selectedOrientation,
      );
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
            final lensIndex = _lenses.indexWhere((lens) => lens.id == value);
            if (lensIndex >= 0) {
              _applyLens(_lenses[lensIndex]);
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
      child: _AstroFramingPreview(
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
        ? InfoMetricTile(
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

class _AstroFramingPreview extends StatelessWidget {
  const _AstroFramingPreview({
    required this.result,
    required this.focalLengthMm,
    required this.sensorLabel,
  });

  final AstroFramingResult result;
  final double focalLengthMm;
  final String sensorLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final aspect = result.frameWidthMm / result.frameHeightMm;

    return LayoutBuilder(
      builder: (context, constraints) {
        var width = math.min(constraints.maxWidth, 340.0);
        var height = width / aspect;
        if (height > 340) {
          height = 340;
          width = height * aspect;
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(width, height),
                painter: _AstroFramingPainter(
                  result: result,
                  colorScheme: scheme,
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: _PreviewBadge(
                  label:
                      '${result.target.label} | ${focalLengthMm.toStringAsFixed(focalLengthMm.truncateToDouble() == focalLengthMm ? 0 : 1)} mm',
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: _PreviewBadge(label: sensorLabel),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AstroFramingPainter extends CustomPainter {
  const _AstroFramingPainter({
    required this.result,
    required this.colorScheme,
  });

  final AstroFramingResult result;
  final ColorScheme colorScheme;

  static const _starPoints = [
    Offset(0.10, 0.18),
    Offset(0.21, 0.72),
    Offset(0.28, 0.32),
    Offset(0.36, 0.58),
    Offset(0.44, 0.22),
    Offset(0.57, 0.76),
    Offset(0.63, 0.14),
    Offset(0.71, 0.40),
    Offset(0.82, 0.26),
    Offset(0.88, 0.68),
    Offset(0.17, 0.48),
    Offset(0.77, 0.55),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintReferenceGrid(canvas, size);
    _paintFieldStars(canvas, size);
    _paintTarget(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (result.target) {
      AstroFramingTarget.sun => [
          const Color(0xFF090B10),
          const Color(0xFF1A1410),
        ],
      AstroFramingTarget.moon => [
          const Color(0xFF06070C),
          const Color(0xFF111522),
        ],
      AstroFramingTarget.star => [
          const Color(0xFF05060A),
          const Color(0xFF0C1120),
        ],
    };

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintReferenceGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    canvas.drawLine(
        Offset(centerX, 0), Offset(centerX, size.height), gridPaint);
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);
  }

  void _paintFieldStars(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.8);

    for (var i = 0; i < _starPoints.length; i++) {
      final point = Offset(
        _starPoints[i].dx * size.width,
        _starPoints[i].dy * size.height,
      );
      final radius = 0.8 + (i % 3) * 0.5;
      canvas.drawCircle(point, radius, paint);
    }
  }

  void _paintTarget(Canvas canvas, Size size) {
    final pixelsPerMm = size.width / result.frameWidthMm;
    final diameterPx = result.objectImageDiameterMm * pixelsPerMm;
    final center = size.center(Offset.zero);

    switch (result.target) {
      case AstroFramingTarget.moon:
        _paintMoon(canvas, center, diameterPx);
      case AstroFramingTarget.sun:
        _paintSun(canvas, center, diameterPx);
      case AstroFramingTarget.star:
        _paintStar(canvas, center, size);
    }
  }

  void _paintMoon(Canvas canvas, Offset center, double diameterPx) {
    final radius = math.max(diameterPx / 2, 1.2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFF4F4EF),
          const Color(0xFFB7BCC6),
          const Color(0xFF818896),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, discPaint);

    final craterPaint = Paint()
      ..color = const Color(0xFF79818C).withValues(alpha: 0.28);
    final craterOffsets = [
      const Offset(-0.18, -0.12),
      const Offset(0.14, -0.04),
      const Offset(-0.08, 0.16),
      const Offset(0.2, 0.18),
    ];
    for (final offset in craterOffsets) {
      canvas.drawCircle(
        Offset(
            center.dx + (offset.dx * radius), center.dy + (offset.dy * radius)),
        radius * 0.16,
        craterPaint,
      );
    }
  }

  void _paintSun(Canvas canvas, Offset center, double diameterPx) {
    final radius = math.max(diameterPx / 2, 1.2);
    final glowRect = Rect.fromCircle(center: center, radius: radius * 1.7);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.45),
          const Color(0xFFFFD54F).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(glowRect);
    canvas.drawCircle(center, radius * 1.7, glowPaint);

    final discRect = Rect.fromCircle(center: center, radius: radius);
    final discPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFF5C3),
          const Color(0xFFFFD54F),
          const Color(0xFFF9A825),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(discRect);
    canvas.drawCircle(center, radius, discPaint);
  }

  void _paintStar(Canvas canvas, Offset center, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFDDE7FF).withValues(alpha: 0.95),
          const Color(0xFF7FB3FF).withValues(alpha: 0.28),
          Colors.transparent,
        ],
        stops: const [0.0, 0.32, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: 24));
    canvas.drawCircle(center, 24, glowPaint);

    final spikePaint = Paint()
      ..color = const Color(0xFFDDE7FF).withValues(alpha: 0.9)
      ..strokeWidth = 1.2;
    canvas.drawLine(
      Offset(center.dx - math.min(size.width, 28) / 2, center.dy),
      Offset(center.dx + math.min(size.width, 28) / 2, center.dy),
      spikePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - math.min(size.height, 28) / 2),
      Offset(center.dx, center.dy + math.min(size.height, 28) / 2),
      spikePaint,
    );

    final corePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 1.8, corePaint);
  }

  @override
  bool shouldRepaint(covariant _AstroFramingPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.colorScheme != colorScheme;
  }
}
