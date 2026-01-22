import 'dart:ui';
import 'package:flutter/material.dart';

class ChoiceCard extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color? backgroundColor;

  const ChoiceCard({
    super.key,
    required this.label,
    required this.onTap,
    this.backgroundColor,
  });

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard>
    with SingleTickerProviderStateMixin {
  double scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => scale = 0.97),
      onTapUp: (_) => setState(() => scale = 1),
      onTapCancel: () => setState(() => scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
