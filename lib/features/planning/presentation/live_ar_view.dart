import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/data/repositories/preferences_repository.dart';
import '../data/device_planning_service.dart';
import '../domain/north_reference.dart';

/// The camera plugin exposes no lens field of view, so reticle placement
/// assumes this value on both axes and states the assumption on screen.
const double arAssumedFieldOfViewDegrees = 60;

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

class _LiveArViewState extends State<LiveArView> with WidgetsBindingObserver {
  CameraController? _controller;
  Object? _error;
  var _initializationGeneration = 0;
  var _isForeground = true;
  var _showDiagnostics = false;
  Future<void> _pendingDisposal = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    final generation = ++_initializationGeneration;
    if (!_isForeground) return;
    if (mounted) setState(() => _error = null);
    CameraController? initializingController;
    try {
      await _pendingDisposal;
      if (!_isCurrentInitialization(generation)) return;
      final cameras = await availableCameras();
      if (!_isCurrentInitialization(generation)) return;
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
      initializingController = controller;
      await controller.initialize();
      if (!_isCurrentInitialization(generation)) {
        await _disposeCameraController(controller);
        return;
      }
      setState(() => _controller = controller);
      initializingController = null;
    } on Object catch (error) {
      if (initializingController != null) {
        await _disposeCameraController(initializingController);
      }
      if (_isCurrentInitialization(generation)) {
        setState(() => _error = error);
      }
    }
  }

  bool _isCurrentInitialization(int generation) =>
      mounted && _isForeground && generation == _initializationGeneration;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      _initialize();
      return;
    }
    _isForeground = false;
    _suspendCamera();
  }

  void _suspendCamera() {
    _initializationGeneration += 1;
    final controller = _controller;
    if (controller == null) return;
    if (mounted) setState(() => _controller = null);
    _pendingDisposal = _disposeCameraController(controller);
  }

  Future<void> _disposeCameraController(CameraController controller) async {
    try {
      await controller.dispose();
    } on Object {
      // Disposal is best-effort during lifecycle transitions. Initialization
      // still gets a fresh controller and reports any failure in the view.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isForeground = false;
    _initializationGeneration += 1;
    final controller = _controller;
    if (controller != null) {
      unawaited(_disposeCameraController(controller));
    }
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
              final declinationValid = NorthReferenceBearing.validDeclination(
                widget.magneticDeclinationDegrees,
              );
              final magneticTarget = declinationValid
                  ? NorthReferenceBearing.trueToMagnetic(
                      widget.azimuthDegrees,
                      widget.magneticDeclinationDegrees,
                    )
                  : null;
              final displayedTarget =
                  widget.northReference == NorthReference.magneticNorth
                  ? magneticTarget
                  : widget.azimuthDegrees;
              return StreamBuilder<double>(
                stream: widget.service.cameraPitchStream(),
                builder: (context, pitchSnapshot) {
                  final pitch = pitchSnapshot.data;
                  final delta = declinationValid && heading != null
                      ? NorthReferenceBearing.deviceHeadingDelta(
                          trueTargetDegrees: widget.azimuthDegrees,
                          magneticHeadingDegrees: heading,
                          declinationDegrees: widget.magneticDeclinationDegrees,
                        )
                      : null;
                  final headline = !declinationValid
                      ? 'Declination invalid · reticle hidden'
                      : heading == null
                      ? 'Compass unavailable'
                      : delta!.abs() < 0.5
                      ? 'On target'
                      : 'Turn ${delta.abs().toStringAsFixed(1)}° '
                            '${delta < 0 ? 'left' : 'right'}';
                  final reference =
                      widget.northReference == NorthReference.magneticNorth
                      ? 'magnetic'
                      : 'true';
                  final subline = displayedTarget == null
                      ? 'Target ${widget.azimuthDegrees.toStringAsFixed(1)}° true '
                            '· alt ${widget.altitudeDegrees.toStringAsFixed(1)}°'
                      : 'Target ${displayedTarget.toStringAsFixed(1)}° '
                            '$reference · alt '
                            '${widget.altitudeDegrees.toStringAsFixed(1)}°';
                  return CustomPaint(
                    painter: _ArOverlayPainter(
                      targetAzimuth: magneticTarget ?? widget.azimuthDegrees,
                      targetAltitude: widget.altitudeDegrees,
                      heading: declinationValid ? heading : null,
                      pitch: pitch,
                    ),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: ColoredBox(
                        color: Colors.black87,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Expanded(
                                // Scrollable so a long diagnostics expansion can
                                // never overflow the live view it annotates.
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Semantics(
                                        label: '$headline. $subline',
                                        excludeSemantics: true,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              headline,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              subline,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_showDiagnostics) ...<Widget>[
                                        const SizedBox(height: 6),
                                        for (final line in _diagnostics(
                                          reading: reading,
                                          heading: heading,
                                          pitch: pitch,
                                        ))
                                          Text(
                                            line,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: _showDiagnostics
                                    ? 'Hide AR diagnostics'
                                    : 'Show AR diagnostics',
                                onPressed: () => setState(
                                  () => _showDiagnostics = !_showDiagnostics,
                                ),
                                icon: Icon(
                                  _showDiagnostics
                                      ? Icons.expand_more
                                      : Icons.info_outline,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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

  /// Readings, assumptions and fallbacks behind the one-line aiming readout.
  ///
  /// Kept behind an explicit toggle: the live picture is what the user aims
  /// with, and a wall of text over it hides the composition it describes.
  List<String> _diagnostics({
    required DeviceHeadingReading? reading,
    required double? heading,
    required double? pitch,
  }) => <String>[
    if (!NorthReferenceBearing.validDeclination(
      widget.magneticDeclinationDegrees,
    ))
      'Declination is invalid. Enter a value from 90° west to 90° east; the reticle is hidden.',
    heading == null
        ? 'Heading unavailable · pitch ${pitch?.toStringAsFixed(1) ?? 'unavailable'}°'
        : 'Heading ${heading.toStringAsFixed(1)}° magnetic · pitch ${pitch?.toStringAsFixed(1) ?? 'unavailable'}°',
    if (heading == null)
      'Use the compass and numeric views; no heading is fabricated.',
    _referenceLabel(),
    reading == null ? 'Accuracy unavailable' : _accuracyLabel(reading),
    'Overlay assumes a ${arAssumedFieldOfViewDegrees.toStringAsFixed(0)}° field of view on both axes; confirm framing in the live view.',
  ];

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
    if (heading == null) return;
    final difference = ((targetAzimuth - heading! + 540) % 360) - 180;
    final x =
        (size.width / 2 + difference / arAssumedFieldOfViewDegrees * size.width)
            .clamp(24.0, size.width - 24);
    final altitudeDifference = pitch == null
        ? targetAltitude
        : targetAltitude - pitch!;
    final y =
        (size.height / 2 -
                altitudeDifference / arAssumedFieldOfViewDegrees * size.height)
            .clamp(24.0, size.height - 24);
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
