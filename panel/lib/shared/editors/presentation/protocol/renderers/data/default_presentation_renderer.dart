part of "../../bound_value_renderer.dart";

/// Resolves a type aware presentation while preserving the current binding.
///
/// An explicit presentation id is preferred when it is compatible with the
/// resolved type. Otherwise the type registry generates a default. Delegation
/// is tracked in the scope and rejected when it would recurse, so malformed
/// presentation definitions produce diagnostics instead of unbounded rendering.
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
      return generated();
    }

    final bound = scope.bindPresentation(selected, {input: binding});
    if (bound is TypeFailure) {
      return generated();
    }
    return PresentationNodeRenderer(
      node: bound.valueOrNull!.$1,
      scope: bound.valueOrNull!.$2,
    );
  }
}
