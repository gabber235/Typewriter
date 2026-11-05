import "package:typewriter_panel/typewriter_panel.dart";

/// Renders [child] the way it renders for a user who asked the platform for
/// reduced motion.
final class ReducedMotion extends StatelessWidget {
  /// [child] with animations reduced.
  const ReducedMotion({required this.child, super.key});

  /// What renders with reduced motion.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child,
    );
  }
}
