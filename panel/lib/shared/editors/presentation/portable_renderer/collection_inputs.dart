part of "../portable_presentation_renderer.dart";

extension _PortableCollectionInputRendering
    on PortablePresentationNodeRenderer {
  Widget _renderListInput(
    BuildContext context,
    skir.ListControl control,
    PortablePresentationScope childScope,
  ) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBindingId: control.itemBindingId,
    indexBindingId: control.indexBindingId,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: control.allowReorder,
    childScope: childScope,
    appearance: control.appearance,
    content: control.content,
  );

  Widget _renderSetInput(
    BuildContext context,
    skir.SetControl control,
    PortablePresentationScope childScope,
  ) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBindingId: control.itemBindingId,
    indexBindingId: null,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: false,
    childScope: childScope,
    appearance: control.appearance,
    content: control.content,
  );

  Widget _renderSequenceInput({
    required BuildContext context,
    required skir.BoundControl control,
    required skir.PresentationNode? itemPresentation,
    required skir.ExpressionBindingId itemBindingId,
    required skir.ExpressionBindingId? indexBindingId,
    required bool allowAdd,
    required bool allowRemove,
    required bool allowReorder,
    required PortablePresentationScope childScope,
    required skir.CollectionAppearance? appearance,
    required skir.CollectionContent? content,
  }) {
    final current = childScope.read(control.binding);
    final items =
        current?.authoredItems?.toList() ??
        (current?.authoredPayload == skir.DataValue.unfilled
            ? <skir.ListItem>[]
            : null);
    final collection = childScope.location(control.binding);
    if (items == null || collection == null) {
      return _diagnostic("The collection binding is unavailable");
    }
    Widget item(int index) {
      final current = items[index];
      final reference = skir.BindingRef(
        bindingId: control.binding.bindingId,
        path: skir.ValuePath(
          segments: [
            ...control.binding.path.segments,
            skir.PathSegment.createItem(id: current.id),
          ],
        ),
      );
      var itemScope = childScope.withBinding(reference, itemBindingId);
      if (itemScope == null) {
        return _diagnostic(
          "Collection item ${current.id.value} is unavailable",
        );
      }
      if (indexBindingId != null) {
        itemScope = itemScope.withValues({
          indexBindingId: skir.DataValue.wrapInteger(index.toString()),
        });
      }
      final itemContent = itemPresentation == null
          ? Text(current.value.authoredString ?? current.id.value)
          : PortablePresentationNodeRenderer(
              node: itemPresentation,
              scope: itemScope,
            );
      final presentationOwnsHandle =
          itemPresentation?.header?.items.any(
            (item) => item is skir.HeaderItem_reorderHandleWrapper,
          ) ??
          false;
      return Padding(
        key: ValueKey(current.id.value),
        padding: EdgeInsets.only(
          bottom: _collectionSpacing(context, appearance),
        ),
        child: _collectionSurface(
          context,
          appearance,
          childScope,
          node,
          Padding(
            padding: appearance?.itemPadding == null
                ? EdgeInsets.all(context.spacing.space2)
                : _presentationInsets(appearance!.itemPadding),
            child: Row(
              children: [
                if (allowReorder && !presentationOwnsHandle)
                  _AuthoredReorderHandle(
                    index: index,
                    label: "Reorder ${current.id.value}",
                    enabled: childScope.enabled && !childScope.readOnly,
                    canMoveEarlier: index > 0,
                    canMoveLater: index < items.length - 1,
                    icon: _operationGlyph(
                      content?.reorderIcon,
                      childScope,
                      const Icon(Icons.drag_handle),
                    ),
                    onMoveEarlier: () {
                      final after = index == 1 ? null : items[index - 2].id;
                      childScope.moveListItem(
                        control.binding,
                        current.id,
                        after,
                      );
                    },
                    onMoveLater: () {
                      childScope.moveListItem(
                        control.binding,
                        current.id,
                        items[index + 1].id,
                      );
                    },
                  ),
                Expanded(child: itemContent),
                if (allowRemove)
                  _operationAppearance(
                    content,
                    childScope,
                    (states, style) => IconButton(
                      statesController: states,
                      style: style,
                      tooltip: _operationText(
                        childScope,
                        content?.operationTooltip ?? content?.removeLabel,
                        "Remove item",
                      ),
                      onPressed: childScope.enabled && !childScope.readOnly
                          ? () {
                              childScope.removeListItem(
                                control.binding,
                                current.id,
                              );
                            }
                          : null,
                      icon: _operationGlyph(
                        content?.removeIcon,
                        childScope,
                        const Icon(Icons.delete_outline),
                      ),
                    ),
                    tooltip: false,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final list = allowReorder
        ? ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (_, index) => item(index),
            onReorderItem: childScope.enabled && !childScope.readOnly
                ? (from, to) {
                    final moving = items[from];
                    final remaining = [...items]..removeAt(from);
                    final after = to == 0 ? null : remaining[to - 1].id;
                    childScope.moveListItem(control.binding, moving.id, after);
                  }
                : (_, _) {},
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < items.length; index++) item(index),
            ],
          );
    final linkControl = switch (itemPresentation?.element) {
      skir.PresentationElement_linkInputWrapper(:final value) => value,
      _ => null,
    };
    return _decorateCollection(
      control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (items.isEmpty)
            _collectionEmpty(context, childScope, content, "No items"),
          list,
          if (allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _operationAppearance(
                content,
                childScope,
                (states, style) => FilledButton.icon(
                  statesController: states,
                  onPressed: childScope.enabled && !childScope.readOnly
                      ? () => unawaited(
                          _addSequenceItem(
                            context: context,
                            control: control,
                            linkControl: linkControl,
                            collection: collection,
                            childScope: childScope,
                          ),
                        )
                      : null,
                  style: style,
                  icon: _operationGlyph(
                    content?.addIcon,
                    childScope,
                    Icon(linkControl == null ? Icons.add : Icons.add_link),
                  ),
                  label: Text(
                    _operationText(
                      childScope,
                      content?.addLabel,
                      linkControl == null ? "Add item" : "Add link",
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _addSequenceItem({
    required BuildContext context,
    required skir.BoundControl control,
    required skir.LinkControl? linkControl,
    required skir.ValueLocation collection,
    required PortablePresentationScope childScope,
  }) async {
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    final itemLocation = skir.ValueLocation(
      resource: collection.resource,
      path: skir.ValuePath(
        segments: [
          ...collection.path.segments,
          skir.PathSegment.createItem(id: item),
        ],
      ),
    );
    if (linkControl != null) {
      Map<skir.ResourceId, _AuthoredCollectionRow>? candidates;
      skir.PresentationCollectionDefinition? candidateDefinition;
      if (linkControl.sourceId case final sourceId?) {
        final resolved = _authoredCollection(sourceId, childScope);
        if (resolved.problem != null) {
          childScope.reportStatus?.call(resolved.problem!);
          return;
        }
        candidateDefinition = resolved.definition;
        candidates = {
          for (final row in resolved.rows)
            if (row.selectable) row.resource: row,
        };
      }
      await _chooseLink(
        context: context,
        scope: childScope,
        control: linkControl,
        location: itemLocation,
        candidates: candidates,
        candidateDefinition: candidateDefinition,
      );
      return;
    }
    await childScope.addCollectionItem(control.binding);
  }

  Widget _renderMapInput(
    BuildContext context,
    skir.MapControl control,
    PortablePresentationScope childScope,
  ) {
    final current = childScope.read(control.control.binding);
    final value = current?.authoredPayload;
    final rows = switch (value) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      _ when value == skir.DataValue.unfilled => <skir.MapRow>[],
      _ => null,
    };
    final collection = childScope.location(control.control.binding);
    if (rows == null || collection == null) {
      return _diagnostic("The map binding is unavailable");
    }
    return _decorateCollection(
      control.control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rows.isEmpty)
            _collectionEmpty(
              context,
              childScope,
              control.content,
              "No entries",
            ),
          for (final row in rows)
            _renderMapRow(context, control, row, collection, childScope),
          if (control.allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: _operationAppearance(
                control.content,
                childScope,
                (states, style) => FilledButton.icon(
                  statesController: states,
                  onPressed: childScope.enabled && !childScope.readOnly
                      ? () => childScope.addMapRow(control.control.binding)
                      : null,
                  style: style,
                  icon: _operationGlyph(
                    control.content?.addIcon,
                    childScope,
                    const Icon(Icons.add),
                  ),
                  label: Text(
                    _operationText(
                      childScope,
                      control.content?.addLabel,
                      "Add entry",
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _renderMapRow(
    BuildContext context,
    skir.MapControl control,
    skir.MapRow row,
    skir.ValueLocation collection,
    PortablePresentationScope childScope,
  ) {
    final base = [
      ...control.control.binding.path.segments,
      skir.PathSegment.createItem(id: row.id),
    ];
    final keyReference = skir.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: skir.ValuePath(segments: [...base, skir.PathSegment.mapKey]),
    );
    final valueReference = skir.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: skir.ValuePath(segments: [...base, skir.PathSegment.mapValue]),
    );
    final keyScope = childScope.withBinding(keyReference, control.keyBindingId);
    final valueScope = childScope.withBinding(
      valueReference,
      control.valueBindingId,
    );
    if (keyScope == null || valueScope == null) {
      return _diagnostic("Map row ${row.id.value} is unavailable");
    }
    return Padding(
      key: ValueKey(row.id.value),
      padding: EdgeInsets.only(
        bottom: _collectionSpacing(context, control.appearance),
      ),
      child: _collectionSurface(
        context,
        control.appearance,
        childScope,
        node,
        Padding(
          padding: control.appearance?.itemPadding == null
              ? EdgeInsets.all(context.spacing.space2)
              : _presentationInsets(control.appearance!.itemPadding),
          child: Row(
            children: [
              Expanded(
                child: _mapGuidance(
                  childScope,
                  control.content?.keyLabel,
                  control.keyPresentation == null
                      ? Text(row.key.authoredString ?? "Key")
                      : PortablePresentationNodeRenderer(
                          node: control.keyPresentation!,
                          scope: keyScope,
                        ),
                ),
              ),
              SizedBox(width: context.spacing.space2),
              Expanded(
                child: _mapGuidance(
                  childScope,
                  control.content?.valueLabel,
                  control.valuePresentation == null
                      ? Text(row.value.authoredString ?? "Value")
                      : PortablePresentationNodeRenderer(
                          node: control.valuePresentation!,
                          scope: valueScope,
                        ),
                ),
              ),
              if (control.allowRemove)
                _operationAppearance(
                  control.content,
                  childScope,
                  (states, style) => IconButton(
                    statesController: states,
                    style: style,
                    tooltip: _operationText(
                      childScope,
                      control.content?.operationTooltip ??
                          control.content?.removeLabel,
                      "Remove row",
                    ),
                    onPressed: childScope.enabled && !childScope.readOnly
                        ? () {
                            childScope.removeMapRow(
                              control.control.binding,
                              row.id,
                            );
                          }
                        : null,
                    icon: _operationGlyph(
                      control.content?.removeIcon,
                      childScope,
                      const Icon(Icons.delete_outline),
                    ),
                  ),
                  tooltip: false,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _decorateCollection(
    skir.BoundControl control,
    PortablePresentationScope childScope,
    Widget child,
  ) => _controlFrame(control, childScope, child, renderPrefix: true);
}

String _operationText(
  PortablePresentationScope scope,
  skir.ExpressionNode? value,
  String fallback,
) => value == null
    ? fallback
    : switch (_string(scope, value)) {
        _ResolvedValue(:final value) => value,
        _ResolvedFailure(:final message) => throw PresentationColorFailure(
          message,
        ),
      };
Widget _operationGlyph(
  skir.PresentationNode? node,
  PortablePresentationScope scope,
  Widget fallback,
) => node == null
    ? fallback
    : PortablePresentationNodeRenderer(
        node: node,
        scope: scope.withReadOnly(true),
      );
VisualDensity? _operationDensity(skir.CollectionContent? content) =>
    switch (content?.operationDensity) {
      skir.ControlDensity.compact => VisualDensity.compact,
      skir.ControlDensity.comfortable => VisualDensity.standard,
      _ => null,
    };
ButtonStyle? _operationButtonStyle(skir.CollectionContent? content) =>
    content?.operationDensity == null
    ? null
    : ButtonStyle(visualDensity: _operationDensity(content));
double _collectionSpacing(
  BuildContext context,
  skir.CollectionAppearance? appearance,
) {
  final value = appearance?.itemSpacing ?? context.spacing.space2;
  if (!value.isFinite || value < 0) {
    throw const PresentationColorFailure(
      "Collection spacing must be finite and nonnegative",
    );
  }
  return value;
}

Widget _collectionSurface(
  BuildContext context,
  skir.CollectionAppearance? appearance,
  PortablePresentationScope scope,
  skir.PresentationNode node,
  Widget child,
) => DepthBox(
  child: appearance == null
      ? child
      : _PresentationSurface(
          style: skir.ContainerLayout(
            child: node,
            backgroundColor: appearance.itemBackground,
            foregroundColor: appearance.itemForeground,
            border: appearance.itemBorder,
            radius: appearance.itemRadius ?? skir.PresentationRadius.none,
            transitionMilliseconds: appearance.itemTransitionMilliseconds ?? 0,
          ),
          scope: scope,
          diagnostic: _diagnostic,
          child: child,
        ),
);
Widget _collectionEmpty(
  BuildContext context,
  PortablePresentationScope scope,
  skir.CollectionContent? content,
  String fallback,
) => Padding(
  padding: EdgeInsets.only(bottom: context.spacing.space2),
  child: content?.empty == null
      ? Text(
          _operationText(scope, content?.emptyText, fallback),
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: context.colors.contentSecondary),
        )
      : PortablePresentationNodeRenderer(node: content!.empty!, scope: scope),
);
Widget _mapGuidance(
  PortablePresentationScope scope,
  skir.ExpressionNode? label,
  Widget editor,
) => label == null
    ? editor
    : Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [Text(_operationText(scope, label, "")), editor],
      );

Widget _operationAppearance(
  skir.CollectionContent? content,
  PortablePresentationScope scope,
  Widget Function(WidgetStatesController, ButtonStyle) action, {
  bool tooltip = true,
}) => _actionAppearance(
  scope,
  skir.ActionAppearance(
    appearance: null,
    variant: null,
    tooltip: tooltip ? content?.operationTooltip : null,
  ),
  (context, states, style, resolved) =>
      action(states, _operationButtonStyle(content)?.merge(style) ?? style),
  enabled: scope.enabled && !scope.readOnly,
);
