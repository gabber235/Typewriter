import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

AnimationController useForwardAnimation({
  required bool play,
  Duration duration = const Duration(milliseconds: 500),
  Duration delay = Duration.zero,
}) {
  final animation = useAnimationController(duration: duration);

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
