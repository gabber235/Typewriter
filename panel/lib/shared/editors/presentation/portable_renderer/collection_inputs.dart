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
  }) => _knownChoices(childScope, control.control.binding) != null
      ? _renderChoiceSetInput(control, childScope)
      : _renderSequenceInput(
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
    final differing = childScope.itemValues(control.binding);
    if (differing.isNotEmpty) {
      return _renderMixedCollection(
        control,
        childScope,
        differing,
        indexBinding == null ? "sets" : "lists",
      );
    }
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
    final rendered = collectionWithHeader(
      sourceScope: childScope,
      mutationScope: childScope,
      reference: control.binding,
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
      buildBody: (context) => _withItemMotion(appearance, (arrival, leave) {
        late final CollectionSequence sequence;
        sequence = CollectionSequence(
          scope: childScope,
          collection: control.binding,
          items: items,
          allowReorder: allowReorder,
          arrival: arrival,
          leave: leave,
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
            return collectionRow(
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
      }),
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

  /// Reads the service's item moves in the collection input's own build,
  /// outside any hook build, so a bad override shows the presentation
  /// diagnostic instead of Flutter's error widget.
  Widget _withItemMotion(
    skir.CollectionAppearance? appearance,
    Widget Function(MotionOverride? arrival, MotionOverride? leave) build,
  ) {
    MotionReading<MotionOverride?> read(skir.PresentationTransition? move) =>
        switch (move?.reading) {
          null => const MotionReading.read(null),
          MotionRead(:final value) => MotionReading.read(value),
          MotionReadFailed(:final message) => MotionReading.failed(message),
        };
    return switch ((
      read(appearance?.itemArrival),
      read(appearance?.itemLeave),
    )) {
      (MotionReadFailed(:final message), _) ||
      (_, MotionReadFailed(:final message)) => _diagnostic(message),
      (MotionRead(value: final arrival), MotionRead(value: final leave)) =>
        build(arrival, leave),
    };
  }

  Widget _renderMapInput(
    BuildContext context,
    skir.MapControl control,
    PortablePresentationScope childScope, {
    Widget Function(_ScopedCollectionHeader, Widget)? headerBuilder,
  }) {
    final differing = childScope.itemValues(control.control.binding);
    if (differing.isNotEmpty) {
      return _renderMixedCollection(
        control.control,
        childScope,
        differing,
        "maps",
      );
    }
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
    return collectionWithHeader(
      sourceScope: childScope,
      mutationScope: childScope,
      reference: control.control.binding,
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
      buildBody: (context) => _withItemMotion(
        control.appearance,
        (arrival, leave) => _decorateCollection(
          control.control,
          childScope,
          _MapRows(
            rows: rows,
            arrival: arrival,
            leave: leave,
            empty: (context) => _collectionEmpty(
              context,
              childScope,
              control.content,
              "No entries",
            ),
            rowBuilder: (context, row, index) => _renderMapRow(
              context,
              control,
              row,
              collection,
              childScope,
              rowIndex: index,
            ),
          ),
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
    return collectionRow(
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

/// Map rows on row entries: [CollectionSequence] without reordering.
class _MapRows extends HookWidget {
  const _MapRows({
    required this.rows,
    required this.arrival,
    required this.leave,
    required this.empty,
    required this.rowBuilder,
  });
  final List<skir.MapRow> rows;
  final MotionOverride? arrival;
  final MotionOverride? leave;
  final WidgetBuilder empty;
  final Widget Function(BuildContext context, skir.MapRow row, int index)
  rowBuilder;

  @override
  Widget build(BuildContext context) {
    final animated = useAnimatedRows(
      items: rows,
      identity: (row) => row.id,
      arrival: arrival,
      leave: leave,
    );
    final entries = animated.entries;
    final lastBuilt = _useLastBuilt(entries);
    // A row's index counts only rows that stay.
    int activeIndexAt(int visualIndex) => entries
        .take(visualIndex)
        .where((entry) => entry.phase != RowPhase.leaving)
        .length;
    return RowFocusScope(
      focus: animated.focus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The empty state shows once the last leaving row is gone.
          if (entries.isEmpty) empty(context),
          for (final (visualIndex, entry) in entries.indexed)
            RowEntryScope(
              key: ValueKey(entry.id),
              entry: entry,
              // The editor owns its scroll, so rows have no SliverRowAnchor.
              child: entry.motion(
                entry.row(
                  // Map rows hold fields: focus lands on their RowLanding.
                  RowStop(
                    role: RowRole.holder,
                    child: lastBuilt(
                      entry,
                      () => rowBuilder(
                        context,
                        entry.item,
                        activeIndexAt(visualIndex),
                      ),
                    ),
                  ),
                ),
                anchors: false,
              ),
            ),
        ],
      ),
    );
  }
}

/// The set of known choices and the collections the selected items hold
/// differently.
extension _PortableChoiceSetRendering on PortablePresentationNodeRenderer {
  /// The cases of the enum a set at [reference] holds, or null when its
  /// items are not cases of one enum.
  List<String>? _knownChoices(
    PortablePresentationScope scope,
    skir.BindingRef reference,
  ) {
    final catalog = scope.catalog;
    final item = catalog?.namedUse(
      catalog.collectionItemType(scope.expectedType(reference)),
    );
    return item == null ? null : catalog?.enumCases(item.definition);
  }

  /// Every case of the enum a set holds as an option to check, the same for
  /// one item and for many.
  Widget _renderChoiceSetInput(
    skir.SetControl control,
    PortablePresentationScope scope,
  ) {
    final reference = control.control.binding;
    final catalog = scope.catalog!;
    final setType = catalog.namedUse(scope.expectedType(reference));
    final item = catalog.namedUse(
      catalog.collectionItemType(scope.expectedType(reference)),
    )!;
    final selected = scope.selectedValues(reference);
    final differing = scope.itemValues(reference);
    return _controlFrame(
      control.control,
      scope,
      _PortableChoiceSet(
        key: ValueKey(node.nodeId),
        choices: _knownChoices(scope, reference)!,
        values: selected.isEmpty ? [scope.read(reference)] : selected,
        enabled:
            scope.enabled &&
            !scope.readOnly &&
            (differing.isEmpty || scope.canWriteItems(reference)),
        choice: (name) => skir.DataValue.createNamed(
          actualType: item.member(name),
          payload: skir.DataValue.unit,
        ),
        withItems: (value, items) {
          final set = skir.DataValue.createSetValue(items: items);
          return value is skir.DataValue_namedWrapper
              ? value.withAuthoredPayload(set)
              : setType == null
              ? set
              : skir.DataValue.createNamed(actualType: setType, payload: set);
        },
        write: (values) => values.toSet().length == 1
            ? scope.write(reference, values.first)
            : scope.writeItems(reference, values),
      ),
      renderPrefix: true,
    );
  }

  /// A list, set or map the selected items hold differently: how many
  /// different [noun] there are, and an edit that gives every item the first
  /// item's value to start from.
  Widget _renderMixedCollection(
    skir.BoundControl control,
    PortablePresentationScope scope,
    List<skir.DataValue?> differing,
    String noun,
  ) {
    final first = differing.first;
    return _controlFrame(
      control,
      scope,
      Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.spacing.space1,
          children: [
            Text(
              "$mixedValueLabel: ${differing.toSet().length} different $noun",
            ),
            const MixedValueMessage(),
            Button(
              face: ButtonFace.outlined,
              icon: const Icon(Icons.edit_outlined),
              label: "Edit",
              onPressed: scope.enabled && !scope.readOnly && first != null
                  ? () => scope.write(control.binding, first)
                  : null,
            ),
          ],
        ),
      ),
      renderPrefix: true,
    );
  }
}

/// The options of a set of known choices over the values each selected item
/// holds.
///
/// A press on a choice only some items hold gives it to all of them, the
/// next takes it from all, and the one after gives each item back what it
/// held before. A choice all or none hold switches between the two.
class _PortableChoiceSet extends HookWidget {
  const _PortableChoiceSet({
    required this.choices,
    required this.values,
    required this.enabled,
    required this.choice,
    required this.withItems,
    required this.write,
    super.key,
  });

  final List<String> choices;
  final List<skir.DataValue?> values;
  final bool enabled;
  final skir.DataValue Function(String name) choice;
  final skir.DataValue Function(
    skir.DataValue? value,
    List<skir.ListItem> items,
  )
  withItems;
  final void Function(List<skir.DataValue> values) write;

  /// A new item holding the choice [name] in [value], under the choice's own
  /// name unless an item already has it.
  skir.ListItem _item(skir.DataValue? value, String name) => skir.ListItem(
    id: skir.ItemId(
      value: value?.authoredItems?.any((item) => item.id.value == name) ?? false
          ? const Uuid().v4()
          : name,
    ),
    value: choice(name),
  );

  /// [value] holding the choice [name] at [place], or without it when
  /// [place] is null.
  skir.DataValue _placed(
    skir.DataValue? value,
    String name,
    (int, skir.ListItem)? place,
  ) {
    final items = [
      for (final item in value?.authoredItems ?? <skir.ListItem>[])
        if (item.value.enumCaseName != name) item,
    ];
    if (place case (final at, final item)) {
      items.insert(at.clamp(0, items.length), item);
    }
    return withItems(value, items);
  }

  static bool _holds(skir.DataValue? value, String name) =>
      _held(value, name) != null;

  /// Where [value] holds the choice [name], and the item that holds it.
  static (int, skir.ListItem)? _held(skir.DataValue? value, String name) {
    for (final (index, item) in (value?.authoredItems ?? []).indexed) {
      if (item.value.enumCaseName == name) return (index, item);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Where each item held a choice before the press that gave it to all,
    // and the values the presses since then left, so a change from anywhere
    // else forgets it.
    final before = useRef(
      <String, (List<(int, skir.ListItem)?>, List<skir.DataValue>)>{},
    );
    void press(String name) {
      final held = [for (final value in values) _held(value, name)];
      final all = held.every((place) => place != null);
      final remembered = switch (before.value.remove(name)) {
        (final places, final left) when listEquals(left, values) => places,
        _ => null,
      };
      final List<(int, skir.ListItem)?> next;
      if (remembered != null && !all) {
        next = remembered;
      } else if (all) {
        next = [for (final _ in held) null];
      } else {
        next = [
          for (final (index, place) in held.indexed)
            place ??
                (
                  values[index]?.authoredItems?.length ?? 0,
                  _item(values[index], name),
                ),
        ];
      }
      final written = [
        for (final (index, value) in values.indexed)
          _placed(value, name, next[index]),
      ];
      final places = remembered ?? (all ? null : held);
      if (places != null &&
          next != remembered &&
          places.any((place) => place != null)) {
        before.value[name] = (places, written);
      }
      write(written);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final name in choices)
          () {
            final count = values.where((value) => _holds(value, name)).length;
            return CheckOption(
              label: name,
              value: count == values.length
                  ? true
                  : count == 0
                  ? false
                  : null,
              detail: "$count of ${values.length}",
              onPressed: enabled ? () => press(name) : null,
            );
          }(),
      ],
    );
  }
}
