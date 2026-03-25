import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

extension AnimationExtension on Animate {
  Animate hoverScale(bool isHovered) => scaleXY(
    duration: isHovered ? 750.ms : 300.ms,
    curve: isHovered ? ElasticOutCurve(0.4) : Curves.easeInOutQuad,
    begin: 1,
    end: 1.05,
  );

  Animate hoverRotate(bool isHovered) => rotate(
    duration: 300.ms,
    delay: isHovered ? 50.ms : 0.ms,
    curve: Curves.easeInOutQuad,
    begin: 0,
    end: 0.005,
  );
}

extension TweenExtension<T> on Tween<T> {
  Animatable<T> curved(Curve curve) {
    return chain(CurveTween(curve: curve));
  }
}
