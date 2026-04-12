// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';

/// A glowing, flickering neon text widget with configurable color and intensity.
/// Supports optional glitch effect for a hacker aesthetic.
class NeonText extends StatefulWidget {
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final bool enableFlicker;
  final bool enableGlitch;
  final TextAlign textAlign;
  final double glowIntensity;

  const NeonText({
    super.key,
    required this.text,
    this.fontSize = 24,
    this.color = const Color(0xFF00FF66),
    this.fontWeight = FontWeight.bold,
    this.enableFlicker = true,
    this.enableGlitch = false,
    this.textAlign = TextAlign.center,
    this.glowIntensity = 1.0,
  });

  @override
  State<NeonText> createState() => _NeonTextState();
}

class _NeonTextState extends State<NeonText> with TickerProviderStateMixin {
  late AnimationController _flickerController;
  late AnimationController _glitchController;
  final Random _random = Random();
  double _glitchOffsetX = 0;
  double _glitchOffsetY = 0;
  bool _showGlitchSlice = false;

  @override
  void initState() {
    super.initState();
    _flickerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    if (widget.enableFlicker) {
      _startRandomFlicker();
    }

    _glitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    );
    if (widget.enableGlitch) {
      _startGlitchLoop();
    }
  }

  void _startRandomFlicker() {
    Future.delayed(Duration(milliseconds: 1500 + _random.nextInt(3000)), () {
      if (!mounted) return;
      _flickerController.forward().then((_) {
        if (!mounted) return;
        _flickerController.reverse().then((_) {
          if (!mounted) return;
          // Double flicker sometimes
          if (_random.nextBool()) {
            Future.delayed(const Duration(milliseconds: 80), () {
              if (!mounted) return;
              _flickerController.forward().then((_) {
                if (!mounted) return;
                _flickerController.reverse();
              });
            });
          }
          _startRandomFlicker();
        });
      });
    });
  }

  void _startGlitchLoop() {
    Future.delayed(Duration(milliseconds: 2000 + _random.nextInt(4000)), () {
      if (!mounted) return;
      setState(() {
        _glitchOffsetX = (_random.nextDouble() - 0.5) * 8;
        _glitchOffsetY = (_random.nextDouble() - 0.5) * 3;
        _showGlitchSlice = true;
      });
      Future.delayed(const Duration(milliseconds: 80), () {
        if (!mounted) return;
        setState(() {
          _glitchOffsetX = 0;
          _glitchOffsetY = 0;
          _showGlitchSlice = false;
        });
        _startGlitchLoop();
      });
    });
  }

  @override
  void dispose() {
    _flickerController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flickerController,
      builder: (context, child) {
        final double flickerOpacity = widget.enableFlicker
            ? (1.0 - _flickerController.value * 0.3)
            : 1.0;

        final textStyle = TextStyle(
          fontSize: widget.fontSize,
          fontWeight: widget.fontWeight,
          color: widget.color,
          letterSpacing: widget.fontSize > 20 ? 4 : 2,
          fontFamily: 'Courier',
          shadows: [
            Shadow(
              color: Color.fromRGBO(
                widget.color.red,
                widget.color.green,
                widget.color.blue,
                0.9 * widget.glowIntensity,
              ),
              blurRadius: 12 * widget.glowIntensity,
            ),
            Shadow(
              color: Color.fromRGBO(
                widget.color.red,
                widget.color.green,
                widget.color.blue,
                0.5 * widget.glowIntensity,
              ),
              blurRadius: 30 * widget.glowIntensity,
            ),
            Shadow(
              color: Color.fromRGBO(
                widget.color.red,
                widget.color.green,
                widget.color.blue,
                0.25 * widget.glowIntensity,
              ),
              blurRadius: 60 * widget.glowIntensity,
            ),
          ],
        );

        return Opacity(
          opacity: flickerOpacity,
          child: Transform.translate(
            offset: Offset(_glitchOffsetX, _glitchOffsetY),
            child: Stack(
              children: [
                Text(
                  widget.text,
                  textAlign: widget.textAlign,
                  style: textStyle,
                ),
                // Glitch RGB split effect
                if (_showGlitchSlice && widget.enableGlitch) ...[
                  Transform.translate(
                    offset: const Offset(2, 0),
                    child: Text(
                      widget.text,
                      textAlign: widget.textAlign,
                      style: textStyle.copyWith(
                        color: Color.fromRGBO(255, 0, 0, 0.5),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-2, 0),
                    child: Text(
                      widget.text,
                      textAlign: widget.textAlign,
                      style: textStyle.copyWith(
                        color: Color.fromRGBO(0, 255, 255, 0.3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
