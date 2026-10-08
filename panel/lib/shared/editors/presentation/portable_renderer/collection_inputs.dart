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
  }) {
    final current = childScope.read(control.binding);
    final items =
        current?.authoredItems?.toList() ??
        (current?.authoredPayload == skir.DataValue.unfilled
            ? <skir.ListItem>[]
            : null);
    final collection = childScope.location(control.binding);
    if (items == null || collection == null || childScope.authoring == null) {
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
      final content = itemPresentation == null
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
        padding: EdgeInsets.only(bottom: context.spacing.space2),
        child: DepthBox(
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space2),
            child: Row(
              children: [
                if (allowReorder && !presentationOwnsHandle)
                  _AuthoredReorderHandle(
                    index: index,
                    label: "Reorder ${current.id.value}",
                    enabled: childScope.enabled && !childScope.readOnly,
                    canMoveEarlier: index > 0,
                    canMoveLater: index < items.length - 1,
                    onMoveEarlier: () {
                      final after = index == 1 ? null : items[index - 2].id;
                      childScope.authoring!.move(collection, current.id, after);
                      childScope.onDraftChanged?.call();
                    },
                    onMoveLater: () {
                      childScope.authoring!.move(
                        collection,
                        current.id,
                        items[index + 1].id,
                      );
                      childScope.onDraftChanged?.call();
                    },
                  ),
                Expanded(child: content),
                if (allowRemove)
                  IconButton(
                    tooltip: "Remove item",
                    onPressed: childScope.enabled && !childScope.readOnly
                        ? () {
                            childScope.authoring!.remove(
                              collection,
                              current.id,
                            );
                            childScope.onDraftChanged?.call();
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline),
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
                    childScope.authoring!.move(collection, moving.id, after);
                    childScope.onDraftChanged?.call();
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
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.space2),
              child: Text(
                "No items",
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.colors.contentSecondary),
              ),
            ),
          list,
          if (allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () => unawaited(
                        _addSequenceItem(
                          context: context,
                          control: control,
                          linkControl: linkControl,
                          collection: collection,
                          items: items,
                          childScope: childScope,
                        ),
                      )
                    : null,
                icon: Icon(linkControl == null ? Icons.add : Icons.add_link),
                label: Text(linkControl == null ? "Add item" : "Add link"),
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
    required List<skir.ListItem> items,
    required PortablePresentationScope childScope,
  }) async {
    final draft = childScope.authoring;
    if (draft == null) return;
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    final itemReference = skir.BindingRef(
      bindingId: control.binding.bindingId,
      path: skir.ValuePath(
        segments: [
          ...control.binding.path.segments,
          skir.PathSegment.createItem(id: item),
        ],
      ),
    );
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
    final expected = childScope.expectedType(itemReference);
    final named = switch (_unwrapNullable(expected)) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    final representation = named == null
        ? null
        : childScope.catalog
              ?.published(named.definition)
              ?.definition
              .representation;
    final concreteRecord = switch (representation) {
      skir.RepresentationTemplate_recordWrapper(:final value) =>
        !value.abstract_,
      _ => false,
    };
    PortablePathResult<skir.AuthoringRecord> result;
    if (named != null && concreteRecord) {
      final prepare = childScope.prepareCreation;
      if (prepare == null) {
        childScope.reportStatus?.call("The collection item cannot be prepared");
        return;
      }
      final selection = skir.TypeSelection.wrapComplete(named);
      final identity = sha256
          .convert(
            utf8.encode(
              "${draft.generation.value}\u0000${collection.resource.value}\u0000${_pathLabel(itemLocation.path)}\u0000$selection",
            ),
          )
          .toString();
      final request = skir.InitializationRequest(
        id: skir.InitializationRequestId(value: "panel:item:$identity"),
        catalog: draft.generation,
        type: selection,
        supplied: const [],
        intentHash: identity,
      );
      try {
        final previousFindingCount = draft.initializationFindings.length;
        final prepared = await prepare(request);
        if (!context.mounted) return;
        result = draft.insertPrepared(
          collection,
          items.lastOrNull?.id,
          item,
          request,
          prepared,
        );
        final findings = draft.initializationFindings.skip(
          previousFindingCount,
        );
        if (findings.isNotEmpty) {
          childScope.reportStatus?.call(
            findings.map(formatPortableInitializationDiagnostic).join("\n"),
          );
        }
      } on Object catch (error) {
        childScope.reportStatus?.call(
          "The collection item could not be prepared: $error",
        );
        return;
      }
    } else {
      result = draft.insert(
        collection,
        items.lastOrNull?.id,
        skir.ListItem(id: item, value: draft.defaultValue(expected)),
      );
    }
    if (result case PortablePathUnavailable(:final message)) {
      childScope.reportStatus?.call(message);
      return;
    }
    childScope.onDraftChanged?.call();
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
    if (rows == null || collection == null || childScope.authoring == null) {
      return _diagnostic("The map binding is unavailable");
    }
    return _decorateCollection(
      control.control,
      childScope,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows)
            _renderMapRow(context, control, row, collection, childScope),
          if (control.allowAdd)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.icon(
                onPressed: childScope.enabled && !childScope.readOnly
                    ? () => _addMapRow(control, collection, rows, childScope)
                    : null,
                icon: const Icon(Icons.add),
                label: const Text("Add entry"),
              ),
            ),
        ],
      ),
    );
  }

  void _addMapRow(
    skir.MapControl control,
    skir.ValueLocation collection,
    List<skir.MapRow> rows,
    PortablePresentationScope childScope,
  ) {
    final draft = childScope.authoring;
    if (draft == null) return;
    final item = skir.ItemId(value: "panel:${const Uuid().v4()}");
    skir.BindingRef reference(skir.PathSegment branch) => skir.BindingRef(
      bindingId: control.control.binding.bindingId,
      path: skir.ValuePath(
        segments: [
          ...control.control.binding.path.segments,
          skir.PathSegment.createItem(id: item),
          branch,
        ],
      ),
    );
    final result = draft.replaceMap(collection, [
      ...rows,
      skir.MapRow(
        id: item,
        key: draft.defaultValue(
          childScope.expectedType(reference(skir.PathSegment.mapKey)),
        ),
        value: draft.defaultValue(
          childScope.expectedType(reference(skir.PathSegment.mapValue)),
        ),
      ),
    ]);
    if (result case PortablePathUnavailable(:final message)) {
      childScope.reportStatus?.call(message);
      return;
    }
    childScope.onDraftChanged?.call();
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
      padding: EdgeInsets.only(bottom: context.spacing.space2),
      child: DepthBox(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space2),
          child: Row(
            children: [
              Expanded(
                child: control.keyPresentation == null
                    ? Text(row.key.authoredString ?? "Key")
                    : PortablePresentationNodeRenderer(
                        node: control.keyPresentation!,
                        scope: keyScope,
                      ),
              ),
              SizedBox(width: context.spacing.space2),
              Expanded(
                child: control.valuePresentation == null
                    ? Text(row.value.authoredString ?? "Value")
                    : PortablePresentationNodeRenderer(
                        node: control.valuePresentation!,
                        scope: valueScope,
                      ),
              ),
              if (control.allowRemove)
                IconButton(
                  tooltip: "Remove row",
                  onPressed: childScope.enabled && !childScope.readOnly
                      ? () {
                          final current = switch (childScope.authoring!.read(
                            collection,
                          )) {
                            PortablePathValue(value: final value) =>
                              value.authoredPayload,
                            _ => null,
                          };
                          if (current is! skir.DataValue_mapValueWrapper) {
                            return;
                          }
                          final result = childScope.authoring!.replaceMap(
                            collection,
                            current.value.rows.where(
                              (candidate) => candidate.id != row.id,
                            ),
                          );
                          if (result case PortablePathUnavailable(
                            :final message,
                          )) {
                            childScope.reportStatus?.call(message);
                          } else {
                            childScope.onDraftChanged?.call();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.delete_outline),
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
  ) => _controlFrame(control, childScope, child);
}
