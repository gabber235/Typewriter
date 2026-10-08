import "package:typewriter_panel/typewriter_panel.dart";

/// Switches keyed messages with an elastic slide, fade, and size transition.
///
/// The child identity controls when a message changes. This widget owns only
/// presentation timing and does not retain message or loading state.
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
