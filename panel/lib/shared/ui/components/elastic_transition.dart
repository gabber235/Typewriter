import "dart:math";

import "package:flutter/material.dart";

import "package:typewriter_panel/shared/utilities/animation.dart";

class ElasticTransition extends StatelessWidget {
  const ElasticTransition({
    required this.child,
    required this.animation,
    super.key,
  });

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final size = CurvedAnimation(
      parent: animation,
      curve: ElasticOutCurve(0.9),
      reverseCurve: const Interval(0, 0.9, curve: Cubic(.89, -0.01, .51, 1.11)),
    );

    final scale = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.2, 1, curve: ElasticOutCurve(0.8)),
        reverseCurve: const Interval(0.5, 1, curve: Curves.ease),
      ),
    );

    final opacity = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.55, 1, curve: Curves.easeIn),
    );

    final padding = Tween<double>(
      begin: 0,
      end: 3,
    ).curved(Curves.ease).animate(animation);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: size,
        builder: (context, child) {
          return Align(
            alignment: AlignmentDirectional(-1.0, 0),
            heightFactor: max(size.value, 0.0),
            child: child,
          );
        },
        child: ScaleTransition(
          scale: scale,
          child: AnimatedBuilder(
            animation: padding,
            child: child,
            builder: (context, child) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: padding.value),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
