// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

/// Enhanced timer painter with glowing segments, gradient fill,
/// danger mode when progress > 80%, and outer glow ring.
class ImageStyleTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  ImageStyleTimerPainter(this.progress, [this.activeColor = const Color(0xFF00FF00)]);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    const totalSegments = 24;
    const gap = 0.06;
    final bool isDanger = progress > 0.8;

    // Outer glow ring
    final glowOpacity = isDanger
        ? (0.2 + 0.2 * sin(DateTime.now().millisecondsSinceEpoch / 80.0))
        : 0.08;
    canvas.drawCircle(
      center,
      radius + 10,
      Paint()
        ..color = Color.fromRGBO(
          activeColor.red,
          activeColor.green,
          activeColor.blue,
          glowOpacity.clamp(0.0, 1.0),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner subtle ring
    canvas.drawCircle(
      center,
      radius - 22,
      Paint()
        ..color = Color.fromRGBO(
          activeColor.red,
          activeColor.green,
          activeColor.blue,
          0.04,
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw segments
    for (int i = 0; i < totalSegments; i++) {
      double startAngle = (2 * pi / totalSegments) * i - pi / 2;
      double sweepAngle = (2 * pi / totalSegments) - gap;
      bool isActive = (i / totalSegments) < progress;

      // Determine segment color with gradient based on position
      Color segmentColor;
      if (isActive) {
        double segmentProgress = i / totalSegments;
        if (isDanger) {
          // Pulsing red in danger mode
          double pulse = 0.7 + 0.3 * sin(DateTime.now().millisecondsSinceEpoch / 100.0 + i * 0.5);
          segmentColor = Color.lerp(
            const Color(0xFFFF4400),
            const Color(0xFFFF0000),
            (segmentProgress * pulse).clamp(0.0, 1.0),
          )!;
        } else {
          // Gradient from bright to slightly dimmer
          double brightness = 1.0 - (segmentProgress * 0.3);
          segmentColor = Color.fromRGBO(
            (activeColor.red * brightness).round().clamp(0, 255),
            (activeColor.green * brightness).round().clamp(0, 255),
            (activeColor.blue * brightness).round().clamp(0, 255),
            1.0,
          );
        }
      } else {
        segmentColor = const Color(0xFF0a1a0a);
      }

      Path path = Path();
      path.addArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle);

      // Base segment
      canvas.drawPath(
        path,
        Paint()
          ..color = segmentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 35
          ..strokeCap = StrokeCap.butt,
      );

      // Glow for active segments
      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.fromRGBO(
              segmentColor.red,
              segmentColor.green,
              segmentColor.blue,
              isDanger ? 0.5 : 0.3,
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 50
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, isDanger ? 14 : 8),
        );
      }

      // Thin bright edge on leading active segment
      if (isActive && i == ((progress * totalSegments).floor()).clamp(0, totalSegments - 1)) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
    }

    // Quarter tick marks
    for (int q = 0; q < 4; q++) {
      double angle = (pi / 2) * q - pi / 2;
      final outerPoint = Offset(
        center.dx + (radius + 14) * cos(angle),
        center.dy + (radius + 14) * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius + 6) * cos(angle),
        center.dy + (radius + 6) * sin(angle),
      );
      canvas.drawLine(
        innerPoint,
        outerPoint,
        Paint()
          ..color = Color.fromRGBO(
            activeColor.red,
            activeColor.green,
            activeColor.blue,
            0.4,
          )
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // Center radial gradient for depth
    final innerGradient = RadialGradient(
      colors: [
        Color.fromRGBO(
          activeColor.red,
          activeColor.green,
          activeColor.blue,
          isDanger ? 0.06 : 0.03,
        ),
        const Color(0x00000000),
      ],
      stops: const [0.0, 1.0],
    );
    canvas.drawCircle(
      center,
      radius - 22,
      Paint()
        ..shader = innerGradient.createShader(
          Rect.fromCircle(center: center, radius: radius - 22),
        ),
    );
  }

  @override
  bool shouldRepaint(old) => true;
}
