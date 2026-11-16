import "package:typewriter_panel/typewriter_panel.dart";

/// Lifts [child] while [raised]: up by the landing's rise and to its
/// scale with [token], and back down with `hoverOut`. With [progress] the
/// caller drives the lift and [raised] is ignored.
///
/// Under reduced motion nothing travels. A control passes [stillFill] to
/// show the state as its soft fill; a row passes none, since a row fill
/// means selected.
class Rise extends HookWidget {
  const Rise({
    required this.child,
    this.raised = false,
    this.progress,
    this.token = MotionToken.hoverIn,
    this.stillFill,
    this.borderRadius,
    super.key,
  });

  final Widget child;
  final bool raised;
  final Animation<double>? progress;
  final MotionToken<RiseLanding> token;
  final Color? stillFill;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final up = resolveMotion(context, token);
    final down = resolveMotion(context, MotionToken.hoverOut);
    final own = useMotionController(initial: raised ? 1 : 0);
    useEffect(() {
      if (progress == null) own.to(raised ? 1 : 0, raised ? up : down);
      return null;
    }, [raised, progress == null]);
    final lift = progress ?? own;

    if (up.still) {
      final fill = stillFill;
      final shown = progress == null ? raised : progress!.value > 0;
      if (!shown || fill == null) return child;
      return DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: borderRadius),
        child: child,
      );
    }
    final landing = up.landing;
    return AnimatedBuilder(
      animation: lift,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -landing.rise * lift.value),
        child: Transform.scale(
          scale: 1 + (landing.scale - 1) * lift.value,
          child: child,
        ),
      ),
    );
  }
}
