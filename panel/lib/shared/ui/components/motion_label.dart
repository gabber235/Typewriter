import "package:typewriter_panel/typewriter_panel.dart";

/// A label that changes in place and can ripple while something is busy.
///
/// A new [text] keeps the letters it shares with the old one, drops the old
/// tail at once and types the new tail with the `type` token: Publish,
/// Publishing, Published. With [typesIn] the first text types from nothing.
/// While [rippling] the letters rise one after another with the `ripple`
/// token, the one loop a busy word may play; under reduced motion they stay
/// level. Assistive technology reads the whole new text from the first frame.
class MotionLabel extends HookWidget {
  const MotionLabel(
    this.text, {
    this.rippling = false,
    this.typesIn = false,
    this.style,
    super.key,
  });

  final String text;
  final bool rippling;
  final bool typesIn;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final typed = useTyping(text, typesIn: typesIn);
    final ripple = resolveMotion(context, MotionToken.ripple);
    final lift = useRipple(
      rippling: rippling && ripple.travels,
      letters: text.length,
      motion: ripple,
    );

    final settled = typed == text.length && !lift.moving;
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: settled
            ? Text(
                text,
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              )
            // The whole text lays the label out, invisible, so a label
            // that types or ripples sizes like a settled one in any flex;
            // the moving letters paint over it.
            : Stack(
                clipBehavior: Clip.none,
                children: [
                  RichText(
                    text: TextSpan(
                      text: text,
                      style: DefaultTextStyle.of(context).style
                          .merge(style)
                          .copyWith(color: context.colors.clear),
                    ),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textScaler: MediaQuery.textScalerOf(context),
                  ),
                  Positioned.fill(
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      maxWidth: double.infinity,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          for (var i = 0; i < typed; i++)
                            Transform.translate(
                              offset: Offset(0, -lift.of(i)),
                              child: Text(text[i], style: style),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// An icon that ripples as one letter while [rippling]: the busy sign of a
/// button with no busy word.
class RippleGlyph extends HookWidget {
  const RippleGlyph({required this.rippling, required this.child, super.key});

  final bool rippling;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ripple = resolveMotion(context, MotionToken.ripple);
    final lift = useRipple(
      rippling: rippling && ripple.travels,
      letters: 1,
      motion: ripple,
    );
    return Transform.translate(offset: Offset(0, -lift.of(0)), child: child);
  }
}

/// How far each letter of a rippling word rises right now.
final class RippleLift {
  const RippleLift._(this._clock, this._motion, this._round);

  final AnimationController _clock;
  final ResolvedMotion<LetterLanding> _motion;
  final Duration _round;

  /// The ripple is playing.
  bool get moving => _clock.isAnimating;

  /// How far letter [index] rises, in pixels.
  double of(int index) {
    if (!_clock.isAnimating) return 0;
    final loop = _motion.motion as LoopMotion;
    final letters = _motion.landing;
    final elapsed = (_clock.value * Duration.microsecondsPerSecond).round();
    final at = elapsed % _round.inMicroseconds;
    final local =
        (at - (letters.letterGap * index).inMicroseconds) /
        loop.period.inMicroseconds;
    if (local <= 0 || local >= 1) return 0;
    return letters.rise * sin(pi * loop.curve.transform(local));
  }
}

/// Plays the ripple of a word of [letters] letters while [rippling]. One
/// round lasts the loop period plus the letter gap for every letter after
/// the first; the loop's own round limit applies.
RippleLift useRipple({
  required bool rippling,
  required int letters,
  required ResolvedMotion<LetterLanding> motion,
}) {
  final clock = useAnimationController(
    lowerBound: 0,
    upperBound: double.infinity,
    animationBehavior: AnimationBehavior.preserve,
  );
  // Under reduced motion the token is still and holds no loop.
  final loop = motion.motion is LoopMotion ? motion.motion as LoopMotion : null;
  final plays = rippling && loop != null;
  final round = loop == null
      ? Duration.zero
      : loop.period + motion.landing.letterGap * max(0, letters - 1);
  useEffect(() {
    if (plays) {
      clock.animateWith(_RippleClock(round: round, rounds: loop.cycles));
    } else {
      clock
        ..stop()
        ..value = 0;
    }
    return null;
  }, [plays, round, loop?.cycles]);
  useListenable(clock);
  return RippleLift._(clock, motion, round);
}

/// Elapsed seconds, done after [rounds] rounds of [round], or never.
final class _RippleClock extends Simulation {
  _RippleClock({required Duration round, required this.rounds})
    : _round = round.inMicroseconds / Duration.microsecondsPerSecond;

  final double _round;
  final int? rounds;

  @override
  double x(double time) => time;

  @override
  double dx(double time) => 1;

  @override
  bool isDone(double time) => rounds != null && time >= rounds! * _round;
}
