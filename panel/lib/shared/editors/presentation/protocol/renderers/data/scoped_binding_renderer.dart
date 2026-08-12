part of "../../data_renderer.dart";

extension ScopedBindingElementRendering on ScopedBindingElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final bindingResult = scope.resolve(binding);
    if (bindingResult case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final resolved = bindingResult.valueOrNull!;
    final childScope = scope.withAlias(
      scopeBindingId,
      scope.canonical(binding),
      BindingSnapshot(
        type: resolved.type,
        value: resolved.value,
        revision: resolved.revision,
        writable: resolved.writable,
      ),
    );
    final localizedChild = child.localizeFailures(
      childScope.expressions,
      registry: childScope.registry,
      budget: childScope.budget,
    );
    return PresentationNodeRenderer(node: localizedChild, scope: childScope);
  }
}
