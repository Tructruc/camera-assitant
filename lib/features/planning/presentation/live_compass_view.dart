import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/data/repositories/preferences_repository.dart';
import '../data/device_planning_service.dart';
import '../domain/north_reference.dart';

class LiveCompassView extends StatelessWidget {
  const LiveCompassView({
    required this.trueBearingDegrees,
    required this.magneticDeclinationDegrees,
    required this.northReference,
    this.headingReadings,
    this.service = const DevicePlanningService(),
    super.key,
  });

  final double trueBearingDegrees;
  final double magneticDeclinationDegrees;
  final NorthReference northReference;
  final Stream<DeviceHeadingReading>? headingReadings;
  final DevicePlanningService service;

  @override
  Widget build(BuildContext context) {
    if (!NorthReferenceBearing.validDeclination(magneticDeclinationDegrees)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Magnetic declination is invalid. Enter a value from 90° west to 90° east before using live compass guidance.',
          ),
        ),
      );
    }
    final magneticTarget = NorthReferenceBearing.trueToMagnetic(
      trueBearingDegrees,
      magneticDeclinationDegrees,
    );
    final targetLabel = northReference == NorthReference.magneticNorth
        ? '${magneticTarget.toStringAsFixed(1)}° magnetic'
        : '${trueBearingDegrees.toStringAsFixed(1)}° true';
    return StreamBuilder<DeviceHeadingReading>(
      stream: headingReadings ?? service.headingStream(),
      builder: (context, snapshot) {
        final reading = snapshot.data;
        final heading =
            reading?.cameraHeadingDegrees ?? reading?.headingDegrees;
        if (heading == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live heading unavailable',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Target $targetLabel (${trueBearingDegrees.toStringAsFixed(1)}° true / ${magneticTarget.toStringAsFixed(1)}° magnetic). Use the numeric and map views; no heading is fabricated.',
                  ),
                ],
              ),
            ),
          );
        }
        final delta = NorthReferenceBearing.deviceHeadingDelta(
          trueTargetDegrees: trueBearingDegrees,
          magneticHeadingDegrees: heading,
          declinationDegrees: magneticDeclinationDegrees,
        );
        final direction = delta.abs() < 0.5
            ? 'on target'
            : '${delta.abs().toStringAsFixed(1)}° ${delta < 0 ? 'left' : 'right'}';
        return Semantics(
          container: true,
          label:
              'Live compass. Heading ${heading.toStringAsFixed(1)} degrees magnetic. Target $targetLabel. Turn $direction.',
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const _CompassRose(),
                        Transform.rotate(
                          angle: delta * math.pi / 180,
                          child: Icon(
                            Icons.navigation,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text('Heading ${heading.toStringAsFixed(1)}° magnetic'),
                  Text('Target $targetLabel · turn $direction'),
                  Text(
                    '${trueBearingDegrees.toStringAsFixed(1)}° true / ${magneticTarget.toStringAsFixed(1)}° magnetic · declination ${magneticDeclinationDegrees.toStringAsFixed(1)}° east',
                    textAlign: TextAlign.center,
                  ),
                  Text(_accuracyLabel(reading!)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _accuracyLabel(DeviceHeadingReading reading) {
    final accuracy = reading.accuracyDegrees;
    if (accuracy == null) {
      return 'Accuracy unavailable · calibrate and verify with numeric view';
    }
    return reading.needsCalibration
        ? 'Low accuracy ±${accuracy.toStringAsFixed(0)}° · move away from metal and calibrate'
        : 'Calibrated ±${accuracy.toStringAsFixed(0)}°';
  }
}

class _CompassRose extends StatelessWidget {
  const _CompassRose();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline,
        width: 2,
      ),
    ),
    child: const Stack(
      children: [
        Align(alignment: Alignment.topCenter, child: Text('N')),
        Align(alignment: Alignment.centerRight, child: Text('E')),
        Align(alignment: Alignment.bottomCenter, child: Text('S')),
        Align(alignment: Alignment.centerLeft, child: Text('W')),
      ],
    ),
  );
}
