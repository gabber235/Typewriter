import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:typewriter_panel/widgets/generic/components/elastic_message_transition.dart";

/// Switches messages with a clipped elastic slide and fade transition.
class ElasticMessageSwitcher extends StatelessWidget {
  const ElasticMessageSwitcher({required this.child, super.key});

  /// Message to display. Use a distinct key to animate between messages.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 1000.ms,
      alignment: Alignment.topCenter,
      curve: const ElasticOutCurve(0.9),
      child: AnimatedSwitcher(
        duration: 420.ms,
        reverseDuration: 180.ms,
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
