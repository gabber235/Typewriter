import "package:typewriter_panel/typewriter_panel.dart";

/// Applies the standard entrance and exit to [child]: it grows in and fades
/// in on the `loadIn` curve and squashes shut on the `listOut` curve.
///
/// The [Animation] is supplied and owned by the parent transition system. This
/// widget is suitable as an [AnimatedSwitcher.transitionBuilder] result.
class ElasticTransition extends StatelessWidget {
  const ElasticTransition({
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
      child: SizeTransition(
        sizeFactor: shaped,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}
