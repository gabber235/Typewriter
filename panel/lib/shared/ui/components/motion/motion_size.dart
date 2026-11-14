import "package:typewriter_panel/typewriter_panel.dart";

/// Follows its [child]'s size: grows with the [grow] token and shrinks with
/// [shrink], or [grow] when none is given. When the token is instant, under
/// reduced motion, the size follows the child at once.
///
/// Every size change goes through it instead of a raw `AnimatedSize`: an
/// `AnimatedSize` with a zero duration finishes its animation inside its
/// own layout and marks itself for layout again, which throws.
class MotionSize extends StatelessWidget {
  const MotionSize({
    required this.child,
    this.grow = MotionToken.surfaceIn,
    this.shrink,
    this.alignment = Alignment.center,
    this.clipBehavior = Clip.hardEdge,
    super.key,
  });

  final Widget child;
  final MotionToken<Landing> grow;
  final MotionToken<Landing>? shrink;
  final AlignmentGeometry alignment;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final growing = motionTimeline(context, grow);
    if (growing.duration == Duration.zero) return child;
    final shrinking = switch (shrink) {
      final token? => motionTimeline(context, token),
      null => growing,
    };
    return AnimatedSize(
      duration: growing.duration,
      reverseDuration: shrinking.duration,
      curve: growing.curve,
      alignment: alignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
