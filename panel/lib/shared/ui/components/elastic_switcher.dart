import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

/// A generic switcher with elastic size and scale animations.
///
/// This encapsulates the exact timings and curves tuned for smooth, playful
/// transitions used across the app (e.g., loading content swaps).
///
/// The animations are intentionally not configurable to keep transitions
/// consistent everywhere.
class ElasticSwitcher extends StatelessWidget {
  const ElasticSwitcher({required this.child, super.key});

  /// The widget to display. Provide a new child (with a differing identity or
  /// key) to trigger the transition to it.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final disableAnimation = MediaQuery.disableAnimationsOf(context);
    final sizeDuraiton = disableAnimation ? Duration.zero : 1000.ms;
    final scaleDuration = disableAnimation ? Duration.zero : 800.ms;

    return AnimatedSize(
      duration: sizeDuraiton,
      curve: const ElasticOutCurve(0.9),
      clipBehavior: Clip.none,
      child: AnimatedSwitcher(
        duration: scaleDuration,
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.2, 1.0, curve: ElasticOutCurve(0.7)),
              reverseCurve: const Interval(
                0.8,
                1.0,
                curve: Curves.fastLinearToSlowEaseIn,
              ),
            ),
            child: child,
          );
        },
        child: child,
      ),
    );
  }
}
