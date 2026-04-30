import 'package:flutter/material.dart';
import 'package:camera_assistant/domain/calculators/long_exposure_calculator.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';

class LongExposureScreen extends StatefulWidget {
  const LongExposureScreen({super.key});

  @override
  State<LongExposureScreen> createState() => _LongExposureScreenState();
}

class _LongExposureScreenState extends State<LongExposureScreen> {
  final _baseShutter = TextEditingController(text: '1/60');
  final _ndStops = TextEditingController(text: '6');
  final _ndFactor = TextEditingController(text: '64');

  final _speed = TextEditingController(text: '8');
  final _exposure = TextEditingController(text: '1/2');
  final _subjectDistance = TextEditingController(text: '20');
  final _focal = TextEditingController(text: '50');
  final _pixelPitchUm = TextEditingController(text: '4.3');

  String _resultNd = 'No result';
  String _resultMotion = 'No result';

  @override
  void dispose() {
    _baseShutter.dispose();
    _ndStops.dispose();
    _ndFactor.dispose();
    _speed.dispose();
    _exposure.dispose();
    _subjectDistance.dispose();
    _focal.dispose();
    _pixelPitchUm.dispose();
    super.dispose();
  }

  void _calcNd() {
    final base = parseDouble(_baseShutter.text);
    final stops = parseDouble(_ndStops.text);
    final factor = parseDouble(_ndFactor.text);

    if (base == null || base <= 0) {
      setState(() => _resultNd = 'Base shutter must be positive.');
      return;
    }

    final byStops = (stops != null && stops >= 0)
        ? LongExposureCalculator.convertByStops(base, stops)
        : null;
    final byFactor = (factor != null && factor > 0)
        ? LongExposureCalculator.convertByFactor(base, factor)
        : null;

    setState(() {
      _resultNd =
          'By stops: ${byStops == null ? 'N/A' : formatSeconds(byStops)}\n'
          'By ND factor: ${byFactor == null ? 'N/A' : formatSeconds(byFactor)}';
    });
  }

  void _calcMotion() {
    final speed = parseDouble(_speed.text);
    final exposure = parseDouble(_exposure.text);
    final distance = parseDouble(_subjectDistance.text);
    final focal = parseDouble(_focal.text);
    final pixelPitch = parseDouble(_pixelPitchUm.text);

    if (speed == null || exposure == null || speed < 0 || exposure <= 0) {
      setState(() => _resultMotion = 'Speed must be >= 0 and exposure > 0.');
      return;
    }

    final physicalDistance =
        LongExposureCalculator.computePhysicalPath(speed, exposure);

    double? streakMm;
    double? streakPx;

    if (distance != null && focal != null && distance > 0 && focal > 0) {
      streakMm = LongExposureCalculator.computeSensorStreakMm(
          focal, physicalDistance, distance);
      if (streakMm != null && pixelPitch != null) {
        streakPx =
            LongExposureCalculator.computeSensorStreakPx(streakMm, pixelPitch);
      }
    }

    setState(() {
      _resultMotion =
          'Physical path: ${physicalDistance.toStringAsFixed(3)} m\n'
          'Sensor streak: ${streakMm == null ? 'N/A (provide focal length + distance)' : '${streakMm.toStringAsFixed(3)} mm'}\n'
          'Pixel streak: ${streakPx == null ? 'N/A (add pixel pitch)' : '${streakPx.toStringAsFixed(1)} px'}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          SectionCard(
            title: 'ND Conversion',
            children: [
              NumField(
                controller: _baseShutter,
                label: 'Base shutter',
                suffix: 'sec',
                allowFractions: true,
              ),
              NumField(
                  controller: _ndStops, label: 'ND stops', suffix: 'stops'),
              NumField(controller: _ndFactor, label: 'ND factor', suffix: 'x'),
              FilledButton(onPressed: _calcNd, child: const Text('Convert')),
              const SizedBox(height: 8),
              Text(_resultNd),
            ],
          ),
          SectionCard(
            title: 'Motion Blur Estimate',
            children: [
              NumField(
                  controller: _speed, label: 'Subject speed', suffix: 'm/s'),
              NumField(
                controller: _exposure,
                label: 'Exposure',
                suffix: 'sec',
                allowFractions: true,
              ),
              NumField(
                  controller: _subjectDistance,
                  label: 'Distance to subject',
                  suffix: 'm'),
              NumField(controller: _focal, label: 'Focal length', suffix: 'mm'),
              NumField(
                  controller: _pixelPitchUm,
                  label: 'Pixel pitch (optional)',
                  suffix: 'um'),
              FilledButton(
                  onPressed: _calcMotion, child: const Text('Estimate Motion')),
              const SizedBox(height: 8),
              Text(_resultMotion),
            ],
          ),
        ],
      ),
    );
  }
}
