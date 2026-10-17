import "package:typewriter_panel/typewriter_panel.dart";

/// Temporarily removes a subtree from input, focus traversal, and semantics.
///
/// Set [excluding] while another owner is animating or replacing the child.
/// The child stays mounted, so its local state and lifecycle continue normally.
class ExcludeInteraction extends StatelessWidget {
  const ExcludeInteraction({
    required this.excluding,
    required this.child,
    super.key,
  });

  final bool excluding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: excluding,
      child: ExcludeFocus(
        excluding: excluding,
        child: IgnorePointer(ignoring: excluding, child: child),
      ),
    );
  }
}
