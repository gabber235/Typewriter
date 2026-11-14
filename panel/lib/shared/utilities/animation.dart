import "package:typewriter_panel/typewriter_panel.dart";

/// Adds curve composition to Flutter tweens.
extension TweenExtension<T> on Tween<T> {
  /// Transforms animation progress through [curve] before evaluating this tween.
  Animatable<T> curved(Curve curve) {
    return chain(CurveTween(curve: curve));
  }
}
