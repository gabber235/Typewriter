part of "../../layout_renderer.dart";

extension PaddingElementRendering on PaddingElement {
  Widget render(PresentationRenderScope scope) => Padding(
    padding: EdgeInsetsDirectional.fromSTEB(start, top, end, bottom),
    child: PresentationNodeRenderer(node: child, scope: scope),
  );
}
