import "package:typewriter_panel/typewriter_panel.dart";

/// Swaps [child] the way a popover comes and goes: the new one grows from
/// panelIn's start scale at [alignment] while it fades in, the old one goes
/// back with panelOut.
class PanelSwitcher extends StatelessWidget {
  const PanelSwitcher({
    required this.child,
    this.alignment = Alignment.center,
    super.key,
  });

  final Widget? child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final arrive = motionTimeline(context, MotionToken.panelIn);
    final leave = motionTimeline(context, MotionToken.panelOut);
    final origin = context.motion.spec(MotionToken.panelIn).landing.originScale;
    return AnimatedSwitcher(
      duration: arrive.duration,
      reverseDuration: leave.duration,
      transitionBuilder: (child, animation) {
        final travel = CurvedAnimation(
          parent: animation,
          curve: arrive.curve,
          reverseCurve: leave.curve.flipped,
        );
        return AnimatedBuilder(
          animation: travel,
          child: child,
          builder: (context, child) => Opacity(
            opacity: travel.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: lerpDouble(origin, 1, travel.value),
              alignment: alignment,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
