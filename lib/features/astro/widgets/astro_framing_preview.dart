import 'dart:math' as math;

import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:flutter/material.dart';

class AstroFramingPreview extends StatelessWidget {
  const AstroFramingPreview({
    super.key,
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
