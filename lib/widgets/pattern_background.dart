import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class PatternBackground extends StatelessWidget {
  final Widget child;
  final bool includeTopPadding;
  final bool includeBottomPadding;
  final Color? backgroundColor;
  final String? backgroundImagePath;

  const PatternBackground({
    super.key,
    required this.child,
    this.includeTopPadding = true,
    this.includeBottomPadding = true,
    this.backgroundColor = const Color(0xFFFEDB88),
    this.backgroundImagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBackgroundColor = theme.scaffoldBackgroundColor;

    Widget backgroundContent;
    if (backgroundImagePath != null) {
      // Layer transparent image on top of solid background color
      backgroundContent = Stack(
        children: [
          // Solid background color
          Container(
            color: backgroundColor ?? defaultBackgroundColor,
          ),
          // Transparent image layered on top
          Image.asset(
            backgroundImagePath!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ],
      );
    } else {
      // Use solid color as background
      backgroundContent = Container(
        color: backgroundColor ?? defaultBackgroundColor,
      );
    }

    Widget content = child;

    // Apply safe area if needed
    if (includeTopPadding || includeBottomPadding) {
      content = SafeArea(
        top: includeTopPadding,
        bottom: includeBottomPadding,
        child: content,
      );
    }

    // For web, we might want to handle scrolling differently
    if (kIsWeb) {
      return Stack(
        children: [
          Positioned.fill(child: backgroundContent),
          // Add some padding for web to account for browser chrome
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: content,
          ),
        ],
      );
    }

    // For mobile, use the standard approach
    return Stack(
      children: [
        Positioned.fill(child: backgroundContent),
        content,
      ],
    );
  }
}