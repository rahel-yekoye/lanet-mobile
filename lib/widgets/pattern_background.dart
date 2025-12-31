import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PatternBackground extends StatelessWidget {
  final Widget child;
  final bool includeTopPadding;
  final bool includeBottomPadding;

  const PatternBackground({
    Key? key,
    required this.child,
    this.includeTopPadding = true,
    this.includeBottomPadding = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For web, we'll handle padding differently to ensure decorations are visible
    if (kIsWeb) {
      return Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/patterns/page_border.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content with custom padding instead of SafeArea
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: child,
          ),
        ],
      );
    }

    // For mobile, use the original SafeArea implementation
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/images/patterns/page_border.png',
            fit: BoxFit.cover,
          ),
        ),
        // Content
        SafeArea(
          top: includeTopPadding,
          bottom: includeBottomPadding,
          child: child,
        ),
      ],
    );
  }
}