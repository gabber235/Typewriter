import "package:typewriter_panel/typewriter_panel.dart";

/// Reusable animation effects for interactive panel controls.
extension AnimationExtension on Animate {
  /// Scales an element toward its hovered size, with a softer return curve.
  Animate hoverScale(bool isHovered) => scaleXY(
    duration: isHovered ? 750.ms : 300.ms,
    curve: isHovered ? ElasticOutCurve(0.4) : Curves.easeInOutQuad,
    begin: 1,
    end: 1.05,
  );

  /// Applies the small rotation used to signal a hovered element.
  Animate hoverRotate(bool isHovered) => rotate(
    duration: 300.ms,
    delay: isHovered ? 50.ms : 0.ms,
    curve: Curves.easeInOutQuad,
    begin: 0,
    end: 0.005,
  );
}

/// Adds curve composition to Flutter tweens.
extension TweenExtension<T> on Tween<T> {
  /// Applies [curve] after this tween without changing its endpoints.
  Animatable<T> curved(Curve curve) {
    return chain(CurveTween(curve: curve));
  }
}
