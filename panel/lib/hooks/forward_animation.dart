import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";

AnimationController useForwardAnimation({
  required bool play,
}) {
  final animation = useAnimationController(duration: 500.ms);

  useEffect(
    () {
      if (play) {
        animation.forward(from: 0.0);
      } else {
        animation.reset();
      }
      return null;
    },
    [play],
  );
  return animation;
}
