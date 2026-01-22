// lib/widgets/auth_scaffold.dart
import 'package:flutter/material.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final String? heroTag;
  final Widget? bottomImage;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.heroTag,
    this.bottomImage,
  });

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),

                // SMALL GAP (boy sits right under card)
                const SizedBox(height: 8),

                // Bottom image — trimmed & safe
                if (bottomImage != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IgnorePointer(
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.65, // 🔴 trims transparent top space
                          child: SizedBox(
                            height: 300, // Increased height to 1.5x the previous size
                            child: bottomImage!,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
