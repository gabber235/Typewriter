part of "../../data_renderer.dart";

extension TypedFieldElementRendering on TypedFieldElement {
  Widget render(PresentationRenderScope scope) => presentation == null
      ? ProtocolBoundValueEditor(
          control: BoundControl(binding: binding),
          scope: scope,
        )
      : PresentationNodeRenderer(node: presentation!, scope: scope);
}
