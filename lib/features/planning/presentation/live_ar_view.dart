import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/data/repositories/preferences_repository.dart';
import '../data/device_planning_service.dart';
import '../domain/north_reference.dart';

class LiveArView extends StatefulWidget {
  const LiveArView({
    required this.azimuthDegrees,
    required this.altitudeDegrees,
    required this.isSun,
    this.northReference = NorthReference.trueNorth,
    this.magneticDeclinationDegrees = 0,
    this.service = const DevicePlanningService(),
    super.key,
  });
  final double azimuthDegrees;
  final double altitudeDegrees;
  final bool isSun;
  final NorthReference northReference;
  final double magneticDeclinationDegrees;
  final DevicePlanningService service;
  @override
  State<LiveArView> createState() => _LiveArViewState();
}

class _LiveArViewState extends State<LiveArView> {
  CameraController? _controller;
  Object? _error;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw StateError('No camera is available on this device.');
      }
      final back =
          cameras
              .where(
                (camera) => camera.lensDirection == CameraLensDirection.back,
              )
              .firstOrNull ??
          cameras.first;
      final controller = CameraController(
        back,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _fallback(
        'Camera unavailable or permission denied. Use the compass and numeric views instead.',
      );
    }
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(controller),
          StreamBuilder<DeviceHeadingReading>(
            stream: widget.service.headingStream(),
            builder: (context, snapshot) {
              final reading = snapshot.data;
              final heading =
                  reading?.cameraHeadingDegrees ?? reading?.headingDegrees;
              final targetBearing =
                  widget.northReference == NorthReference.magneticNorth
                  ? NorthReferenceBearing.trueToMagnetic(
                      widget.azimuthDegrees,
                      widget.magneticDeclinationDegrees,
                    )
                  : widget.azimuthDegrees;
              return StreamBuilder<double>(
                stream: widget.service.cameraPitchStream(),
                builder: (context, pitchSnapshot) {
                  final pitch = pitchSnapshot.data;
                  return CustomPaint(
                    painter: _ArOverlayPainter(
                      targetAzimuth: targetBearing,
                      targetAltitude: widget.altitudeDegrees,
                      heading: heading,
                      pitch: pitch,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          heading == null
                              ? 'Compass unavailable • target ${widget.azimuthDegrees.toStringAsFixed(1)}° true'
                              : 'Heading ${heading.toStringAsFixed(1)}° magnetic • pitch ${pitch?.toStringAsFixed(1) ?? 'unavailable'}°\nTarget ${targetBearing.toStringAsFixed(1)}° ${widget.northReference == NorthReference.magneticNorth ? 'magnetic' : 'true'} / ${widget.altitudeDegrees.toStringAsFixed(1)}° altitude\n${_referenceLabel()}\n${_accuracyLabel(reading!)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (widget.isSun)
            const Align(
              alignment: Alignment.topCenter,
              child: ColoredBox(
                color: Colors.black87,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Never look at the Sun through unfiltered optics.',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _fallback(String message) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );

  String _accuracyLabel(DeviceHeadingReading reading) {
    final accuracy = reading.accuracyDegrees;
    if (accuracy == null) {
      return 'Accuracy unavailable • calibrate and verify with numeric view';
    }
    if (reading.needsCalibration) {
      return 'Low accuracy ±${accuracy.toStringAsFixed(0)}° • move away from metal and calibrate';
    }
    return 'Calibrated ±${accuracy.toStringAsFixed(0)}°';
  }

  String _referenceLabel() =>
      widget.northReference == NorthReference.magneticNorth
      ? 'Declination ${widget.magneticDeclinationDegrees.toStringAsFixed(1)}° east applied'
      : 'True-north target; compare magnetic heading with local declination';
}

final class _ArOverlayPainter extends CustomPainter {
  const _ArOverlayPainter({
    required this.targetAzimuth,
    required this.targetAltitude,
    required this.heading,
    required this.pitch,
  });
  final double targetAzimuth;
  final double targetAltitude;
  final double? heading;
  final double? pitch;
  @override
  void paint(Canvas canvas, Size size) {
    final difference = heading == null
        ? 0.0
        : ((targetAzimuth - heading! + 540) % 360) - 180;
    final x = (size.width / 2 + difference / 60 * size.width).clamp(
      24.0,
      size.width - 24,
    );
    final altitudeDifference = pitch == null
        ? targetAltitude
        : targetAltitude - pitch!;
    final y = (size.height / 2 - altitudeDifference / 60 * size.height).clamp(
      24.0,
      size.height - 24,
    );
    final paint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(x, y), 18, paint);
    canvas.drawLine(Offset(x - 28, y), Offset(x + 28, y), paint);
    canvas.drawLine(Offset(x, y - 28), Offset(x, y + 28), paint);
  }

  @override
  bool shouldRepaint(_ArOverlayPainter old) =>
      old.targetAzimuth != targetAzimuth ||
      old.targetAltitude != targetAltitude ||
      old.heading != heading ||
      old.pitch != pitch;
}
