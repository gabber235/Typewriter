part of "../../layout_renderer.dart";

/// Projects a column element after its child nodes have been resolved.
///
/// The presentation model owns alignment and spacing intent. Flutter owns the
/// resulting arrangement, while child rendering remains the responsibility of
/// [PresentationNodeRenderer]. The minimum main axis size keeps the column
/// content sized rather than claiming unused space from its parent.
extension ColumnElementRendering on ColumnElement {
  Widget render(PresentationRenderScope scope) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
    children: children.renderAxisChildren(spacing, scope, vertical: true),
  );
}
