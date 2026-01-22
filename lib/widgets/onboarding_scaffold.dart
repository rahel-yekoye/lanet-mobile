import 'package:flutter/material.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';

class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final String? title;

  const OnboardingScaffold({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Constrain the onboarding card to a comfortable height so it doesn't
              // stretch edge-to-edge on tall devices. Center it vertically.
              final maxAvail = constraints.maxHeight > 0 ? constraints.maxHeight : double.infinity;
              final cardMaxHeight = maxAvail.isFinite
                  ? (maxAvail * 0.72).clamp(380.0, 740.0)
                  : 520.0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (title != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: cardMaxHeight, maxWidth: 640),
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
