part of "../../bound_value_renderer.dart";

/// Resolves a type aware presentation while preserving the current binding.
///
/// An explicit or type-owned editor is bound when its contract is valid.
/// Generated controls serve types without an editor and read-only fields that
/// cannot use one. Broken declarations and recursive delegation surface as
/// field diagnostics.
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
    final resolved = scope.inspect(binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final resolvedBinding = resolved.valueOrNull!;
    final selection = scope.resolvePresentation(
      resolvedBinding.type,
      presentationId,
      scope.accessOf(binding),
    );
    if (selection case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final selected = selection.valueOrNull;
    Widget generated() => PresentationNodeRenderer(
      node: resolvedBinding.type.generateDefaultPresentation(
        binding: binding,
        nodeId: "default.${binding.bindingId.value}",
        registry: scope.registry,
      ),
      scope: scope,
    );
    if (selected == null) {
      return generated();
    }

    if (scope.activePresentations.contains(selected.id)) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Presentation delegation is recursive",
        ),
      ]);
    }

    final input = selected.primaryInput;
    if (input == null) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: "Automatic editor has no primary input",
        ),
      ]);
    }

    final bound = scope.bindPresentation(selected, {input: binding});
    if (bound case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    return PresentationNodeRenderer(
      node: bound.valueOrNull!.$1,
      scope: bound.valueOrNull!.$2,
    );
  }
}
