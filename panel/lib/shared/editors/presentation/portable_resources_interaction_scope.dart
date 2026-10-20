import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_resources_interaction_scope.freezed.dart";

/// How a resources element arranges its members.
enum PortableResourcesLayoutKind { graph, timeline, grid, list, tree }

/// The members one resources element lays out, as an application sees them.
@freezed
abstract class PortableResourcesView with _$PortableResourcesView {
  const factory PortableResourcesView({
    required List<PortableResourceMember> members,
    required PortablePresentationScope scope,
    required PortableResourcesLayoutKind layout,

    /// The link field the members are linked at, when the binding has one.
    skir.ValueLocation? location,
  }) = _PortableResourcesView;
}

/// One group of a tree layout: the hierarchy path [field] its members are
/// grouped by, the group's [path], and every member at or below it.
@freezed
abstract class PortableResourcesGroup with _$PortableResourcesGroup {
  const factory PortableResourcesGroup({
    required skir.ValuePath field,
    required String path,
    required String name,
    required List<PortableResourceMember> members,
  }) = _PortableResourcesGroup;
}

/// Lets an application supply member interaction, such as selection, opening,
/// dragging and dropping, without coupling portable UI to its resource
/// identities or editing workspace. Without this scope members only report
/// activation through the presentation's open callback, and groups, graph
/// canvases and link fields render as they are.
class PortableResourcesInteractionScope extends InheritedWidget {
  const PortableResourcesInteractionScope({
    required this.itemBuilder,
    required this.layoutBuilder,
    required super.child,
    this.groupBuilder,
    this.canvasBuilder,
    this.linkFieldBuilder,
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

  /// Wraps a tree group header.
  final Widget Function(
    BuildContext context,
    PortableResourcesView view,
    PortableResourcesGroup group,
    Widget header,
  )?
  groupBuilder;

  /// Wraps the viewport of a graph layout. [toGrid] converts a global
  /// position into grid units of the canvas.
  final Widget Function(
    BuildContext context,
    PortableResourcesView view,
    Offset? Function(Offset globalPosition) toGrid,
    Widget canvas,
  )?
  canvasBuilder;

  /// Wraps a control that edits the links at [location].
  final Widget Function(
    BuildContext context,
    skir.ValueLocation location,
    Widget control,
  )?
  linkFieldBuilder;

  static PortableResourcesInteractionScope? maybeOf(
    BuildContext context,
  ) => context
      .dependOnInheritedWidgetOfExactType<PortableResourcesInteractionScope>();

  /// Wraps [control] through the nearest scope's [linkFieldBuilder] when
  /// [scope] lets people edit the links at [location]. A disabled or read only
  /// control is returned as it is, so it never receives dropped resources.
  static Widget wrapLinkField(
    BuildContext context,
    PortablePresentationScope scope,
    skir.ValueLocation location,
    Widget control,
  ) {
    if (!scope.enabled || scope.readOnly) return control;
    return maybeOf(context)?.linkFieldBuilder
            ?.call(context, location, control) ??
        control;
  }

  @override
  bool updateShouldNotify(PortableResourcesInteractionScope oldWidget) =>
      itemBuilder != oldWidget.itemBuilder ||
      layoutBuilder != oldWidget.layoutBuilder ||
      groupBuilder != oldWidget.groupBuilder ||
      canvasBuilder != oldWidget.canvasBuilder ||
      linkFieldBuilder != oldWidget.linkFieldBuilder;
}
