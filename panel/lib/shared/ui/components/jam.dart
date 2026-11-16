import "package:typewriter_panel/typewriter_panel.dart";

/// Jams [child] once for every new failure: a decaying judder with the
/// `jam` token and a red flash over [shape] that fades to nothing, so the
/// control looks as before. Under reduced motion the judder never starts
/// and the flash keeps its fade.
class Jam extends HookWidget {
  const Jam({
    required this.failures,
    required this.child,
    this.shape,
    super.key,
  });

  /// How many times the work behind [child] failed. A rise jams once; a
  /// rebuild with the same count never jams again.
  final int failures;
  final Widget child;

  /// The outline the flash fills; the control radius when null.
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    final jam = resolveMotion(context, MotionToken.jam);
    final judder = useMotionController();
    final flash = useAnimationController(
      duration: jam.landing.flash,
      animationBehavior: AnimationBehavior.preserve,
    );
    final seen = useRef(failures);

    useEffect(() {
      final fresh = failures > seen.value;
      seen.value = failures;
      if (!fresh) return null;
      judder.play(jam);
      flash.forward(from: 0);
      return null;
    }, [failures]);

    useListenable(Listenable.merge([judder, flash]));
    final red = flash.isAnimating
        ? context.colors.danger.withValues(alpha: 1 - flash.value)
        : context.colors.clear;

    return Transform.translate(
      offset: Offset(judder.value * jam.landing.amplitude, 0),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: shape ?? context.shapes.mediumShape,
          color: red,
        ),
        child: child,
      ),
    );
  }
}
