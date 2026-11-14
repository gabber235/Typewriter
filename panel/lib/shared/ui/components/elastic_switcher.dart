import "package:typewriter_panel/typewriter_panel.dart";

/// Switches keyed content in place: the new content arrives with `loadIn`
/// and the old leaves with `listOut`, while the size follows.
///
/// The child identity controls when a transition starts. The widget owns no
/// application state; reduced motion is applied by the tokens.
class ElasticSwitcher extends StatelessWidget {
  const ElasticSwitcher({required this.child, super.key});

  /// The widget to display. Change its runtime type or key to start a transition.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final arrive = motionTimeline(context, MotionToken.loadIn);
    final leave = motionTimeline(context, MotionToken.listOut);
    final content = AnimatedSwitcher(
      duration: arrive.duration,
      reverseDuration: leave.duration,
      switchInCurve: arrive.curve,
      switchOutCurve: leave.curve.flipped,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child,
    );
    return MotionSize(
      grow: MotionToken.loadIn,
      clipBehavior: Clip.none,
      child: content,
    );
  }
}
