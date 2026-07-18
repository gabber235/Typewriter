import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";

/// A widget that displays its child with a blur effect and reveals it on hover.
///
/// The blur effect animates smoothly when the user hovers over the widget.
class BlurReveal extends HookWidget {
  /// Creates a [BlurReveal] widget.
  ///
  /// The [child] parameter is required and specifies the widget to display.
  /// [blurSigma] controls the intensity of the blur effect (default: 6.0).
  /// [animationDuration] controls how long the reveal/hide animation takes.
  const BlurReveal({
    required this.child,
    this.blurSigma = 6.0,
    this.animationDuration = const Duration(milliseconds: 200),
    super.key,
  });

  /// The widget to display with the blur effect.
  final Widget child;

  /// The blur intensity when not hovered. Higher values mean more blur.
  final double blurSigma;

  /// The duration of the reveal/hide animation.
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final isHovered = useState(false);
    final animationController = useAnimationController(
      duration: animationDuration,
    );
    final blurAnimation = useAnimation(
      Tween<double>(begin: blurSigma, end: 0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      ),
    );

    useEffect(() {
      if (isHovered.value) {
        animationController.forward();
      } else {
        animationController.reverse();
      }
      return null;
    }, [isHovered.value]);

    return MouseRegion(
      onEnter: (_) => isHovered.value = true,
      onExit: (_) => isHovered.value = false,
      cursor: SystemMouseCursors.click,
      child: ImageFiltered(
        imageFilter: blurAnimation > 0.1
            ? ImageFilter.blur(sigmaX: blurAnimation, sigmaY: blurAnimation)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: child,
      ),
    );
  }
}
