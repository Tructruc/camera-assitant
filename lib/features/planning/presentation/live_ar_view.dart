import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../data/device_planning_service.dart';

class LiveArView extends StatefulWidget {
  const LiveArView({
    required this.azimuthDegrees,
    required this.altitudeDegrees,
    required this.isSun,
    this.service = const DevicePlanningService(),
    super.key,
  });
  final double azimuthDegrees;
  final double altitudeDegrees;
  final bool isSun;
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
              return CustomPaint(
                painter: _ArOverlayPainter(
                  targetAzimuth: widget.azimuthDegrees,
                  targetAltitude: widget.altitudeDegrees,
                  heading: heading,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black87,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      heading == null
                          ? 'Compass unavailable • target ${widget.azimuthDegrees.toStringAsFixed(1)}° true'
                          : 'Heading ${heading.toStringAsFixed(1)}° magnetic • target ${widget.azimuthDegrees.toStringAsFixed(1)}° true\n${_accuracyLabel(reading!)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
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
}

final class _ArOverlayPainter extends CustomPainter {
  const _ArOverlayPainter({
    required this.targetAzimuth,
    required this.targetAltitude,
    required this.heading,
  });
  final double targetAzimuth;
  final double targetAltitude;
  final double? heading;
  @override
  void paint(Canvas canvas, Size size) {
    final difference = heading == null
        ? 0.0
        : ((targetAzimuth - heading! + 540) % 360) - 180;
    final x = (size.width / 2 + difference / 60 * size.width).clamp(
      24.0,
      size.width - 24,
    );
    final y = (size.height / 2 - targetAltitude / 90 * size.height / 2).clamp(
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
      old.heading != heading;
}
