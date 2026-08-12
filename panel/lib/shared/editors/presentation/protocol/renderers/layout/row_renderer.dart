part of "../../layout_renderer.dart";

extension RowElementRendering on RowElement {
  Widget render(PresentationRenderScope scope) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
    children: children.renderSpaced(spacing, scope),
  );
}
