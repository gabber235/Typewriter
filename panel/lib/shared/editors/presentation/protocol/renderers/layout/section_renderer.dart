part of "../../layout_renderer.dart";

extension SectionElementRendering on SectionElement {
  Widget render(PresentationRenderScope scope) => Section(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: PresentationHeaderChrome(
        nodeId: "section.${child.id}",
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
