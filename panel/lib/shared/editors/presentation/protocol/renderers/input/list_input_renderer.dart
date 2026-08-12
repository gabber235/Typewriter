part of "../../composite_input_renderer.dart";

extension ListInputElementRendering on ListInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => _ListInputRenderer(element: this, binding: binding, scope: scope);
}

class _ListInputRenderer extends StatefulWidget {
  const _ListInputRenderer({
    required this.element,
    required this.binding,
    required this.scope,
  });

  final ListInputElement element;
  final ResolvedBinding binding;
  final PresentationRenderScope scope;

  @override
  State<_ListInputRenderer> createState() => _ListInputRendererState();
}

class _ListInputRendererState extends State<_ListInputRenderer> {
  late List<DataValue> _previousValues;
  late List<_ListItemIdentity> _identities;

  @override
  void initState() {
    super.initState();
    final value = widget.binding.value as ListValue;
    _previousValues = value.values;
    _identities = _newIdentities(value.values.length);
  }

  @override
  void didUpdateWidget(_ListInputRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope.expansionStore != widget.scope.expansionStore) {
      _removeExpansionState(oldWidget.scope.expansionStore, _identities);
    }

    final value = widget.binding.value as ListValue;
    final reconciled = _reconcileIdentities(
      _previousValues,
      value.values,
      _identities,
    );
    for (final identity in _identities) {
      if (!reconciled.contains(identity)) {
        widget.scope.expansionStore.remove(identity);
      }
    }
    _identities = reconciled;
    _previousValues = value.values;
  }

  @override
  void dispose() {
    _removeExpansionState(widget.scope.expansionStore, _identities);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final element = widget.element;
    final binding = widget.binding;
    final scope = widget.scope;
    final type = binding.type as ListType;
    final value = binding.value as ListValue;

    final locked = scope.readOnly || !scope.enabled || !binding.writable;
    final currentDepth = DepthContainer.maybeOf(context)?.depth ?? 0;
    if (value.values.isEmpty) {
      return const _CollectionEmptyState(message: "No items found");
    }

    final itemScope = _trackReorders();

    ValueKey<_ListItemIdentity> key(int index) => ValueKey(_identities[index]);

    Widget child(int index) => Padding(
      key: key(index),
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
      child: _itemHeader(
        type,
        index,
        value.values[index],
        _identities[index],
        itemScope,
      ),
    );

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: value.values.length,
      onReorderItem: element.allowReorder && !locked
          ? (source, destination) => itemScope.invoke(
              LocalEditorAction(
                ReorderListItemAction(
                  source: scope
                      .canonical(element.control.binding)
                      .at(DataPath.root.index(source)),
                  newIndex: destination.asSigned64Literal,
                ),
              ),
            )
          : _ignoreReorder,
      proxyDecorator: (child, index, animation) => AnimatedBuilder(
        animation: animation,
        child: DepthContainer(depth: currentDepth, child: child),
        builder: (context, child) => Transform.scale(
          scale: 1 + (animation.value * 0.03),
          child: Material(
            color: Colors.transparent,
            shadowColor: Theme.of(context).colorScheme.shadow,
            elevation: animation.value * 12,
            borderRadius: context.shapes.mediumBorderRadius,
            child: child,
          ),
        ),
      ),
      itemBuilder: (context, index) => child(index),
    );
  }

  Widget _itemHeader(
    ListType type,
    int index,
    DataValue value,
    _ListItemIdentity identity,
    PresentationRenderScope itemScope,
  ) {
    final source = itemScope
        .canonical(widget.element.control.binding)
        .at(DataPath.root.index(index));
    final items = [
      if (widget.element.allowRemove)
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
              target: widget.scope.canonical(widget.element.control.binding),
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
      if (widget.element.allowReorder)
        HeaderReorderHandleItem(
          id: listItemReorderHeaderItemId,
          label: "Reorder item".asStringLiteral,
          source: source,
        ),
    ];
    return PresentationHeaderChrome(
      nodeId: "${widget.element.control.binding}.item.$index",
      expansionIdentity: identity,
      header: PresentationHeader(
        binding: source,
        title: "Item ${index + 1}".asStringLiteral,
        initiallyExpanded: false,
        items: items,
      ),
      scope: itemScope,
      child: _item(type, index, value, itemScope),
    );
  }

  Widget _item(
    ListType type,
    int index,
    DataValue value,
    PresentationRenderScope itemScope,
  ) {
    final reference = itemScope
        .canonical(widget.element.control.binding)
        .at(DataPath.root.index(index));
    if (widget.element.itemPresentation case final presentation?) {
      final childScope = itemScope
          .withAlias(
            widget.element.itemBindingId,
            reference,
            BindingSnapshot(
              type: type.element,
              value: value,
              revision: widget.binding.revision,
              writable: widget.binding.writable,
            ),
          )
          .withVirtualBinding(
            widget.element.indexBindingId,
            BindingSnapshot(
              type: const IntegerType(width: IntegerWidth.signed64),
              value: IntegerValue(BigInt.from(index)),
              revision: widget.binding.revision,
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
      revision: widget.binding.revision,
      writable: widget.binding.writable,
    ).renderDefaultPresentation(
      itemScope,
      nodeId: "list.${widget.element.control.binding.bindingId.value}.$index",
      root: true,
      label: "",
    );
  }

  PresentationRenderScope _trackReorders() => widget.scope.copyWith(
    executeAction: (action, context, aliases) {
      if (action case LocalEditorAction(
        action: final ReorderListItemAction reorder,
      )) {
        final canonical =
            LocalEditorAction(reorder).canonicalizedWith(aliases).action
                as ReorderListItemAction;
        final source = _listItemIndex(
          canonical.source,
          widget.scope.canonical(widget.element.control.binding),
        );
        final destination = canonical.newIndex
            .evaluate(
              context,
              registry: widget.scope.registry,
              budget: widget.scope.budget,
            )
            .valueOrNull;
        if (source != null && destination is IntegerValue) {
          _identities = _moveIdentity(
            _identities,
            source,
            destination.value.toInt(),
          );
        }
      }
      widget.scope.executeAction(action, context, aliases);
    },
  );

  void _ignoreReorder(int source, int destination) {}
}

final class _ListItemIdentity {}

void _removeExpansionState(
  HeaderExpansionStore store,
  List<_ListItemIdentity> identities,
) {
  for (final identity in identities) {
    store.remove(identity);
  }
}

List<_ListItemIdentity> _newIdentities(int count) =>
    List.generate(count, (_) => _ListItemIdentity(), growable: false);

List<_ListItemIdentity> _reconcileIdentities(
  List<DataValue> previous,
  List<DataValue> current,
  List<_ListItemIdentity> identities,
) {
  if (current.length == identities.length) return identities;

  var prefixLength = 0;
  while (prefixLength < previous.length &&
      prefixLength < current.length &&
      previous[prefixLength] == current[prefixLength]) {
    prefixLength++;
  }

  var suffixLength = 0;
  while (suffixLength < previous.length - prefixLength &&
      suffixLength < current.length - prefixLength &&
      previous[previous.length - suffixLength - 1] ==
          current[current.length - suffixLength - 1]) {
    suffixLength++;
  }

  return [
    ...identities.take(prefixLength),
    ..._newIdentities(current.length - prefixLength - suffixLength),
    ...identities.skip(identities.length - suffixLength),
  ];
}

List<_ListItemIdentity> _moveIdentity(
  List<_ListItemIdentity> identities,
  int source,
  int destination,
) {
  if (source < 0 ||
      source >= identities.length ||
      destination < 0 ||
      destination >= identities.length ||
      source == destination) {
    return identities;
  }
  final reordered = identities.toList();
  final identity = reordered.removeAt(source);
  reordered.insert(destination, identity);
  return reordered;
}

int? _listItemIndex(BindingReference item, BindingReference list) {
  if (item.bindingId != list.bindingId || item.path.segments.isEmpty) {
    return null;
  }
  final segments = item.path.segments;
  if (segments.last case IndexPathSegment(:final index)) {
    final parent = DataPath(segments.sublist(0, segments.length - 1));
    if (parent == list.path) return index;
  }
  return null;
}
