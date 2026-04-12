// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// Enhanced loading bar with scan-line effect, neon glow edge,
/// segmented fill, and terminal-style percentage overlay.
class LoadingBar extends StatelessWidget {
  final Animation<double> animation;
  final double width;
  const LoadingBar({super.key, required this.animation, required this.width});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double v = animation.value.clamp(0.0, 1.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Terminal text above bar
            SizedBox(
              width: width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INITIALIZING SYSTEM...',
                    style: TextStyle(
                      color: Color.fromRGBO(0, 255, 102, 0.7),
                      fontSize: 10,
                      fontFamily: 'Courier',
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    '${(v * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Color.fromRGBO(0, 255, 102, 0.9),
                      fontSize: 11,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Color.fromRGBO(0, 255, 102, 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Segmented bar
            Container(
              width: width,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFF0a1a0a),
                border: Border.all(
                  color: Color.fromRGBO(0, 255, 102, 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 255, 102, 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CustomPaint(
                  painter: _SegmentedBarPainter(v),
                  size: Size(width, 18),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SegmentedBarPainter extends CustomPainter {
  final double progress;
  _SegmentedBarPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const int segments = 30;
    const double segGap = 2.0;
    final double segWidth = (size.width - (segments - 1) * segGap) / segments;

    for (int i = 0; i < segments; i++) {
      final double segStart = i * (segWidth + segGap);
      final double segProgress = i / segments;
      final bool isActive = segProgress < progress;

      if (isActive) {
        // Gradient from bright to slightly dimmer
        final double brightness = 1.0 - (segProgress * 0.2);
        final Color segColor = Color.fromRGBO(
          (0 * brightness).round(),
          (255 * brightness).round().clamp(0, 255),
          (102 * brightness).round().clamp(0, 255),
          1.0,
        );

        // Glow behind active segment
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(segStart - 1, -1, segWidth + 2, size.height + 2),
            const Radius.circular(1),
          ),
          Paint()
            ..color = Color.fromRGBO(0, 255, 102, 0.2)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );

        // Active segment
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(segStart, 1, segWidth, size.height - 2),
            const Radius.circular(1),
          ),
          Paint()..color = segColor,
        );

        // Bright top edge
        canvas.drawLine(
          Offset(segStart, 2),
          Offset(segStart + segWidth, 2),
          Paint()
            ..color = Color.fromRGBO(200, 255, 200, 0.6)
            ..strokeWidth = 1,
        );
      } else {
        // Inactive segment
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(segStart, 1, segWidth, size.height - 2),
            const Radius.circular(1),
          ),
          Paint()..color = const Color(0xFF0d200d),
        );
      }
    }

    // Scan-line sweep effect
    final scanX = (progress > 0) ? progress * size.width : 0.0;
    if (scanX > 0) {
      final scanGradient = LinearGradient(
        colors: [
          Color.fromRGBO(255, 255, 255, 0.0),
          Color.fromRGBO(255, 255, 255, 0.25),
          Color.fromRGBO(255, 255, 255, 0.0),
        ],
      );
      final scanWidth = 20.0;
      canvas.drawRect(
        Rect.fromLTWH(
          (scanX - scanWidth / 2).clamp(0, size.width),
          0,
          scanWidth,
          size.height,
        ),
        Paint()
          ..shader = scanGradient.createShader(
            Rect.fromLTWH(scanX - scanWidth / 2, 0, scanWidth, size.height),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedBarPainter old) =>
      old.progress != progress;
}
