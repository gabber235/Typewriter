import "package:typewriter_panel/typewriter_panel.dart";

/// Switches keyed messages: the new message arrives with `loadIn`, the old
/// leaves with `listOut`, and the size follows.
///
/// The child identity controls when a message changes. This widget owns only
/// presentation and does not retain message or loading state.
class ElasticMessageSwitcher extends StatelessWidget {
  const ElasticMessageSwitcher({required this.child, super.key});

  /// Message to display. Use a distinct key to animate between messages.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final arrive = motionTimeline(context, MotionToken.loadIn);
    final leave = motionTimeline(context, MotionToken.listOut);
    final content = AnimatedSwitcher(
      duration: arrive.duration,
      reverseDuration: leave.duration,
      transitionBuilder: (child, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) => ExcludeInteraction(
            excluding:
                animation.status == AnimationStatus.reverse ||
                animation.status == AnimationStatus.dismissed,
            child: child!,
          ),
          child: ElasticMessageTransition(animation: animation, child: child),
        );
      },
      child: child,
    );
    // A zero length size change would land inside layout.
    if (arrive.duration == Duration.zero) return content;
    return AnimatedSize(
      duration: arrive.duration,
      alignment: Alignment.topCenter,
      curve: arrive.curve,
      child: content,
    );
  }
}
