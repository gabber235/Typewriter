import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Switches messages with a clipped elastic slide and fade transition.
class ElasticMessageSwitcher extends StatelessWidget {
  const ElasticMessageSwitcher({
    required this.child,
    this.sizeDuration = const Duration(milliseconds: 1000),
    this.duration = const Duration(milliseconds: 420),
    this.reverseDuration = const Duration(milliseconds: 180),
    super.key,
  });

  /// Message to display. Use a distinct key to animate between messages.
  final Widget? child;

  final Duration sizeDuration;
  final Duration duration;
  final Duration reverseDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: sizeDuration,
      alignment: Alignment.topCenter,
      curve: const ElasticOutCurve(0.9),
      child: AnimatedSwitcher(
        duration: duration,
        reverseDuration: reverseDuration,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
        transitionBuilder: (child, animation) {
          return ElasticMessageTransition(animation: animation, child: child);
        },
        child: child,
      ),
    );
  }
}
