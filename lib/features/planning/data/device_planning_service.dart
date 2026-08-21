import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

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
}
