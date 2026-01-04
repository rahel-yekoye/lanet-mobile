import 'package:flutter/material.dart';

class CulturalScaffold extends StatelessWidget {
  final Widget body;
  final String? headerImage; // Optional illustration at the top (e.g., market_scene.png)
  final bool showTopBorder;
  final bool showBottomBorder;

  const CulturalScaffold({
    super.key,
    required this.body,
    this.headerImage,
    this.showTopBorder = true,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6), // Warm beige background
      body: SafeArea(
        child: Column(
          children: [
            // Top Border
            if (showTopBorder)
              Image.asset(
                'assets/images/patterns/page_border.png',
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),

            // Optional Header Illustration (like market, village, etc.)
            if (headerImage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Image.asset(
                    'assets/images/illustrations/$headerImage',
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

            // Main Content
            Expanded(child: body),

            // Bottom Border (flipped vertically to match traditional design symmetry)
            if (showBottomBorder)
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationX(3.14159), // 180° flip
                child: Image.asset(
                  'assets/images/patterns/page_border.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                ),
              ),
          ],
        ),
      ),
    );
  }
}