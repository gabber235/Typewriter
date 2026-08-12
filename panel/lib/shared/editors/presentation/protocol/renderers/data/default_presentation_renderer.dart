part of "../../bound_value_renderer.dart";

extension DefaultPresentationElementRendering on DefaultPresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    if (presentationId case final presentationId?
        when scope.activePresentations.contains(presentationId)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation delegation is recursive",
        ),
      ]);
    }
    final resolved = scope.resolve(binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final resolvedBinding = resolved.valueOrNull!;
    final selected = scope.resolvePresentation(
      resolvedBinding.type,
      presentationId,
    );
    if (selected == null) {
      final generated = resolvedBinding.type.generateDefaultPresentation(
        binding: binding,
        nodeId: "default.${binding.bindingId.value}",
      );
      return PresentationNodeRenderer(node: generated, scope: scope);
    }
    if (scope.activePresentations.contains(selected.id)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation delegation is recursive",
        ),
      ]);
    }
    final childScope = scope
        .withAlias(
          const BindingId(0),
          scope.canonical(binding),
          BindingSnapshot(
            type: resolvedBinding.type,
            value: resolvedBinding.value,
            revision: resolvedBinding.revision,
            writable: resolvedBinding.writable,
          ),
        )
        .copyWith(
          activePresentations: {...scope.activePresentations, selected.id},
        );
    return PresentationNodeRenderer(node: selected.root, scope: childScope);
  }
}
