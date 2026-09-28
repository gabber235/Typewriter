part of "../../layout_renderer.dart";

/// Arranges rendered children on one horizontal axis.
///
/// Children are rendered with the parent scope before spacing widgets are
/// inserted. The row owns arrangement only; nested nodes own their behavior.
extension RowElementRendering on RowElement {
  Widget render(PresentationRenderScope scope) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
    children: children.renderAxisChildren(spacing, scope),
  );
}
