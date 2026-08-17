part of "../../data_renderer.dart";

extension PolymorphicMatchElementRendering on PolymorphicMatchElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final bindingResult = scope.resolve(binding);
    if (bindingResult case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }

    final resolved = bindingResult.valueOrNull!;
    if (resolved.value is! PolymorphicValue) {
      return presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Polymorphic match requires a polymorphic value",
        ),
      ]);
    }

    final value = resolved.value as PolymorphicValue;
    final selected = cases
        .where((candidate) => candidate.type == value.concreteType)
        .firstOrNull;
    if (selected == null) {
      return _renderFallback(context, scope);
    }

    final concrete = scope.registry.resolve(NamedType(value.concreteType));
    if (concrete case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }

    final representation = concrete.valueOrNull!.representation;
    final childScope = scope.withVirtualBinding(
      VirtualBindingHost(
        id: scopeBindingId,
        snapshot: BindingSnapshot(
          type: representation,
          value: value.value,
          revision: resolved.revision,
          writable: resolved.writable,
        ),
        onChanged: (next) => scope.update(
          binding,
          PolymorphicValue(concreteType: value.concreteType, value: next),
        ),
        interactionTarget: scope.canonical(binding),
      ),
    );
    final child = selected.child.localizeFailures(
      childScope.expressions,
      registry: childScope.registry,
      budget: childScope.budget,
    );
    return PresentationNodeRenderer(node: child, scope: childScope);
  }

  Widget _renderFallback(BuildContext context, PresentationRenderScope scope) {
    final fallback = this.fallback;
    if (fallback == null) return const SizedBox.shrink();
    final child = fallback.localizeFailures(
      scope.expressions,
      registry: scope.registry,
      budget: scope.budget,
    );
    return PresentationNodeRenderer(node: child, scope: scope);
  }
}
