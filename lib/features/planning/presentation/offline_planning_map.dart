import 'dart:math' as math;

import 'package:flutter/material.dart';

final class PlanningMapMarker {
  const PlanningMapMarker({
    required this.bearingDegrees,
    required this.altitudeDegrees,
    required this.label,
    this.isPrimary = false,
  });

  final double bearingDegrees;
  final double altitudeDegrees;
  final String label;
  final bool isPrimary;
}

class OfflinePlanningMap extends StatelessWidget {
  const OfflinePlanningMap({
    required this.desiredBearingDegrees,
    required this.observerLabel,
    required this.markers,
    super.key,
  });

  final double desiredBearingDegrees;
  final String observerLabel;
  final List<PlanningMapMarker> markers;

  @override
  Widget build(BuildContext context) {
    final semantics = StringBuffer(
      'Offline spatial schematic. Desired bearing '
      '${desiredBearingDegrees.toStringAsFixed(1)} degrees true.',
    );
    for (final marker in markers) {
      semantics.write(
        ' ${marker.label} at ${marker.bearingDegrees.toStringAsFixed(1)} '
        'degrees bearing and ${marker.altitudeDegrees.toStringAsFixed(1)} '
        'degrees altitude.',
      );
    }
    return Semantics(
      container: true,
      label: semantics.toString(),
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offline spatial schematic',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(observerLabel),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: CustomPaint(
                    painter: _PlanningMapPainter(
                      desiredBearingDegrees: desiredBearingDegrees,
                      markers: markers,
                      lineColor: Theme.of(context).colorScheme.primary,
                      markerColor: Theme.of(context).colorScheme.tertiary,
                      gridColor: Theme.of(context).colorScheme.outlineVariant,
                      textColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sight line ${desiredBearingDegrees.toStringAsFixed(1)}° true',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (markers.isEmpty)
                  const Text('No target positions in this plan.')
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final marker in markers.take(8))
                        Chip(
                          avatar: Icon(
                            marker.isPrimary ? Icons.my_location : Icons.circle,
                            size: 14,
                          ),
                          label: Text(
                            '${marker.label}: ${marker.bearingDegrees.toStringAsFixed(0)}° az · ${marker.altitudeDegrees.toStringAsFixed(0)}° alt',
                          ),
                        ),
                    ],
                  ),
                const Text(
                  'No terrain or map tiles are included. Verify obstacles and the horizon on site.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanningMapPainter extends CustomPainter {
  const _PlanningMapPainter({
    required this.desiredBearingDegrees,
    required this.markers,
    required this.lineColor,
    required this.markerColor,
    required this.gridColor,
    required this.textColor,
  });

  final double desiredBearingDegrees;
  final List<PlanningMapMarker> markers;
  final Color lineColor;
  final Color markerColor;
  final Color gridColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final grid = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, grid);
    canvas.drawCircle(center, radius * .5, grid);
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      grid,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      grid,
    );
    _drawLabel(canvas, 'N', Offset(center.dx, center.dy - radius - 14));
    _drawLabel(canvas, 'E', Offset(center.dx + radius + 10, center.dy));
    _drawLabel(canvas, 'S', Offset(center.dx, center.dy + radius + 14));
    _drawLabel(canvas, 'W', Offset(center.dx - radius - 10, center.dy));

    final bearingRadians = (desiredBearingDegrees - 90) * math.pi / 180;
    final sightLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final endpoint =
        center +
        Offset(
          math.cos(bearingRadians) * radius,
          math.sin(bearingRadians) * radius,
        );
    canvas.drawLine(center, endpoint, sightLine);
    canvas.drawCircle(center, 6, Paint()..color = lineColor);

    for (final marker in markers) {
      final angle = (marker.bearingDegrees - 90) * math.pi / 180;
      final altitude = marker.altitudeDegrees.clamp(-10.0, 90.0);
      final distance = radius * (1 - ((altitude + 10) / 120)).clamp(.18, .92);
      final position =
          center +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      canvas.drawCircle(
        position,
        marker.isPrimary ? 8 : 5,
        Paint()..color = marker.isPrimary ? lineColor : markerColor,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PlanningMapPainter oldDelegate) =>
      desiredBearingDegrees != oldDelegate.desiredBearingDegrees ||
      markers != oldDelegate.markers ||
      lineColor != oldDelegate.lineColor ||
      markerColor != oldDelegate.markerColor ||
      gridColor != oldDelegate.gridColor ||
      textColor != oldDelegate.textColor;
}
