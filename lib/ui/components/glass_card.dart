// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';

/// A glassmorphism card with frosted glass effect and neon border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurAmount;
  final Color backgroundColor;
  final List<BoxShadow>? extraShadows;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor = const Color(0xFF00FF66),
    this.borderWidth = 1.5,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(16),
    this.blurAmount = 12,
    this.backgroundColor = const Color(0x1A00FF66),
    this.extraShadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: backgroundColor,
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: extraShadows ??
                  [
                    BoxShadow(
                      color: Color.fromRGBO(
                        borderColor.red,
                        borderColor.green,
                        borderColor.blue,
                        0.15,
                      ),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
