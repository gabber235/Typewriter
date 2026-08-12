part of "../../layout_renderer.dart";

extension CollapsibleElementRendering on CollapsibleElement {
  Widget render(PresentationRenderScope scope) => PresentationHeaderChrome(
    nodeId: "collapsible.${child.id}",
    header: PresentationHeader(
      title: title,
      initiallyExpanded: initiallyExpanded,
    ),
    scope: scope,
    child: PresentationNodeRenderer(node: child, scope: scope),
  );
}
