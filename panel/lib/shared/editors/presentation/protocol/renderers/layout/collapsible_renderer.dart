part of "../../layout_renderer.dart";

extension CollapsibleElementRendering on CollapsibleElement {
  Widget render(PresentationRenderScope scope) {
    final nodeId = "collapsible.${child.id}";
    return PresentationHeaderChrome(
      nodeId: nodeId,
      expansionKey: HeaderExpansionKey.node(nodeId: nodeId, binding: null),
      header: PresentationHeader(
        title: title,
        initiallyExpanded: initiallyExpanded,
      ),
      scope: scope,
      child: PresentationNodeRenderer(node: child, scope: scope),
    );
  }
}
