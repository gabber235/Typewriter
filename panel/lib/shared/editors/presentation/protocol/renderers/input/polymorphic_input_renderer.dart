library;

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Lets the author choose one concrete type for a nominal polymorphic value,
/// then renders that type's presentation or its default representation editor.
///
/// The concrete type selector replaces the whole polymorphic value with an
/// initial valid payload. The payload editor writes back through the original
/// binding, which keeps the scope as the sole update owner.
extension PolymorphicInputElementRendering on PolymorphicInputElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    return BoundControlShell(
      nominal: true,
      synthesizeMissingDiagnostic: false,
      control: element.control,
      scope: scope,
      shapeMismatch: (binding) =>
          binding.type is NamedType &&
              (binding.value is MixedEditorValue ||
                  binding.value is MissingEditorValue ||
                  binding.value.valueOrNull is PolymorphicValue)
          ? null
          : "Polymorphic control requires a named polymorphic binding",
      builder: (context, field) {
        final value = field.value as PolymorphicValue?;
        final reference = scope.canonical(element.control.binding);
        final owner = scope.editOwnerFor?.call(reference);
        final structuralOwner = owner is EditorStructureOwner ? owner : null;
        final draft = structuralOwner?.polymorphicStructure(reference.path);
        final selectedType = draft?.concreteType ?? value?.concreteType;
        final selectedIndex = element.concreteTypes.indexWhere(
          (candidate) => candidate.type == selectedType,
        );
        final selected = element.concreteTypes
            .where((candidate) => candidate.type == selectedType)
            .firstOrNull;
        final content = selectedType == null
            ? const SizedBox.shrink()
            : draft != null && structuralOwner != null
            ? _draftConcreteEditor(
                field.binding,
                element,
                scope,
                structuralOwner,
                reference.path,
                selectedType,
                draft.payload,
              )
            : switch (selected?.presentation) {
                final presentation? => PresentationNodeRenderer(
                  node: presentation.localizeFailures(
                    scope.expressions,
                    registry: scope.registry,
                    budget: scope.budget,
                  ),
                  scope: scope,
                ),
                null => value!._defaultConcreteEditor(
                  field.binding.resolvedOrNull!,
                  element,
                  scope,
                ),
              };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdaptiveChoiceControl<ResolvedTypeRef>(
              selected: selectedType,
              initialization: field.mixed
                  ? SelectionInitializationPolicy.explicit
                  : SelectionInitializationPolicy.automatic,
              choices: {
                for (final candidate in element.concreteTypes)
                  candidate.type: scope.expressionText(candidate.label),
              },
              enabled: field.editable,
              onSelected: (type) {
                if (type == null) return;
                if (structuralOwner != null) {
                  structuralOwner.selectConcreteType(reference.path, type);
                } else {
                  type._replace(element, scope);
                }
              },
            ),
            if (field.mixed) const MixedValueMessage(),
            SizedBox(height: context.spacing.space3),
            DirectionalContentSwitcher(
              index: selectedIndex,
              child: KeyedSubtree(key: ValueKey(selectedType), child: content),
            ),
          ],
        );
      },
    );
  }
}

Widget _draftConcreteEditor(
  InspectedBinding binding,
  PolymorphicInputElement element,
  PresentationRenderScope scope,
  EditorStructureOwner owner,
  DataPath path,
  ResolvedTypeRef concreteType,
  EditorValue payload,
) {
  const payloadBindingId = BindingId(2147483647);
  const payloadReference = BindingReference(bindingId: payloadBindingId);
  final source = _DraftConcreteBindingSource(
    owner: owner,
    path: path,
    type: NamedType(concreteType),
    revision: binding.revision,
    writable: binding.writable,
  );
  final childScope = scope.withAlias(
    payloadBindingId,
    element.control.binding,
    source,
  );
  final selected = element.concreteTypes
      .where((candidate) => candidate.type == concreteType)
      .firstOrNull;
  if (selected?.presentation case final presentation?) {
    return PresentationNodeRenderer(
      node: presentation,
      scope: childScope.withAlias(
        element.control.binding.bindingId,
        payloadReference,
        source,
      ),
    );
  }
  return InspectedBinding(
    reference: payloadReference,
    type: NamedType(concreteType),
    value: payload,
    revision: binding.revision,
    writable: binding.writable,
  ).renderDefaultPresentation(
    childScope,
    nodeId: "polymorphic.${concreteType.id}",
    root: true,
  );
}

final class _DraftConcreteBindingSource implements BindingSource {
  const _DraftConcreteBindingSource({
    required this.owner,
    required this.path,
    required this.type,
    required this.revision,
    required this.writable,
  });

  final EditorStructureOwner owner;
  final DataPath path;
  final TypeExpression type;
  @override
  final int revision;
  @override
  final bool writable;

  @override
  TypeResult<BindingSourceState> inspect(
    DataPath child, {
    TypeRegistry? registry,
  }) {
    final resolved = type.resolvePath(child, registry: registry);
    if (resolved case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(
      BindingSourceState(
        type: resolved.valueOrNull!,
        value: owner.concretePayloadValue(path, child),
      ),
    );
  }
}

/// Supplies the virtual payload binding used when a concrete type has no
/// custom presentation. Its update callback reconstructs the enclosing
/// polymorphic value rather than exposing a second mutable source of truth.
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

    final nominalType = NamedType(concreteType);
    final childScope = scope.withVirtualBinding(
      VirtualBindingHost(
        id: payloadBindingId,
        snapshot: BindingSnapshot(
          type: nominalType,
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
      source: element.control.binding,
    );
    return PresentationNodeRenderer(
      node: PresentationNode(
        id: "polymorphic.${concreteType.id}",
        element: const DefaultPresentationElement(binding: payloadReference),
      ),
      scope: childScope,
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
