// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

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
        return Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black54,
            boxShadow: [BoxShadow(color: Color.fromRGBO(Colors.green.red, Colors.green.green, Colors.green.blue, 0.04), blurRadius: 8, spreadRadius: 1)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                FractionallySizedBox(
                  widthFactor: v,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF00FFA0), Color(0xFF00FF66)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
