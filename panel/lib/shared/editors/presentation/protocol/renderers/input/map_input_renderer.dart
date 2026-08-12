part of "../../composite_input_renderer.dart";

extension MapInputElementRendering on MapInputElement {
  Widget render({
    required ResolvedBinding binding,
    required PresentationRenderScope scope,
  }) => _MapInput(element: this, binding: binding, scope: scope);
}

class _MapInput extends StatelessWidget {
  const _MapInput({
    required this.element,
    required this.binding,
    required this.scope,
  });

  final MapInputElement element;
  final ResolvedBinding binding;
  final PresentationRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final type = binding.type as MapType;
    final value = binding.value as MapValue;
    final locked = scope.readOnly || !scope.enabled || !binding.writable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (value.entries.isEmpty)
          const _CollectionEmptyState(message: "No entries found"),
        for (final entry in value.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _entry(type, value, entry, locked),
          ),
      ],
    );
  }

  Widget _entry(MapType type, MapValue map, DataMapEntry entry, bool locked) {
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
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 160, child: _key(type, map, entry)),
        const SizedBox(width: 8),
        Expanded(child: _item(type, entry, itemScope)),
      ],
    );
    final hasDeclaredHeader =
        element.keyPresentation?.header != null || valueHeader != null;
    if (!element.allowRemove && !hasDeclaredHeader) return content;
    final standardHeader = PresentationHeader(
      binding: reference,
      title: entry.key.expressionDisplayText.asStringLiteral,
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
      nodeId: "${element.control.binding}.entry.${entry.key.hashCode}",
      header: effectiveHeader,
      scope: scope,
      child: content,
    );
  }

  Widget _key(MapType type, MapValue map, DataMapEntry entry) {
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
      nodeId: "map.key.${entry.key.hashCode}",
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
    DataMapEntry entry,
    PresentationRenderScope? itemScope,
  ) {
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
      nodeId: "map.value.${entry.key.hashCode}",
      root: true,
    );
  }
}
