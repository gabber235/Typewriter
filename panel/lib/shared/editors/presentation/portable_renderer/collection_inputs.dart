part of "../portable_presentation_renderer.dart";

extension _PortableCollectionInputRendering
    on PortablePresentationNodeRenderer {
  Widget _renderListInput(
    BuildContext context,
    skir.ListControl control,
    PortablePresentationScope childScope, {
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBinding: control.itemBinding,
    indexBinding: control.indexBinding,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: control.allowReorder,
    childScope: childScope,
    appearance: control.appearance,
    content: control.content,
    headerBuilder: headerBuilder,
  );

  Widget _renderSetInput(
    BuildContext context,
    skir.SetControl control,
    PortablePresentationScope childScope, {
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) => _renderSequenceInput(
    context: context,
    control: control.control,
    itemPresentation: control.itemPresentation,
    itemBinding: control.itemBinding,
    indexBinding: null,
    allowAdd: control.allowAdd,
    allowRemove: control.allowRemove,
    allowReorder: false,
    childScope: childScope,
    appearance: control.appearance,
    content: control.content,
    headerBuilder: headerBuilder,
  );

  Widget _renderSequenceInput({
    required BuildContext context,
    required skir.BoundControl control,
    required skir.PresentationNode? itemPresentation,
    required skir.BindingDeclaration itemBinding,
    required skir.BindingDeclaration? indexBinding,
    required bool allowAdd,
    required bool allowRemove,
    required bool allowReorder,
    required PortablePresentationScope childScope,
    required skir.CollectionAppearance? appearance,
    required skir.CollectionContent? content,
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
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
    final linkControl = switch (itemPresentation?.element) {
      skir.PresentationElement_linkInputWrapper(:final value) => value,
      _ => null,
    };
    final rendered = collectionWithFocus(
      sourceScope: childScope,
      mutationScope: childScope,
      reference: control.binding,
      removalKind: _CollectionRemovalKind.listItem,
      renderedOrder: [for (final item in items) item.id],
      sourceHeader: _ScopedCollectionHeader(
        scope: childScope,
        header: node.header,
      ),
      fallbackHeader: () => _generatedCollectionHeader(
        childScope.associationFor(control).label ?? "Items",
      ),
      contained: false,
      allowAdd: allowAdd,
      content: content,
      addLabel: linkControl == null ? "Add item" : "Add link",
      addIcon: linkControl == null ? Icons.add : Icons.add_link,
      add: (context) => unawaited(
        _addSequenceItem(
          context: context,
          control: control,
          linkControl: linkControl,
          collection: collection,
          childScope: childScope,
        ),
      ),
      headerBuilder: headerBuilder,
      buildBody: (context) {
        late final CollectionSequence sequence;
        sequence = CollectionSequence(
          scope: childScope,
          collection: control.binding,
          items: items,
          allowReorder: allowReorder,
          entryBuilder: (context, item, index) {
            final reference = skir.BindingRef(
              bindingId: control.binding.bindingId,
              path: skir.ValuePath(
                segments: [
                  ...control.binding.path.segments,
                  skir.PathSegment.createItem(id: item.id),
                ],
              ),
            );
            var itemScope = childScope.withBinding(reference, itemBinding);
            if (itemScope == null) {
              return _diagnostic(
                "Collection item ${item.id.value} is unavailable",
              );
            }
            if (indexBinding != null) {
              itemScope = itemScope.declare(
                indexBinding,
                skir.DataValue.wrapInteger(index.toString()),
              );
            }
            final editor = prepareListChild(
              itemPresentation,
              itemBinding.id,
              itemScope,
            );
            return collectionRowWithFocus(
              id: item.id,
              editor: editor,
              scope: childScope,
              owner: node,
              generatedHeader: () => _generatedEntryHeader("Item ${index + 1}"),
              initiallyNeedsRepair:
                  item.value.authoredPayload == skir.DataValue.unfilled,
              controls: [
                if (allowReorder)
                  _SuppliedHeaderControl(
                    command: switch (childScope.collectionCommandTarget(
                      reference,
                    )) {
                      final target? => _CollectionCommand.reorder(target),
                      null => null,
                    },
                    build: (context) => sequence.handle(
                      context,
                      index,
                      editor.scope,
                      icon: _operationGlyph(
                        content?.reorderIcon,
                        childScope,
                        const Icon(Icons.drag_handle),
                      ),
                    ),
                  ),
              ],
              permittedRemove: allowRemove
                  ? skir.EditorAction.wrapLocal(
                      skir.LocalEditorAction.createRemoveListItem(
                        target: control.binding,
                        item: item.id,
                      ),
                    )
                  : null,
              appearance: appearance,
              content: content,
            );
          },
        );
        return _decorateCollection(
          control,
          childScope,
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty)
                _collectionEmpty(context, childScope, content, "No items"),
              sequence,
            ],
          ),
        );
      },
    );
    return linkControl == null && !_linksItems(childScope, control.binding)
        ? rendered
        : PortableResourcesInteractionScope.wrapLinkField(
            context,
            childScope,
            collection,
            rendered,
          );
  }

  /// Whether the collection at [binding] holds links, so dropped resources
  /// can be linked into it.
  bool _linksItems(PortablePresentationScope scope, skir.BindingRef binding) {
    final catalog = scope.catalog;
    final item = catalog?.namedUse(
      catalog.collectionItemType(scope.expectedType(binding)),
    );
    return item != null &&
        catalog?.published(item.definition)?.definition.representation
            is skir.RepresentationTemplate_linkWrapper;
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
    PortablePresentationScope childScope, {
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) {
    final value = childScope.read(control.control.binding)?.authoredPayload;
    final rows = switch (value) {
      skir.DataValue_mapValueWrapper(:final value) => value.rows.toList(),
      _ when value == skir.DataValue.unfilled => <skir.MapRow>[],
      _ => null,
    };
    final collection = childScope.location(control.control.binding);
    if (rows == null || collection == null) {
      return _diagnostic("The map binding is unavailable");
    }
    return collectionWithFocus(
      sourceScope: childScope,
      mutationScope: childScope,
      reference: control.control.binding,
      removalKind: _CollectionRemovalKind.mapRow,
      renderedOrder: [for (final row in rows) row.id],
      sourceHeader: _ScopedCollectionHeader(
        scope: childScope,
        header: node.header,
      ),
      fallbackHeader: () => _generatedCollectionHeader(
        childScope.associationFor(control.control).label ?? "Entries",
      ),
      contained: false,
      allowAdd: control.allowAdd,
      content: control.content,
      addLabel: "Add entry",
      addIcon: Icons.add,
      add: (context) => childScope.addMapRow(control.control.binding),
      headerBuilder: headerBuilder,
      buildBody: (context) => _decorateCollection(
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
            for (final (index, row) in rows.indexed)
              _renderMapRow(
                context,
                control,
                row,
                collection,
                childScope,
                rowIndex: index,
              ),
          ],
        ),
      ),
    );
  }

  Widget _renderMapRow(
    BuildContext context,
    skir.MapControl control,
    skir.MapRow row,
    skir.ValueLocation collection,
    PortablePresentationScope childScope, {
    required int rowIndex,
  }) {
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
    final keyScope = childScope.withBinding(keyReference, control.keyBinding);
    final valueScope = childScope.withBinding(
      valueReference,
      control.valueBinding,
    );
    if (keyScope == null || valueScope == null) {
      return _diagnostic("Map row ${row.id.value} is unavailable");
    }
    final key = prepareListChild(
      control.keyPresentation,
      control.keyBinding.id,
      keyScope,
    );
    final value = prepareListChild(
      control.valuePresentation,
      control.valueBinding.id,
      valueScope,
    );
    final scalarPair = key.effectiveInline && value.effectiveInline;
    final rowReference = skir.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: skir.ValuePath(segments: base),
    );
    final rowOwner = childScope.authoredAliases.resolve(rowReference);
    if (rowOwner == null) return _diagnostic("The map row is unavailable");
    final editor = _CollectionEditorContinuation(
      owner: rowOwner,
      scope: childScope,
      layout: scalarPair
          ? CollectionEntryLayout.inline
          : CollectionEntryLayout.disclosure,
      render: (context, _) {
        final keyWidget = _mapGuidance(
          childScope,
          control.content?.keyLabel,
          key.renderStandalone(context),
        );
        final valueWidget = _mapGuidance(
          childScope,
          control.content?.valueLabel,
          value.renderStandalone(context),
        );
        return scalarPair
            ? _inlineMapPair(
                context: context,
                keyEditor: keyWidget,
                valueEditor: valueWidget,
              )
            : _structuredMapBody(
                context: context,
                keyEditor: keyWidget,
                valueEditor: valueWidget,
              );
      },
    );
    return collectionRowWithFocus(
      id: row.id,
      editor: editor,
      scope: childScope,
      owner: node,
      generatedHeader: () => _generatedEntryHeader(
        row.key.collectionKeyTitle ?? "Entry ${rowIndex + 1}",
      ),
      initiallyNeedsRepair:
          row.key.authoredPayload == skir.DataValue.unfilled ||
          row.value.authoredPayload == skir.DataValue.unfilled,
      controls: const [],
      permittedRemove: control.allowRemove
          ? skir.EditorAction.wrapLocal(
              skir.LocalEditorAction.createRemoveMapRow(
                target: control.control.binding,
                row: row.id,
              ),
            )
          : null,
      appearance: control.appearance,
      content: control.content,
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
        _ResolvedFailure(:final message) => throw PresentationValueFailure(
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
    throw const PresentationValueFailure(
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
            transition: appearance.itemTransition,
            shadows: appearance.itemShadows,
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
