import "package:typewriter_panel/typewriter_panel.dart";

/// Owns an animation controller that restarts when [play] becomes true.
///
/// A true value forwards from zero. A false value resets the controller. When
/// [delay] is non zero, each play state change is scheduled after that delay;
/// a later change cancels the pending schedule. The controller is disposed
/// with the hook and may be used by the returned animation widgets.
AnimationController useForwardAnimation({
  required bool play,
  Duration duration = const Duration(milliseconds: 500),
  Duration delay = Duration.zero,
  TickerProvider? vsync,
}) {
  final animation = useAnimationController(duration: duration, vsync: vsync);

  void handleAnimation() {
    if (play) {
      animation.forward(from: 0.0);
    } else {
      animation.reset();
    }
  }

  useEffect(() {
    if (delay == Duration.zero) {
      handleAnimation();
      return null;
    }

    final timer = Timer(delay, handleAnimation);
    return timer.cancel;
  }, [play, delay]);
  return animation;
}
