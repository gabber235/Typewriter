part of "../../layout_renderer.dart";

extension ColumnElementRendering on ColumnElement {
  Widget render(PresentationRenderScope scope) => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: mainAxisAlignment.mainAxisAlignment,
    crossAxisAlignment: crossAxisAlignment.crossAxisAlignment,
    children: children.renderSpaced(spacing, scope, vertical: true),
  );
}
