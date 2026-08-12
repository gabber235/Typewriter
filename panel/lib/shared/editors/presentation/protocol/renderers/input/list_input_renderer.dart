part of "../../composite_input_renderer.dart";

extension ListInputElementRendering on ListInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => _ListInputRenderer(element: this, binding: binding, scope: scope);
}

class _ListInputRenderer extends StatelessWidget {
  const _ListInputRenderer({
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
    if (value.values.isEmpty) {
      return const _CollectionEmptyState(message: "No items found");
    }
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: value.values.length,
      onReorderItem: element.allowReorder && !locked
          ? _reorder
          : _ignoreReorder,
      itemBuilder: (context, index) => Padding(
        key: ValueKey(
          scope
              .canonical(element.control.binding)
              .at(DataPath.root.index(index)),
        ),
        padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
        child: _itemHeader(type, index, value.values[index]),
      ),
    );
  }

  Widget _itemHeader(ListType type, int index, DataValue value) {
    final source = scope
        .canonical(element.control.binding)
        .at(DataPath.root.index(index));
    final items = [
      if (element.allowRemove)
        HeaderButtonItem(
          id: listItemRemoveHeaderItemId,
          icon: HeroiconsSolid.trash.asIconLiteral,
          label: "Remove item".asStringLiteral,
          priority: (-0x8000000000000000).asSigned64Literal,
          tone: HeaderActionTone.destructive,
          confirmation: HeaderActionConfirmation(
            title: "Remove item?".asStringLiteral,
            message:
                "Are you sure you want to remove this item?".asStringLiteral,
            confirmationLabel: "Remove".asStringLiteral,
          ),
          action: LocalEditorAction(
            RemoveListItemAction(
              target: scope.canonical(element.control.binding),
              index: index.asSigned64Literal,
            ),
          ),
        ),
      HeaderButtonItem(
        id: listItemDuplicateHeaderItemId,
        icon: Ion.duplicate.asIconLiteral,
        label: "Duplicate item".asStringLiteral,
        priority: 70.asSigned64Literal,
        action: LocalEditorAction(DuplicateListItemAction(source: source)),
      ),
      if (element.allowReorder)
        HeaderReorderHandleItem(
          id: listItemReorderHeaderItemId,
          label: "Reorder item".asStringLiteral,
          source: source,
        ),
    ];
    return PresentationHeaderChrome(
      nodeId: "${element.control.binding}.item.$index",
      header: PresentationHeader(
        binding: source,
        title: "Item ${index + 1}".asStringLiteral,
        initiallyExpanded: false,
        items: items,
      ),
      scope: scope,
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
      root: true,
    );
  }

  void _reorder(int source, int destination) => scope.invoke(
    LocalEditorAction(
      ReorderListItemAction(
        source: scope
            .canonical(element.control.binding)
            .at(DataPath.root.index(source)),
        newIndex: destination.asSigned64Literal,
      ),
    ),
  );

  void _ignoreReorder(int source, int destination) {}
}
