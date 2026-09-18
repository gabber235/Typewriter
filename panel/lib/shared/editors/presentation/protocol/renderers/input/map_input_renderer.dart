part of "../../composite_input_renderer.dart";

/// Renders map keys and values as virtual child bindings.
///
/// Key edits are rejected when they would create a duplicate, then the whole
/// map is submitted through the owning scope. Entry identities are maintained
/// separately so header expansion follows a key across rebuilt map entries.
extension MapInputElementRendering on MapInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => _MapInput(element: this, binding: binding, scope: scope);
}

final class _DraftMapInput extends StatelessWidget {
  const _DraftMapInput({
    required this.element,
    required this.binding,
    required this.scope,
    required this.owner,
    required this.structure,
  });

  final MapInputElement element;
  final InspectedBinding binding;
  final PresentationRenderScope scope;
  final EditorStructureOwner owner;
  final EditorMapStructure structure;

  @override
  Widget build(BuildContext context) {
    final type = binding.type as MapType;
    final mapReference = scope.canonical(element.control.binding);
    if (structure.entries.isEmpty) {
      return const _CollectionEmptyState(message: "No entries found");
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final indexed in structure.entries.indexed)
          Padding(
            key: ValueKey(indexed.$2.id),
            padding: EdgeInsets.only(bottom: context.spacing.space2),
            child: PresentationHeaderChrome(
              nodeId: "${element.control.binding}.draft.${indexed.$2.id.value}",
              expansionKey: HeaderExpansionKey.instance(indexed.$2.id.value),
              header: PresentationHeader(
                binding: element.control.binding,
                title:
                    "Map entry ${indexed.$1 + 1}".asStringLiteral.asHeaderTitle,
                initiallyExpanded: true,
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
                              target: element.control.binding,
                              key: indexed.$2.id.value.asSigned64Literal,
                            ),
                          ),
                        ),
                      ]
                    : const [],
              ),
              scope: scope,
              subtreeDiagnostics: indexed.$2.diagnostics,
              child: _entry(type, mapReference.path, indexed.$2),
            ),
          ),
      ],
    );
  }

  Widget _entry(MapType type, DataPath mapPath, EditorMapEntryStructure entry) {
    const keyId = BindingId(2147483645);
    const valueId = BindingId(2147483646);
    final keyHost = VirtualBindingHost.editorValue(
      id: keyId,
      type: type.key,
      value: entry.key,
      revision: binding.revision,
      writable: binding.writable,
      onChanged: (next) => owner.updateMapKey(mapPath, entry.id, next),
      interactionTarget: scope.canonical(element.control.binding),
    );
    final valueHost = VirtualBindingHost.editorValue(
      id: valueId,
      type: type.value,
      value: entry.value,
      revision: binding.revision,
      writable: binding.writable,
      onChanged: (next) => owner.updateMapValue(mapPath, entry.id, next),
      interactionTarget: scope.canonical(element.control.binding),
    );
    final childScope = scope
        .withVirtualBinding(keyHost, source: element.control.binding)
        .withVirtualBinding(valueHost, source: element.control.binding);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _MapEntryField(
          label: element.keyPresentation == null ? null : "Key",
          value: false,
          child: PresentationFieldDiagnostics(
            bindingId: keyId,
            sourcePath: DataPath.root,
            diagnostics: entry.keyDiagnostics,
            child: element.keyPresentation != null
                ? PresentationNodeRenderer(
                    node: element.keyPresentation!.localizeFailures(
                      childScope.expressions,
                      registry: childScope.registry,
                      budget: childScope.budget,
                    ),
                    scope: childScope.withAlias(
                      element.keyBindingId,
                      const BindingReference(bindingId: keyId),
                      keyHost,
                    ),
                  )
                : InspectedBinding(
                    reference: const BindingReference(bindingId: keyId),
                    type: type.key,
                    value: entry.key,
                    revision: binding.revision,
                    writable: binding.writable,
                  ).renderDefaultPresentation(
                    childScope,
                    nodeId: "map.key.${entry.id.value}",
                    label: "Key",
                  ),
          ),
        ),
        _MapEntryField(
          label: element.valuePresentation == null ? null : "Value",
          value: true,
          child: PresentationFieldDiagnostics(
            bindingId: valueId,
            sourcePath: DataPath.root,
            diagnostics: entry.valueDiagnostics,
            child: element.valuePresentation != null
                ? PresentationNodeRenderer(
                    node: element.valuePresentation!.localizeFailures(
                      childScope.expressions,
                      registry: childScope.registry,
                      budget: childScope.budget,
                    ),
                    scope: childScope.withAlias(
                      element.valueBindingId,
                      const BindingReference(bindingId: valueId),
                      valueHost,
                    ),
                  )
                : InspectedBinding(
                    reference: const BindingReference(bindingId: valueId),
                    type: type.value,
                    value: entry.value,
                    revision: binding.revision,
                    writable: binding.writable,
                  ).renderDefaultPresentation(
                    childScope,
                    nodeId: "map.value.${entry.id.value}",
                    root: true,
                    label: "Value",
                  ),
          ),
        ),
      ],
    );
  }
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
        previousStore.remove(HeaderExpansionKey.instance(slot.identity));
      }
    }
    _slots = next;
  }

  @override
  void dispose() {
    for (final slot in _slots) {
      scope.expansionStore.remove(HeaderExpansionKey.instance(slot.identity));
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
            padding: EdgeInsets.only(bottom: context.spacing.space2),
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
        : _valueScope(type, entry);
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
      title: (switch (entry.key) {
        IntegerValue() => "Map entry".asStringLiteral,
        _ => entry.key.expressionDisplayText.asStringLiteral,
      }).asHeaderTitle,
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
      expansionKey: HeaderExpansionKey.instance(slot.identity),
      header: effectiveHeader,
      scope: scope,
      child: content,
    );
  }

  Widget _key(MapType type, MapValue map, _MapEntrySlot slot) {
    final entry = slot.entry;
    if (element.keyPresentation case final presentation?) {
      final childScope = scope.withVirtualBinding(
        VirtualBindingHost(
          id: element.keyBindingId,
          snapshot: BindingSnapshot(
            type: type.key,
            value: entry.key,
            revision: binding.revision,
            writable: binding.writable,
          ),
          onChanged: (next) => _replaceKey(map, entry.key, next),
          interactionTarget: scope.canonical(element.control.binding),
        ),
        source: element.control.binding,
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
      VirtualBindingHost(
        id: element.keyBindingId,
        snapshot: BindingSnapshot(
          type: type.key,
          value: entry.key,
          revision: binding.revision,
          writable: binding.writable,
        ),
        onChanged: (next) => _replaceKey(map, entry.key, next),
        interactionTarget: scope.canonical(element.control.binding),
      ),
      source: element.control.binding,
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

  PresentationRenderScope _valueScope(MapType type, DataMapEntry entry) =>
      scope.withAlias(
        element.valueBindingId,
        element.control.binding.at(DataPath.root.mapKey(entry.key)),
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
      final childScope = itemScope ?? _valueScope(type, entry);
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
