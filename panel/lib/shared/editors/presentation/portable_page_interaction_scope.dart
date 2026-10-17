import "package:typewriter_panel/typewriter_panel.dart";

/// Lets an application supply page interaction without coupling portable UI
/// to its resource identities or editing workspace.
class PortablePageInteractionScope extends InheritedWidget {
  const PortablePageInteractionScope({
    required this.nodeBuilder,
    required this.graphBuilder,
    required super.child,
    super.key,
  });

  final Widget Function(
    BuildContext context,
    PortablePageEntryProjection entry,
    PortablePresentationScope scope,
    Widget child,
  )
  nodeBuilder;

  final Widget Function(
    BuildContext context,
    List<PortablePageEntryProjection> entries,
    PortablePresentationScope scope,
    Widget child,
  )
  graphBuilder;

  static PortablePageInteractionScope? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<PortablePageInteractionScope>();

  @override
  bool updateShouldNotify(PortablePageInteractionScope oldWidget) =>
      nodeBuilder != oldWidget.nodeBuilder ||
      graphBuilder != oldWidget.graphBuilder;
}
