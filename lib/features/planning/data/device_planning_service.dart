import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/planning_capabilities.dart';

final class DeviceLocationReading {
  const DeviceLocationReading({
    required this.latitude,
    required this.longitude,
    required this.elevationMetres,
    required this.accuracyMetres,
  });
  final double latitude;
  final double longitude;
  final double elevationMetres;
  final double accuracyMetres;
}

final class DeviceHeadingReading {
  const DeviceHeadingReading({
    required this.headingDegrees,
    required this.cameraHeadingDegrees,
    required this.accuracyDegrees,
  });
  final double? headingDegrees;
  final double? cameraHeadingDegrees;
  final double? accuracyDegrees;

  bool get needsCalibration => accuracyDegrees == null || accuracyDegrees! > 15;
}

final class DevicePlanningService {
  const DevicePlanningService();
  Future<DeviceLocationReading> requestCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError(
        'Location services are disabled. Enter coordinates manually.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'Location permission was denied. Enter coordinates manually.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return DeviceLocationReading(
      latitude: position.latitude,
      longitude: position.longitude,
      elevationMetres: position.altitude,
      accuracyMetres: position.accuracy,
    );
  }

  Stream<DeviceHeadingReading> headingStream() =>
      FlutterCompass.events?.map(
        (event) => DeviceHeadingReading(
          headingDegrees: event.heading,
          cameraHeadingDegrees: event.headingForCameraMode,
          accuracyDegrees: event.accuracy,
        ),
      ) ??
      const Stream<DeviceHeadingReading>.empty();

  Stream<double> cameraPitchStream() => accelerometerEventStream(
    samplingPeriod: SensorInterval.normalInterval,
  ).map((event) => cameraPitchDegrees(event.x, event.y, event.z));
  Future<CapabilityStatus> locationStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return CapabilityStatus.unsupported;
    }
    return switch (await Geolocator.checkPermission()) {
      LocationPermission.always ||
      LocationPermission.whileInUse => CapabilityStatus.available,
      LocationPermission.deniedForever => CapabilityStatus.denied,
      _ => CapabilityStatus.permissionRequired,
    };
  }

  /// Reports what the live views can offer without triggering a permission
  /// prompt: only the user opening AR may ask for camera or orientation access.
  Future<PlanningCapabilities> detectCapabilities() async {
    try {
      final location = await locationStatus();
      final orientation = FlutterCompass.events == null
          ? CapabilityStatus.unsupported
          : CapabilityStatus.available;
      final camera = await _cameraStatus();
      return PlanningCapabilities(
        location: location,
        orientation: orientation,
        camera: camera,
        augmentedReality:
            camera == CapabilityStatus.available &&
                orientation == CapabilityStatus.available
            ? CapabilityStatus.available
            : CapabilityStatus.unsupported,
      );
    } on Object {
      // Detection must never break a planner; an unknown device falls back to
      // the honest "not yet known" capability set.
      return const PlanningCapabilities.fallback();
    }
  }

  Future<CapabilityStatus> _cameraStatus() async {
    try {
      final cameras = await availableCameras();
      return cameras.isEmpty
          ? CapabilityStatus.unsupported
          : CapabilityStatus.available;
    } on CameraException catch (error) {
      return switch (error.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' => CapabilityStatus.permissionRequired,
        _ => CapabilityStatus.unsupported,
      };
    }
  }
}

double cameraPitchDegrees(double x, double y, double z) =>
    math.atan2(-z, math.sqrt(x * x + y * y)) * 180 / math.pi;
