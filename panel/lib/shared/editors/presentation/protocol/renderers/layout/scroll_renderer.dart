part of "../../layout_renderer.dart";

extension ScrollElementRendering on ScrollElement {
  Widget render(PresentationRenderScope scope) => SingleChildScrollView(
    child: PresentationNodeRenderer(node: child, scope: scope),
  );
}
