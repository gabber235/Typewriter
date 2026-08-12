part of "../../layout_renderer.dart";

extension WrapElementRendering on WrapElement {
  Widget render(PresentationRenderScope scope) => Wrap(
    spacing: spacing,
    runSpacing: spacing,
    alignment: mainAxisAlignment.wrapAlignment,
    crossAxisAlignment: crossAxisAlignment.wrapCrossAlignment,
    children: children.renderChildren(scope),
  );
}
