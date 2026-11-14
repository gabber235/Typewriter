import "package:typewriter_panel/typewriter_panel.dart";

/// Paints one animated decoration and publishes its displayed surface.
///
/// Supply the raw fill in [decoration], including its authored opacity. The
/// parent surface is composed each frame, so parent changes do not restart a
/// tween of an already composed color. [foregroundFor] receives that effective
/// displayed background and can keep contrast correct during a transition.
/// An explicit [foreground] interpolates instead. These options are exclusive.
/// With neither option, an explicit fill derives contrast and no fill inherits.
class SurfaceContainer extends HookWidget {
  const SurfaceContainer({
    required this.decoration,
    required this.motion,
    required this.child,
    this.foreground,
    this.foregroundFor,
    this.secondaryForeground,
    this.padding,
    this.width,
    this.height,
    super.key,
  }) : assert(foreground == null || foregroundFor == null);

  final BoxDecoration decoration;

  /// How a changed [decoration], [padding], size or [foreground] moves to its
  /// new value; a change mid move continues from the value on screen.
  final ResolvedMotion<Landing> motion;
  final Color? foreground;
  final Color Function(BuildContext, Color)? foregroundFor;
  final Color? secondaryForeground;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shownDecoration = useMotionValue(
      motion,
      decoration,
      lerp: (a, b, t) => BoxDecoration.lerp(a, b, t)!,
    );
    final shownPadding = useMotionValue(
      motion,
      padding,
      lerp: EdgeInsetsGeometry.lerp,
    );
    final shownWidth = useMotionValue(motion, width, lerp: lerpDouble);
    final shownHeight = useMotionValue(motion, height, lerp: lerpDouble);
    final shownForeground = useMotionValue(
      motion,
      foreground,
      lerp: Color.lerp,
    );
    final fill = shownDecoration.color ?? Colors.transparent;
    final effective = Color.alphaBlend(fill, Surface.colorOf(context));
    return Container(
      decoration: shownDecoration,
      padding: shownPadding,
      width: shownWidth,
      height: shownHeight,
      child: Surface(
        color: fill,
        foreground:
            foregroundFor?.call(context, effective) ??
            shownForeground ??
            (shownDecoration.color == null ? null : effective.on(context)),
        secondaryForeground: secondaryForeground,
        child: child,
      ),
    );
  }
}
