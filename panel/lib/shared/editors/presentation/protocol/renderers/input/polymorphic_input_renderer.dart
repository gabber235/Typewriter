library;

import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Lets the author choose one concrete type for a nominal polymorphic value,
/// then renders that type's presentation or its default representation editor.
///
/// The concrete type selector creates an incomplete typed draft. Realm owns
/// concrete initialization and later completes the value through its type
/// prototype before persistence. The payload editor writes back through the
/// original binding, which keeps the scope as the sole update owner.
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
        final selectionOwner = switch (owner) {
          final ConcreteTypeSelectionOwner value => value,
          _ => null,
        };
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
            _ConcreteTypeChoice(
              key: ValueKey(reference.path),
              selected: selectedType,
              initialization: field.mixed
                  ? SelectionInitializationPolicy.explicit
                  : SelectionInitializationPolicy.automatic,
              choices: {
                for (final candidate in element.concreteTypes)
                  candidate.type: scope.expressionText(candidate.label),
              },
              enabled: field.editable && selectionOwner != null,
              owner: selectionOwner,
              path: reference.path,
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

class _ConcreteTypeChoice extends StatefulWidget {
  const _ConcreteTypeChoice({
    required this.selected,
    required this.initialization,
    required this.choices,
    required this.enabled,
    required this.owner,
    required this.path,
    super.key,
  });

  final ResolvedTypeRef? selected;
  final SelectionInitializationPolicy initialization;
  final Map<ResolvedTypeRef, String> choices;
  final bool enabled;
  final ConcreteTypeSelectionOwner? owner;
  final DataPath path;

  @override
  State<_ConcreteTypeChoice> createState() => _ConcreteTypeChoiceState();
}

class _ConcreteTypeChoiceState extends State<_ConcreteTypeChoice> {
  ResolvedTypeRef? _pending;
  List<TypeDiagnostic>? _diagnostics;
  int _request = 0;

  @override
  void didUpdateWidget(covariant _ConcreteTypeChoice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.owner != widget.owner || oldWidget.path != widget.path) {
      _request++;
      _pending = null;
      _diagnostics = null;
    }
  }

  Future<void> _select(ResolvedTypeRef type) async {
    final owner = widget.owner;
    if (owner == null || type == widget.selected) return;
    final request = ++_request;
    setState(() {
      _pending = type;
      _diagnostics = null;
    });
    final EditorMutationResult result;
    try {
      result = await owner.selectConcreteTypeAsync(widget.path, type);
    } on Object catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _pending = null;
        _diagnostics = [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Concrete type selection failed: $error",
            path: widget.path,
          ),
        ];
      });
      return;
    }
    if (!mounted || request != _request) return;
    setState(() {
      _pending = null;
      _diagnostics = switch (result) {
        InvalidEditorMutation(:final diagnostics) =>
          diagnostics.isEmpty
              ? [
                  TypeDiagnostic(
                    code: TypeDiagnosticCode.invalidValue,
                    message: "Concrete type could not be initialized",
                    path: widget.path,
                  ),
                ]
              : diagnostics,
        ConflictingEditorMutation() => [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Concrete type selection was superseded",
            path: widget.path,
          ),
        ],
        AppliedEditorMutation() => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AdaptiveChoiceControl<ResolvedTypeRef>(
        selected: widget.selected,
        initialization: widget.initialization,
        choices: widget.choices,
        enabled: widget.enabled && _pending == null,
        onSelected: (type) {
          if (type != null) unawaited(_select(type));
        },
      ),
      if (_pending != null)
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      if (_diagnostics case final diagnostics?)
        presentationDiagnostic(context, diagnostics),
    ],
  );
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
