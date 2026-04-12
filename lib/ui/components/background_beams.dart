// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

/// Animated particle background with floating neon particles,
/// subtle grid lines, and configurable color per difficulty.
class BackgroundBeams extends StatefulWidget {
  final Color baseColor;
  final bool intensified;

  const BackgroundBeams({
    super.key,
    this.baseColor = const Color(0xFF00FF66),
    this.intensified = false,
  });

  @override
  State<BackgroundBeams> createState() => _BackgroundBeamsState();
}

class _BackgroundBeamsState extends State<BackgroundBeams>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _particles = List.generate(35, (_) => _Particle.random(_random));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackgroundPainter(
        particles: _particles,
        time: _controller.value,
        baseColor: widget.baseColor,
        intensified: widget.intensified,
      ),
      size: Size.infinite,
    );
  }
}

class _Particle {
  double x, y, radius, speed, opacity, phase;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  factory _Particle.random(Random r) {
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: 1.0 + r.nextDouble() * 3.0,
      speed: 0.2 + r.nextDouble() * 0.6,
      opacity: 0.15 + r.nextDouble() * 0.5,
      phase: r.nextDouble() * 2 * pi,
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final List<_Particle> particles;
  final double time;
  final Color baseColor;
  final bool intensified;

  _BackgroundPainter({
    required this.particles,
    required this.time,
    required this.baseColor,
    required this.intensified,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dark gradient background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF000a00),
          const Color(0xFF001100),
          const Color(0xFF000800),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle grid lines
    final gridPaint = Paint()
      ..color = Color.fromRGBO(
        baseColor.red,
        baseColor.green,
        baseColor.blue,
        intensified ? 0.08 : 0.04,
      )
      ..strokeWidth = 0.5;

    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Horizontal scan line
    final scanY = (time * 3 % 1.0) * size.height;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.0),
          Color.fromRGBO(
            baseColor.red,
            baseColor.green,
            baseColor.blue,
            intensified ? 0.12 : 0.06,
          ),
          Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 2, size.width, 4));
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 2, size.width, 4),
      scanPaint,
    );

    // Floating particles
    for (final p in particles) {
      final t = time * 60; // total seconds
      final px = (p.x * size.width + sin(t * p.speed * 0.1 + p.phase) * 30) %
          size.width;
      final py = (p.y * size.height -
              t * p.speed * 0.8 +
              sin(t * 0.2 + p.phase) * 15) %
          size.height;
      final pulseFactor = 0.7 + 0.3 * sin(t * 2.0 + p.phase);
      final currentOpacity =
          (p.opacity * pulseFactor * (intensified ? 1.5 : 1.0)).clamp(0.0, 1.0);

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        p.radius * 4,
        Paint()
          ..color = Color.fromRGBO(
            baseColor.red,
            baseColor.green,
            baseColor.blue,
            currentOpacity * 0.15,
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Core
      canvas.drawCircle(
        Offset(px, py),
        p.radius,
        Paint()
          ..color = Color.fromRGBO(
            baseColor.red,
            baseColor.green,
            baseColor.blue,
            currentOpacity,
          ),
      );
    }

    // Side beams
    _drawBeam(canvas, size, 0.15, 0.7);
    _drawBeam(canvas, size, 0.85, 0.5);
    if (intensified) {
      _drawBeam(canvas, size, 0.5, 0.9);
    }

    // Vignette
    final vignetteRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0x00000000),
          Color.fromRGBO(0, 0, 0, intensified ? 0.7 : 0.5),
        ],
        stops: const [0.4, 1.0],
      ).createShader(vignetteRect);
    canvas.drawRect(vignetteRect, vignettePaint);
  }

  void _drawBeam(Canvas canvas, Size size, double xFrac, double strength) {
    final x = size.width * xFrac;
    final beamWidth = 80.0;
    final t = time * 60;
    final flicker = 0.5 + 0.5 * sin(t * 0.3 + xFrac * 10);
    final opacity = 0.02 * strength * flicker * (intensified ? 2.0 : 1.0);

    final beamPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.0),
          Color.fromRGBO(
            baseColor.red,
            baseColor.green,
            baseColor.blue,
            opacity.clamp(0.0, 1.0),
          ),
          Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.0),
        ],
      ).createShader(
        Rect.fromLTWH(x - beamWidth / 2, 0, beamWidth, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(x - beamWidth / 2, 0, beamWidth, size.height),
      beamPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}
