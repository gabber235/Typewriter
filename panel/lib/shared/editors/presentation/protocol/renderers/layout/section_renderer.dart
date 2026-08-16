part of "../../layout_renderer.dart";

extension SectionElementRendering on SectionElement {
  Widget render(PresentationRenderScope scope) {
    final nodeId = "section.${child.id}";
    return Section(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PresentationHeaderChrome(
          nodeId: nodeId,
          expansionKey: HeaderExpansionKey.node(nodeId: nodeId, binding: null),
          header: PresentationHeader(
            title: title,
            description: description,
            initiallyExpanded: initiallyExpanded,
          ),
          scope: scope,
          child: PresentationNodeRenderer(node: child, scope: scope),
        ),
      ),
    );
  }
}
