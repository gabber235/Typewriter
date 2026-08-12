import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

extension CompositeInputRendering on PresentationElement {
  Widget render(BuildContext context, PresentationRenderScope scope) {
    final element = this;
    final control = switch (element) {
      ListInputElement(:final control) ||
      MapInputElement(:final control) ||
      RecordInputElement(:final control) => control,
      _ => null,
    };
    if (control == null) return const SizedBox.shrink();
    final resolved = scope.resolve(control.binding);
    if (resolved case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final binding = resolved.valueOrNull!;
    return switch ((element, binding.type, binding.value)) {
      (ListInputElement(), ListType(), ListValue()) => _ListInput(
        element: element as ListInputElement,
        binding: binding,
        scope: scope,
      ),
      (MapInputElement(), MapType(), MapValue()) =>
        (element as MapInputElement).render(binding: binding, scope: scope),
      (
        RecordInputElement(:final fieldPresentation, :final control),
        RecordType(),
        RecordValue(),
      ) =>
        fieldPresentation == null
            ? binding.renderDefaultPresentation(
                scope,
                nodeId: "record.${control.binding.bindingId.value}",
              )
            : PresentationNodeRenderer(
                node: fieldPresentation.localizeFailures(
                  scope.expressions,
                  registry: scope.registry,
                  budget: scope.budget,
                ),
                scope: scope,
              ),
      _ => presentationDiagnostic(context, [
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Composite control does not match its binding",
        ),
      ]),
    };
  }
}

class _ListInput extends StatelessWidget {
  const _ListInput({
    required this.element,
    required this.binding,
    required this.scope,
  });

  final ListInputElement element;
  final ResolvedBinding binding;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final type = binding.type as ListType;
    final value = binding.value as ListValue;
    final locked = scope.readOnly || !scope.enabled || !binding.writable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (value.values.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text("No items"),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: value.values.length,
            onReorderItem: element.allowReorder && !locked ? _reorder : null,
            itemBuilder: (context, index) => Padding(
              key: ValueKey(
                scope
                    .canonical(element.control.binding)
                    .at(DataPath.root.index(index)),
              ),
              padding: const EdgeInsets.only(bottom: 8),
              child: _itemHeader(type, index, value.values[index], locked),
            ),
          ),
      ],
    );
  }

  Widget _itemHeader(ListType type, int index, DataValue value, bool locked) {
    final source = scope
        .canonical(element.control.binding)
        .at(DataPath.root.index(index));
    final actions = [
      if (element.allowRemove)
        EditorHeaderAction(
          id: listItemRemoveHeaderActionId,
          icon: _icon("mdi:delete-outline"),
          label: "Remove item".asStringLiteral,
          priority: _integer(90),
          tone: HeaderActionTone.destructive,
          activation: InvokeHeaderAction(
            LocalEditorAction(
              RemoveListItemAction(
                target: scope.canonical(element.control.binding),
                index: _integer(index),
              ),
            ),
          ),
        ),
      EditorHeaderAction(
        id: listItemDuplicateHeaderActionId,
        icon: _icon("mdi:content-copy"),
        label: "Duplicate item".asStringLiteral,
        priority: _integer(70),
        activation: InvokeHeaderAction(
          LocalEditorAction(DuplicateListItemAction(source: source)),
        ),
      ),
      if (element.allowReorder)
        EditorHeaderAction(
          id: listItemReorderHeaderActionId,
          icon: _icon("mdi:drag"),
          label: "Reorder item".asStringLiteral,
          placement: HeaderActionPlacement.beforeTitle,
          activation: ReorderListItemHeaderAction(source: source),
        ),
    ];
    return PresentationHeaderChrome(
      nodeId: "${element.control.binding}.item.$index",
      header: PresentationHeader(
        binding: source,
        title: "Item ${index + 1}".asStringLiteral,
        initiallyExpanded: false,
        actions: actions,
      ),
      scope: scope,
      leading: element.allowReorder
          ? ReorderableDragStartListener(
              index: index,
              enabled: !locked,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icones("mdi:drag"),
              ),
            )
          : null,
      child: _item(type, index, value),
    );
  }

  Widget _item(ListType type, int index, DataValue value) {
    final reference = scope
        .canonical(element.control.binding)
        .at(DataPath.root.index(index));
    if (element.itemPresentation case final presentation?) {
      final childScope = scope
          .withAlias(
            element.itemBindingId,
            reference,
            BindingSnapshot(
              type: type.element,
              value: value,
              revision: binding.revision,
              writable: binding.writable,
            ),
          )
          .withVirtualBinding(
            element.indexBindingId,
            BindingSnapshot(
              type: const IntegerType(width: IntegerWidth.signed64),
              value: IntegerValue(BigInt.from(index)),
              revision: binding.revision,
              writable: false,
            ),
            (value) {},
          );
      final localized = presentation.localizeFailures(
        childScope.expressions,
        registry: childScope.registry,
        budget: childScope.budget,
      );
      return PresentationNodeRenderer(node: localized, scope: childScope);
    }
    return ResolvedBinding(
      reference: reference,
      type: type.element,
      value: value,
      revision: binding.revision,
      writable: binding.writable,
    ).renderDefaultPresentation(
      scope,
      nodeId: "list.${element.control.binding.bindingId.value}.$index",
    );
  }

  void _reorder(int source, int destination) => scope.invoke(
    LocalEditorAction(
      ReorderListItemAction(
        source: scope
            .canonical(element.control.binding)
            .at(DataPath.root.index(source)),
        newIndex: _integer(destination),
      ),
    ),
  );
}

TypedExpression _integer(int value) => TypedExpression(
  resultType: const IntegerType(width: IntegerWidth.signed64),
  expression: LiteralExpression(IntegerValue(BigInt.from(value))),
);

TypedExpression _icon(String value) => TypedExpression(
  resultType: NamedType(standardTypeRefs.icon),
  expression: LiteralExpression(IconValue.iconify(value).typedValue),
);
