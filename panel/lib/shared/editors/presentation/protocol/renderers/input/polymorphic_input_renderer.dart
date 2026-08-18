library;

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension PolymorphicInputElementRendering on PolymorphicInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return BoundControlShell(
      control: element.control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is NamedType && binding.value is PolymorphicValue
          ? null
          : "Polymorphic control requires a named polymorphic binding",
      builder: (context, field) {
        final value = field.binding.value as PolymorphicValue;
        final selectedIndex = element.concreteTypes.indexWhere(
          (candidate) => candidate.type == value.concreteType,
        );
        final selected = element.concreteTypes
            .where((candidate) => candidate.type == value.concreteType)
            .firstOrNull;
        final content = switch (selected?.presentation) {
          final presentation? => PresentationNodeRenderer(
            node: presentation.localizeFailures(
              scope.expressions,
              registry: scope.registry,
              budget: scope.budget,
            ),
            scope: scope,
          ),
          null => value._defaultConcreteEditor(field.binding, element, scope),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdaptiveChoiceControl<ResolvedTypeRef>(
              selected: value.concreteType,
              choices: {
                for (final candidate in element.concreteTypes)
                  candidate.type: scope.expressionText(candidate.label),
              },
              enabled: field.editable,
              onSelected: (type) => type._replace(element, scope),
            ),
            const SizedBox(height: 12),
            DirectionalContentSwitcher(
              index: selectedIndex,
              child: KeyedSubtree(
                key: ValueKey(value.concreteType),
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }
}

extension on PolymorphicValue {
  Widget _defaultConcreteEditor(
    ResolvedBinding binding,
    PolymorphicInputElement element,
    PresentationRenderScope scope,
  ) {
    final concrete = scope.registry.resolve(NamedType(concreteType));
    if (concrete case TypeFailure(:final diagnostics)) {
      return Builder(
        builder: (context) => presentationDiagnostic(context, diagnostics),
      );
    }
    const payloadBindingId = BindingId(2147483647);
    const payloadReference = BindingReference(bindingId: payloadBindingId);
    final representation = concrete.valueOrNull!.representation;
    final childScope = scope.withVirtualBinding(
      VirtualBindingHost(
        id: payloadBindingId,
        snapshot: BindingSnapshot(
          type: representation,
          value: value,
          revision: binding.revision,
          writable: binding.writable,
        ),
        onChanged: (next) => scope.update(
          element.control.binding,
          PolymorphicValue(concreteType: concreteType, value: next),
        ),
        interactionTarget: scope.canonical(element.control.binding),
      ),
    );
    return ResolvedBinding(
      reference: payloadReference,
      type: representation,
      value: value,
      revision: binding.revision,
      writable: binding.writable,
    ).renderDefaultPresentation(
      childScope,
      nodeId: "polymorphic.${concreteType.id}",
    );
  }
}

extension on ResolvedTypeRef? {
  void _replace(
    PolymorphicInputElement element,
    PresentationRenderScope scope,
  ) {
    if (this == null) return;
    final type = this!;
    final concrete = scope.registry.resolve(NamedType(type));
    final resolved = concrete.valueOrNull;
    if (resolved == null || !resolved.isConcrete) return;
    final initial = resolved.representation
        .createInitialValue(registry: scope.registry)
        .valueOrNull;
    if (initial == null) return;
    scope.update(
      element.control.binding,
      PolymorphicValue(concreteType: type, value: initial),
    );
  }
}
