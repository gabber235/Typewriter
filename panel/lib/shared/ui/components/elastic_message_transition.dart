import "package:typewriter_panel/typewriter_panel.dart";

/// Applies the message transition used by [ElasticMessageSwitcher].
///
/// The supplied animation is owned by the enclosing switcher. This transition
/// does not alter the child's lifecycle or identity.
class ElasticMessageTransition extends StatelessWidget {
  const ElasticMessageTransition({
    required this.child,
    required this.animation,
    super.key,
  });

  final Widget child;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final elastic = CurvedAnimation(
      parent: animation,
      curve: const ElasticOutCurve(0.82),
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -0.1),
          end: Offset.zero,
        ).animate(elastic),
        child: child,
      ),
    );
  }
}
