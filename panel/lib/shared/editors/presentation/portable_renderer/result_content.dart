part of "../portable_presentation_renderer.dart";

/// The uniform host chrome around a portable result body.
///
/// The surface picks [density]: compact in dropdowns, card in modals. The
/// name, accent and icon come from the resource's [appearance], so every
/// result row and picker names a resource the way its display declares. The
/// body is the presentation's own details, rendered read only; the row keeps
/// activation and focus. Without an appearance, as for values that are not
/// resources, the body alone fills the row.
final class PortableResultContent extends StatelessWidget {
  const PortableResultContent({
    required this.node,
    required this.scope,
    required this.row,
    required this.density,
    this.appearance,
    this.kindLabel = "",
    this.footer,
    super.key,
  });

  final skir.PresentationNode node;
  final PortablePresentationScope scope;
  final SearchResultRowContext row;
  final SearchResultDensity density;
  final skir.ResourceAppearance? appearance;

  /// What kind of result this is, such as the resource type name.
  final String kindLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final details = appearance != null && _declaresNothing(node)
        ? null
        : PortablePresentationNodeRenderer(
            node: node,
            scope: scope.withReadOnly(true).withAuthoredLayout(node),
          );
    return SearchResultRow(
      row: row,
      density: density,
      title: appearance?.label,
      accent: appearance?.accentColor,
      leading: appearance == null ? null : ResourceIcon(icon: appearance!.icon),
      kindLabel: kindLabel,
      footer: footer,
      body: details,
    );
  }
}

/// Whether [node] is a layout without children, such as the body of a result
/// presentation that adds no details to the host's name, accent and icon.
bool _declaresNothing(skir.PresentationNode node) => switch (node.element) {
  skir.PresentationElement_childrenWrapper(
    value: skir.ChildrenElement_columnWrapper(:final value) ||
        skir.ChildrenElement_rowWrapper(:final value),
  ) =>
    value.children.isEmpty,
  null => true,
  _ => false,
};
