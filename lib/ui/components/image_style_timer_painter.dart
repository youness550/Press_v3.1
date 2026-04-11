// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

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

    for (int i = 0; i < totalSegments; i++) {
      double startAngle = (2 * pi / totalSegments) * i - pi / 2;
      double sweepAngle = (2 * pi / totalSegments) - gap;
      bool isActive = (i / totalSegments) < progress;
      Path path = Path();
      path.addArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle);

      canvas.drawPath(
        path,
        Paint()
          ..color = isActive ? activeColor : const Color(0xFF002200)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 35
          ..strokeCap = StrokeCap.butt,
      );

      if (isActive) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Color.fromRGBO(activeColor.red, activeColor.green, activeColor.blue, 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 45
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }
  }

  @override
  bool shouldRepaint(old) => true;
}
