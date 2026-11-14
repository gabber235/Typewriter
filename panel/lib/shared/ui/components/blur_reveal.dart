import "package:typewriter_panel/typewriter_panel.dart";

/// Reveals a child on pointer hover: its blur clears with `hoverIn` and
/// returns with `hoverOut`.
///
/// This is pointer driven presentation only. It does not change semantics or
/// provide an alternate reveal mechanism for keyboard and touch users.
class BlurReveal extends HookWidget {
  /// Creates a [BlurReveal] widget.
  ///
  /// The [child] parameter is required and specifies the widget to display.
  /// [blurSigma] controls the intensity of the blur effect (default: 6.0).
  const BlurReveal({required this.child, this.blurSigma = 6.0, super.key});

  final Widget child;

  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final token = isHovered.value ? MotionToken.hoverIn : MotionToken.hoverOut;
    // The revealed value is a result, not travel: under reduced motion the
    // blur clears at once on hover instead of staying.
    final travels = resolveMotion(context, token).travels;
    final clear = useMotion(token, isHovered.value ? 1 : 0);
    final reveal = travels ? clear.value : (isHovered.value ? 1.0 : 0.0);
    final blur = max(0.0, blurSigma * (1 - reveal));

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      cursor: SystemMouseCursors.click,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: child,
      ),
    );
  }
}
