import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBG extends StatefulWidget {
  final Widget child;
  const AnimatedBG({super.key, required this.child});

  @override
  State<AnimatedBG> createState() => _AnimatedBGState();
}

class _AnimatedBGState extends State<AnimatedBG>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat(reverse: true);
  }

@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: _controller,
    builder: (_, __) {
      return Container(
        color:  Colors.grey, // <-- soft pastel purple
        child: Stack(
          children: [
            Positioned(
              top: 50 + sin(_controller.value * 2 * pi) * 20,
              left: 60,
              child: _blob(120, Colors.purple.shade100),
            ),
            Positioned(
              bottom: 80 + cos(_controller.value * 2 * pi) * 20,
              right: 40,
              child: _blob(150, Colors.blue.shade100),
            ),
            widget.child,
          ],
        ),
      );
    },
  );
}


  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(200),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 60, // correct usage
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
