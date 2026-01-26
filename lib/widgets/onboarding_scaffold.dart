import 'package:flutter/material.dart';
import 'package:lanet_mobile/widgets/pattern_background.dart';
import 'package:lanet_mobile/widgets/onboarding_progress_indicator.dart';

class OnboardingScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final int currentStep;
  final int totalSteps;

  const OnboardingScaffold({
    super.key,
    required this.child,
    this.title,
    this.currentStep = 1,
    this.totalSteps = 4,
  });

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

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Progress indicator at the top
                      OnboardingProgressIndicator(
                        currentStep: currentStep,
                        totalSteps: totalSteps,
                      ),
                      const SizedBox(height: 24),
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 24,
                                  color: Colors.teal.shade700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Main content card
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxHeight: cardMaxHeight, maxWidth: 640),
                          child: Card(
                            elevation: 8,
                            shadowColor: Colors.teal.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.teal.shade50.withOpacity(0.3),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
