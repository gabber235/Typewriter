import "package:typewriter_panel/typewriter_panel.dart";

/// Applies the message transition used by [ElasticMessageSwitcher]: the
/// message drops in from just above on the `loadIn` curve and leaves on the
/// `listOut` curve, fading as it goes.
///
/// The supplied animation is owned by the enclosing switcher. This transition
/// does not alter the child's lifecycle or identity.
class ElasticMessageTransition extends StatelessWidget {
  const ElasticMessageTransition({
    required this.child,
    required this.animation,
    super.key,
  });

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final shaped = CurvedAnimation(
      parent: animation,
      curve: motionTimeline(context, MotionToken.loadIn).curve,
      reverseCurve: motionTimeline(context, MotionToken.listOut).curve.flipped,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(shaped),
        child: child,
      ),
    );
  }
}
