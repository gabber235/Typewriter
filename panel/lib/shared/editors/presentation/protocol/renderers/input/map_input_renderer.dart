part of "../../composite_input_renderer.dart";

extension MapInputElementRendering on MapInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => _MapInput(element: this, binding: binding, scope: scope);
}

class _MapInput extends StatefulWidget {
  const _MapInput({
    required this.element,
    required this.binding,
    required this.scope,
  });

  final MapInputElement element;
  final ResolvedBinding binding;
  final PresentationRenderScope scope;

  @override
  State<_MapInput> createState() => _MapInputState();
}

class _MapInputState extends State<_MapInput> {
  final _entryTracker = _MapEntryTracker();
  late List<_MapEntrySlot> _slots;

  MapInputElement get element => widget.element;
  ResolvedBinding get binding => widget.binding;
  PresentationRenderScope get scope => widget.scope;

  @override
  void initState() {
    super.initState();
    final map = binding.value as MapValue;
    _slots = _entryTracker.initialize(map.entries);
  }

  @override
  void didUpdateWidget(_MapInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final map = binding.value as MapValue;
    final previous = _slots;
    final next = _entryTracker.reconcile(previous, map.entries);
    final nextIdentities = {for (final slot in next) slot.identity};
    final previousStore = oldWidget.scope.expansionStore;
    for (final slot in previous) {
      if (!identical(previousStore, scope.expansionStore) ||
          !nextIdentities.contains(slot.identity)) {
        previousStore.remove(slot.identity);
      }
    }
    _slots = next;
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      scope.expansionStore.remove(slot.identity);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = binding.type as MapType;
    final value = binding.value as MapValue;
    assert(_slots.length == value.entries.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_slots.isEmpty)
          const _CollectionEmptyState(message: "No entries found"),
        for (final slot in _slots)
          Padding(
            key: ObjectKey(slot.identity),
            padding: const EdgeInsets.only(bottom: 8),
            child: _entry(context, type, value, slot),
          ),
      ],
    );
  }

  Widget _entry(
    BuildContext context,
    MapType type,
    MapValue map,
    _MapEntrySlot slot,
  ) {
    final entry = slot.entry;
    final reference = scope
        .canonical(element.control.binding)
        .at(DataPath.root.mapKey(entry.key));
    final valueScope = element.valuePresentation == null
        ? null
        : _valueScope(type, entry, reference);
    final valueChain = valueScope == null
        ? null
        : element.valuePresentation!.resolveHeaderChain(valueScope);
    final valueHeader = valueChain?.header;
    final valueHeaderBinding = valueHeader?.binding == null
        ? null
        : valueScope!.canonical(valueHeader!.binding!);
    final absorbedValueHeader = valueHeaderBinding == reference
        ? valueHeader
        : null;
    final itemScope = absorbedValueHeader == null
        ? valueScope
        : valueScope!.copyWith(
            suppressedHeaders: {
              ...valueScope.suppressedHeaders,
              ...valueChain!.suppressed,
              (element.valuePresentation!.id, reference),
            },
          );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space2,
      children: [
        _MapEntryField(
          label: element.keyPresentation == null ? null : "Key",
          value: false,
          child: _key(type, map, slot),
        ),
        _MapEntryField(
          label: element.valuePresentation == null ? null : "Value",
          value: true,
          child: _item(type, slot, itemScope),
        ),
      ],
    );
    final hasDeclaredHeader =
        element.keyPresentation?.header != null || valueHeader != null;
    if (!element.allowRemove && !hasDeclaredHeader) return content;
    final standardHeader = PresentationHeader(
      binding: reference,
      title: switch (entry.key) {
        IntegerValue() => "Map entry".asStringLiteral,
        _ => entry.key.expressionDisplayText.asStringLiteral,
      },
      initiallyExpanded: false,
      items: element.allowRemove
          ? [
              HeaderButtonItem(
                id: mapEntryRemoveHeaderItemId,
                icon: HeroiconsSolid.trash.asIconLiteral,
                label: "Remove entry".asStringLiteral,
                priority: (-0x8000000000000000).asSigned64Literal,
                tone: HeaderActionTone.destructive,
                action: LocalEditorAction(
                  RemoveMapEntryAction(
                    target: scope.canonical(element.control.binding),
                    key: TypedExpression(
                      resultType: type.key,
                      expression: LiteralExpression(entry.key),
                    ),
                  ),
                ),
              ),
            ]
          : const [],
    );
    final effectiveHeader = absorbedValueHeader == null
        ? standardHeader
        : absorbedValueHeader
              .mergeInner(standardHeader)
              .copyWith(
                binding: reference,
                title: absorbedValueHeader.title ?? standardHeader.title,
                initiallyExpanded:
                    absorbedValueHeader.initiallyExpanded ??
                    standardHeader.initiallyExpanded,
              );
    return PresentationHeaderChrome(
      nodeId: "${element.control.binding}.entry.${slot.identity.id}",
      header: effectiveHeader,
      scope: scope,
      expansionIdentity: slot.identity,
      child: content,
    );
  }

  Widget _key(MapType type, MapValue map, _MapEntrySlot slot) {
    final entry = slot.entry;
    if (element.keyPresentation case final presentation?) {
      final childScope = scope.withVirtualBinding(
        element.keyBindingId,
        BindingSnapshot(
          type: type.key,
          value: entry.key,
          revision: binding.revision,
          writable: binding.writable,
        ),
        (next) => _replaceKey(map, entry.key, next),
      );
      final localized = presentation.localizeFailures(
        childScope.expressions,
        registry: childScope.registry,
        budget: childScope.budget,
      );
      return PresentationNodeRenderer(node: localized, scope: childScope);
    }
    final reference = BindingReference(bindingId: element.keyBindingId);
    final childScope = scope.withVirtualBinding(
      element.keyBindingId,
      BindingSnapshot(
        type: type.key,
        value: entry.key,
        revision: binding.revision,
        writable: binding.writable,
      ),
      (next) => _replaceKey(map, entry.key, next),
    );
    return ResolvedBinding(
      reference: reference,
      type: type.key,
      value: entry.key,
      revision: binding.revision,
      writable: binding.writable,
    ).renderDefaultPresentation(
      childScope,
      nodeId: "map.key.${slot.identity.id}",
      label: "Key",
    );
  }

  void _replaceKey(MapValue map, DataValue previous, DataValue next) {
    if (previous == next) return;
    if (map.entries.any((entry) => entry.key == next)) return;
    final entries = [
      for (final entry in map.entries)
        if (entry.key == previous)
          DataMapEntry(key: next, value: entry.value)
        else
          entry,
    ];
    scope.update(element.control.binding, MapValue(entries.toList()));
  }

  PresentationRenderScope _valueScope(
    MapType type,
    DataMapEntry entry,
    BindingReference reference,
  ) => scope.withAlias(
    element.valueBindingId,
    reference,
    BindingSnapshot(
      type: type.value,
      value: entry.value,
      revision: binding.revision,
      writable: binding.writable,
    ),
  );

  Widget _item(
    MapType type,
    _MapEntrySlot slot,
    PresentationRenderScope? itemScope,
  ) {
    final entry = slot.entry;
    final reference = scope
        .canonical(element.control.binding)
        .at(DataPath.root.mapKey(entry.key));
    if (element.valuePresentation case final presentation?) {
      final childScope = itemScope ?? _valueScope(type, entry, reference);
      final localized = presentation.localizeFailures(
        childScope.expressions,
        registry: childScope.registry,
        budget: childScope.budget,
      );
      return PresentationNodeRenderer(node: localized, scope: childScope);
    }
    return ResolvedBinding(
      reference: reference,
      type: type.value,
      value: entry.value,
      revision: binding.revision,
      writable: binding.writable,
    ).renderDefaultPresentation(
      scope,
      nodeId: "map.value.${slot.identity.id}",
      root: true,
      label: "Value",
    );
  }
}
