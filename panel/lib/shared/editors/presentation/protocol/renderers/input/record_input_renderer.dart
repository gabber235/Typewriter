part of "../../composite_input_renderer.dart";

extension RecordInputElementRendering on RecordInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => fieldPresentation == null
      ? binding.renderDefaultPresentation(
          scope,
          nodeId: "record.${control.binding.bindingId.value}",
          root: true,
        )
      : PresentationNodeRenderer(
          node: fieldPresentation!.localizeFailures(
            scope.expressions,
            registry: scope.registry,
            budget: scope.budget,
          ),
          scope: scope,
        );
}
