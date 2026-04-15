// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pressing_under_pressure/ui/components/background_beams.dart';
import 'package:pressing_under_pressure/ui/components/neon_text.dart';
import 'package:pressing_under_pressure/ui/components/glass_card.dart';

Color _c(Color c, double o) => Color.fromRGBO(c.red, c.green, c.blue, o);

/// A premium "No Wi-Fi" screen that blocks access to the game
/// until the user connects to Wi-Fi.
class NoInternetScreen extends StatefulWidget {
  final VoidCallback onRetry;
  const NoInternetScreen({super.key, required this.onRetry});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  // Entrance animations
  late AnimationController _entranceController;
  late Animation<double> _iconFade;
  late Animation<double> _titleFade;
  late Animation<double> _bodyFade;
  late Animation<double> _buttonFade;
  late Animation<double> _iconScale;

  // Pulsing wifi icon glow
  late AnimationController _pulseController;
  late Animation<double> _pulse;

  // Rotating signal arcs
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _iconFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _iconScale = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.35, curve: Curves.elasticOut)),
    );
    _titleFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );
    _bodyFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.4, 0.7, curve: Curves.easeOut)),
    );
    _buttonFade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.6, 1.0, curve: Curves.easeOut)),
    );
    _entranceController.forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF2244);

    return Scaffold(
      backgroundColor: const Color(0xFF050000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle red particle background
          const BackgroundBeams(baseColor: Color(0xFF661122)),

          // Dark overlay
          Container(color: _c(Colors.black, 0.55)),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated WiFi-off icon with rotating arcs
                    FadeTransition(
                      opacity: _iconFade,
                      child: ScaleTransition(
                        scale: _iconScale,
                        child: AnimatedBuilder(
                          animation: Listenable.merge([_pulse, _rotateController]),
                          builder: (context, child) {
                            return SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating signal arcs (decorative)
                                  Transform.rotate(
                                    angle: _rotateController.value * 2 * pi,
                                    child: CustomPaint(
                                      size: const Size(130, 130),
                                      painter: _SignalArcsPainter(
                                        color: red,
                                        opacity: _pulse.value * 0.4,
                                      ),
                                    ),
                                  ),
                                  // Outer glow ring
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: _c(red, _pulse.value * 0.4),
                                          blurRadius: 35,
                                          spreadRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Inner icon circle
                                  Container(
                                    width: 90,
                                    height: 90,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _c(red, 0.08),
                                      border: Border.all(
                                        color: _c(red, _pulse.value * 0.6),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _c(red, 0.25),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.wifi_off_rounded,
                                      color: _c(red, 0.9),
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Title
                    FadeTransition(
                      opacity: _titleFade,
                      child: const NeonText(
                        text: 'CONNECTION\nLOST',
                        fontSize: 30,
                        color: red,
                        enableFlicker: true,
                        enableGlitch: true,
                        glowIntensity: 1.2,
                      ),
                    ),

                    const SizedBox(height: 10),

                    FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        '◆ SIGNAL NOT FOUND ◆',
                        style: TextStyle(
                          color: _c(red, 0.5),
                          fontSize: 11,
                          fontFamily: 'Courier',
                          letterSpacing: 4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Message card
                    FadeTransition(
                      opacity: _bodyFade,
                      child: GlassCard(
                        borderColor: _c(red, 0.3),
                        backgroundColor: _c(red, 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              'This game requires a\nCellular or Wi-Fi connection to play.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _c(Colors.white, 0.85),
                                fontSize: 15,
                                fontFamily: 'Courier',
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 1,
                              color: _c(red, 0.15),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_rounded, color: _c(const Color(0xFF00FF66), 0.6), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Enable Cellular or Wi-Fi',
                                  style: TextStyle(
                                    color: _c(const Color(0xFF00FF66), 0.7),
                                    fontSize: 13,
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'to enjoy Pressing Under Pressure',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _c(Colors.white, 0.4),
                                fontSize: 12,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Retry button
                    FadeTransition(
                      opacity: _buttonFade,
                      child: SizedBox(
                        width: 220,
                        child: GlassCard(
                          borderColor: _c(const Color(0xFF00FF66), 0.5),
                          backgroundColor: _c(const Color(0xFF00FF66), 0.08),
                          padding: EdgeInsets.zero,
                          borderRadius: 14,
                          onTap: widget.onRetry,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.refresh_rounded, color: Color(0xFF00FF66), size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'RETRY',
                                  style: TextStyle(
                                    color: Color(0xFF00FF66),
                                    fontFamily: 'Courier',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subtle hint
                    FadeTransition(
                      opacity: _buttonFade,
                      child: Text(
                        'Check your connection and tap Retry',
                        style: TextStyle(
                          color: _c(Colors.white, 0.25),
                          fontSize: 11,
                          fontFamily: 'Courier',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for decorative rotating signal arcs around the WiFi icon.
class _SignalArcsPainter extends CustomPainter {
  final Color color;
  final double opacity;
  _SignalArcsPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw 3 broken arcs at different radii
    for (int i = 0; i < 3; i++) {
      final radius = 45.0 + i * 12.0;
      paint.color = _c(color, opacity * (1.0 - i * 0.25));
      final rect = Rect.fromCircle(center: center, radius: radius);
      // Draw a partial arc
      canvas.drawArc(rect, -pi / 4 + i * 0.4, pi / 3, false, paint);
      canvas.drawArc(rect, pi * 0.7 + i * 0.3, pi / 4, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignalArcsPainter old) =>
      old.opacity != opacity;
}
