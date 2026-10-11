import "package:typewriter_panel/typewriter_panel.dart";

/// Switches keyed content with the panel's standard elastic size and scale
/// transition.
///
/// The child identity controls when a transition starts. Timing is intentionally
/// fixed so loading and status changes share one motion treatment. The widget
/// owns no application state.
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
