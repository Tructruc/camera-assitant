import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';
import 'package:photography_assistant/features/planning/presentation/live_ar_view.dart';

void main() {
  testWidgets('AR releases and recreates its camera after interruption', (
    tester,
  ) async {
    final originalPlatform = CameraPlatform.instance;
    final cameraPlatform = _FakeCameraPlatform();
    CameraPlatform.instance = cameraPlatform;
    addTearDown(() => CameraPlatform.instance = originalPlatform);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LiveArView(
            azimuthDegrees: 180,
            altitudeDegrees: 30,
            isSun: false,
            service: _SilentDevicePlanningService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(cameraPlatform.createdCameraIds, <int>[1]);
    expect(find.byType(CameraPreview), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(cameraPlatform.disposedCameraIds, <int>[1]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(cameraPlatform.createdCameraIds, <int>[1, 2]);
    expect(find.byType(CameraPreview), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(cameraPlatform.disposedCameraIds, <int>[1, 2]);
  });
}

final class _SilentDevicePlanningService extends DevicePlanningService {
  const _SilentDevicePlanningService();

  @override
  Stream<DeviceHeadingReading> headingStream() => const Stream.empty();

  @override
  Stream<double> cameraPitchStream() => const Stream.empty();
}

final class _FakeCameraPlatform extends CameraPlatform {
  final List<int> createdCameraIds = <int>[];
  final List<int> disposedCameraIds = <int>[];

  @override
  Future<List<CameraDescription>> availableCameras() async => const [
    CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    ),
  ];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async {
    final id = createdCameraIds.length + 1;
    createdCameraIds.add(id);
    return id;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) =>
      Stream<CameraInitializedEvent>.value(
        CameraInitializedEvent(
          cameraId,
          640,
          480,
          ExposureMode.auto,
          true,
          FocusMode.auto,
          true,
        ),
      );

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      Stream<CameraErrorEvent>.value(
        CameraErrorEvent(cameraId, 'synthetic test event'),
      );

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream<DeviceOrientationChangedEvent>.empty();

  @override
  Widget buildPreview(int cameraId) => const ColoredBox(color: Colors.black);

  @override
  Future<void> dispose(int cameraId) async {
    disposedCameraIds.add(cameraId);
  }
}
