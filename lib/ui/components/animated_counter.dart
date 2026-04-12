// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// An animated number counter that scales/bounces on value changes.
class AnimatedCounter extends StatefulWidget {
  final int value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final Color color;
  final double fontSize;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.color = const Color(0xFF00FF66),
    this.fontSize = 16,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _previousValue) {
      _previousValue = widget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Text(
            '${widget.prefix}${widget.value}${widget.suffix}',
            style: widget.style ??
                TextStyle(
                  color: widget.color,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier',
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(
                        widget.color.red,
                        widget.color.green,
                        widget.color.blue,
                        0.7,
                      ),
                      blurRadius: 10,
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }
}
