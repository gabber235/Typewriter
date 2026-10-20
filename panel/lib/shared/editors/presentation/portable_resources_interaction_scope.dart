import "package:typewriter_panel/typewriter_panel.dart";

/// How a resources element arranges its members.
enum PortableResourcesLayoutKind { graph, timeline, grid, list, tree }

/// The members one resources element lays out, as an application sees them.
final class PortableResourcesView {
  const PortableResourcesView({
    required this.members,
    required this.scope,
    required this.layout,
  });

  final List<PortableResourceMember> members;
  final PortablePresentationScope scope;
  final PortableResourcesLayoutKind layout;
}

/// Lets an application supply member interaction, such as selection, opening
/// and dragging, without coupling portable UI to its resource identities or
/// editing workspace. Without this scope members only report activation
/// through the presentation's open callback.
class PortableResourcesInteractionScope extends InheritedWidget {
  const PortableResourcesInteractionScope({
    required this.itemBuilder,
    required this.layoutBuilder,
    required super.child,
    super.key,
  });

  /// Wraps one rendered member. [child] already shows the member's item
  /// presentation; the builder adds interaction and its visual state.
  final Widget Function(
    BuildContext context,
    PortableResourcesView view,
    PortableResourceMember member,
    Widget child,
  )
  itemBuilder;

  /// Wraps a whole layout, for example to install shared shortcuts.
  final Widget Function(
    BuildContext context,
    PortableResourcesView view,
    Widget child,
  )
  layoutBuilder;

  static PortableResourcesInteractionScope? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<PortableResourcesInteractionScope>();

  @override
  bool updateShouldNotify(PortableResourcesInteractionScope oldWidget) =>
      itemBuilder != oldWidget.itemBuilder ||
      layoutBuilder != oldWidget.layoutBuilder;
}
