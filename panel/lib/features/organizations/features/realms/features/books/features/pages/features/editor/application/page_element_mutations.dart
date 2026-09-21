part of "page_elements.dart";

mixin _PageElementMutations
    on _$PageElements, _PageElementMutationContext, _PageElementValues {
  Future<void> moveAll(List<(String, int, int)> changed) =>
      _commitPlacements(changed, (current, x, y) {
        final graph = _graph(current);
        return GraphPlacement(
          x: x,
          y: y,
          width: graph.width,
          height: graph.height,
        );
      });

  Future<void> resizeAll(List<(String, int, int)> changed) =>
      _commitPlacements(changed, (current, width, height) {
        final graph = _graph(current);
        return GraphPlacement(
          x: graph.x,
          y: graph.y,
          width: width,
          height: height,
        );
      });

  Future<void> updateCues(List<(String, int, int)> changed) =>
      _commitPlacements(
        changed,
        (current, start, end) => switch (current) {
          TimelineSegmentPlacement() => TimelineSegmentPlacement(
            startFrame: start,
            endFrame: end,
          ),
          TimelineKeyframePlacement() => TimelineKeyframePlacement(
            frame: start,
          ),
          _ => throw ApiException.badRequest("The element is not a cue"),
        },
      );

  Future<void> _commitPlacements(
    List<(String, int, int)> changed,
    Placement Function(Placement current, int first, int second) update,
  ) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    final changes = <TransactionalEditorSource, Map<DataPath, DataValue>>{};
    try {
      for (final (id, first, second) in changed) {
        final owner = owners.editor(_target(id)) as TransactionalEditorSource;
        final resource = _typedElement(id);
        final placement = elementPlacementPath
            .read(resource.content.rootValue)
            .valueOrNull;
        if (placement == null) {
          throw ApiException.badRequest("Missing placement");
        }
        final current = decodePlacement(placement);
        changes[owner] = {
          elementPlacementPath: placementValue(update(current, first, second)),
        };
      }
      final results = await EditorBatch.submit(changes: changes);
      for (final result in results.values) {
        if (result is MutationSuccess || result is MutationUncertain) continue;
        throw ApiException.conflict(
          "The placement batch could not be saved. Review the retained draft.",
        );
      }
    } finally {
      owners.dispose();
    }
  }

  GraphPlacement _graph(Placement placement) => switch (placement) {
    final GraphPlacement value => value,
    _ => throw ApiException.badRequest("The element is not on a graph"),
  };

  Future<void> deleteAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return;
    await _submit(
      _commands.deleteElements([
        for (final id in elementIds) skir.ResourceId(value: id),
      ]),
    );
  }

  Placement creationPlacement(
    EntryPlacementKind placementKind, {
    Offset? preferredGraphAnchor,
  }) {
    state.ensureReady();
    return switch (placementKind) {
      EntryPlacementKind.graph => _graphPlacement(
        _placeCreatedGraphEntries(1, preferredGraphAnchor).single,
      ),
      EntryPlacementKind.timelineEntry => const TimelineEntryPlacement(
        trackIndex: 0,
      ),
    };
  }

  List<GraphGridRect> _placeCreatedGraphEntries(
    int count,
    Offset? preferredGraphAnchor,
  ) {
    final obstacles = state.requireValue.graphRects;
    return const GraphIncrementalPlacer().placeGroup(
      obstacles: obstacles,
      group: [
        for (var index = 0; index < count; index++)
          GraphGridRect(x: 0, y: index * 2, width: 4, height: 1),
      ],
      anchor:
          preferredGraphAnchor ??
          graphCenterOfMass(obstacles, cellSize: entryGraphCellSize) ??
          Offset.zero,
    );
  }

  Future<List<String>> duplicateAll(List<String> elementIds) async =>
      _duplicate(elementIds);

  Future<List<String>> duplicateAndLink(
    List<String> elementIds,
    DataPath path,
  ) => _duplicate(elementIds, linkPath: path);

  Future<List<String>> _duplicate(
    List<String> elementIds, {
    DataPath? linkPath,
  }) async {
    state.ensureReady();
    if (elementIds.isEmpty) return const [];
    final conversion = _codec();
    final copies = {
      for (final id in elementIds) skir.ResourceId(value: id): newResourceId(),
    };
    final selected = [for (final id in copies.keys) _resource(id)];
    final selectedGraphs =
        <({skir.AuthoringResource resource, GraphGridRect rect})>[];
    for (final resource in selected) {
      final placement = elementPlacementPath
          .read(_typedElement(resource.id.value).content.rootValue)
          .valueOrNull;
      if (placement == null) continue;
      final decoded = decodePlacement(placement);
      if (decoded case final GraphPlacement value) {
        selectedGraphs.add((resource: resource, rect: value.graphRect));
      }
    }
    final moved = <skir.ResourceId, GraphGridRect>{};
    if (selectedGraphs.isNotEmpty) {
      final sourceBounds = selectedGraphs.map((item) => item.rect).graphBounds!;
      final placed = _placeGraphRects(
        source: selectedGraphs.map((item) => item.rect).toList(),
        obstacles: state.requireValue.graphRects,
        anchor: Offset(
          sourceBounds.right + 1 + sourceBounds.width / 2,
          sourceBounds.center.dy,
        ),
      );
      for (final indexed in selectedGraphs.indexed) {
        moved[indexed.$2.resource.id] = placed[indexed.$1];
      }
    }
    final operations = <skir.AuthoringOperation>[];
    for (final resource in selected) {
      final decoded = conversion.authoring.decodeResourceOrThrow(resource);
      var content = _rewriteReferences(decoded.content.rootValue, copies);
      final rect = moved[resource.id];
      if (rect != null) {
        content = elementPlacementPath
            .replace(content, placementValue(_graphPlacement(rect)))
            .valueOrNull!;
      }
      operations.add(
        skir.AuthoringOperation.createCreate(
          resource: conversion.authoring.encodeResource(
            copies[resource.id]!,
            skir.ResourceKind.element,
            decoded.content.copyWith(rootValue: content),
          ),
        ),
      );
    }
    operations.add(_pageMembershipCommit(_pageId, add: copies.values));
    if (linkPath != null) {
      for (final resource in selected) {
        final decoded = conversion.authoring.decodeResourceOrThrow(resource);
        final current = linkPath.read(decoded.content.rootValue).valueOrNull;
        final projected = state.requireValue
            .where((item) => item.id == resource.id.value)
            .firstOrNull;
        final definition = switch (projected) {
          PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
            definition,
          _ => null,
        };
        final next = definition?.referenceDropValues(
          EntryIdentifier(
            copies[resource.id]!.value,
            elementType: definition.elementDefinition.rootType,
          ),
          conversion.registry,
        )[linkPath];
        if (current == null || next == null) {
          throw ApiException.conflict("The selected reference field changed");
        }
        final proposed = linkPath
            .replace(decoded.content.rootValue, next)
            .valueOrNull;
        if (proposed == null) {
          throw ApiException.conflict("The selected reference field changed");
        }
        operations.add(_contentCommit(resource, proposed, {linkPath}));
      }
    }
    await _submit(_commands.applyPreviewed(operations));
    return [
      for (final id in elementIds) copies[skir.ResourceId(value: id)]!.value,
    ];
  }

  Future<void> moveEntriesToPage(
    List<String> elementIds,
    String targetPageId,
  ) async {
    state.ensureReady();
    final targetId = skir.ResourceId(value: targetPageId);
    if (elementIds.isEmpty || targetId == _pageId) return;
    final ids = [for (final id in elementIds) skir.ResourceId(value: id)];
    await ref.withReadyPageElements(targetPageId, (target) async {
      final operations = <skir.AuthoringOperation>[
        _pageMembershipCommit(_pageId, remove: ids),
        _pageMembershipCommit(targetId, add: ids),
      ];
      final graphs = <({skir.ResourceId id, GraphGridRect rect})>[];
      for (final id in ids) {
        final value = elementPlacementPath
            .read(_typedElement(id.value).content.rootValue)
            .valueOrNull;
        if (value == null) continue;
        final placement = decodePlacement(value);
        if (placement case final GraphPlacement value) {
          graphs.add((id: id, rect: value.graphRect));
        }
      }
      if (graphs.isNotEmpty) {
        final targetObstacles = target.state.requireValue.graphRects;
        final placed = _placeGraphRects(
          source: graphs.map((item) => item.rect).toList(),
          obstacles: targetObstacles,
          anchor:
              graphCenterOfMass(
                targetObstacles,
                cellSize: entryGraphCellSize,
              ) ??
              Offset.zero,
        );
        for (final indexed in graphs.indexed) {
          operations.add(_placementCommit(indexed.$2.id, placed[indexed.$1]));
        }
      }
      await _submit(_commands.applyPreviewed(operations));
    });
  }

  Future<void> replaceEntryType(
    String elementId,
    ElementDefinition definition,
    RecordValue value,
  ) async {
    state.ensureReady();
    final conversion = _codec();
    final resource = _resource(skir.ResourceId(value: elementId));
    final proposed = resource.toMutable()
      ..content = conversion.authoring
          .encodeEnvelope(
            TypedValueEnvelope(rootType: definition.rootType, rootValue: value),
          )
          .valueOrNull!;
    await _submit(
      _commands.applyPreviewed([
        skir.AuthoringOperation.createCommit(
          id: resource.id,
          observedSequence: _authoring.sequence!,
          base: resource,
          proposed: proposed,
          changedPaths: [
            conversion.codec.encodePath(DataPath.root).valueOrNull!,
          ],
        ),
      ]),
    );
  }

  TypedAuthoringResource _typedElement(String id) {
    final conversion = _codec();
    return conversion.authoring.decodeResourceOrThrow(
      _resource(skir.ResourceId(value: id)),
    );
  }

  skir.AuthoringResource _resource(skir.ResourceId id) =>
      _authoring.resources[id] ?? (throw ApiException.notFound("Resource"));

  GraphPlacement _graphPlacement(GraphGridRect rect) => GraphPlacement(
    x: rect.x,
    y: rect.y,
    width: rect.width,
    height: rect.height,
  );

  skir.AuthoringOperation _placementCommit(
    skir.ResourceId id,
    GraphGridRect rect,
  ) {
    final conversion = _codec();
    final resource = _resource(id);
    final decoded = conversion.authoring.decodeResourceOrThrow(resource);
    final proposed = elementPlacementPath
        .replace(
          decoded.content.rootValue,
          placementValue(_graphPlacement(rect)),
        )
        .valueOrNull;
    if (proposed == null) throw ApiException.badRequest("Missing placement");
    return _contentCommit(resource, proposed, {elementPlacementPath});
  }

  skir.AuthoringOperation _contentCommit(
    skir.AuthoringResource resource,
    DataValue proposedValue,
    Set<DataPath> paths,
  ) {
    final conversion = _codec();
    final decoded = conversion.authoring.decodeResourceOrThrow(resource);
    final proposed = resource.toMutable()
      ..content = conversion.authoring
          .encodeEnvelope(decoded.content.copyWith(rootValue: proposedValue))
          .valueOrNull!;
    return skir.AuthoringOperation.createCommit(
      id: resource.id,
      observedSequence: _authoring.sequence!,
      base: resource,
      proposed: proposed,
      changedPaths: [
        for (final path in paths)
          conversion.codec.encodePath(path).valueOrNull!,
      ],
    );
  }

  skir.AuthoringOperation _pageMembershipCommit(
    skir.ResourceId pageId, {
    Iterable<skir.ResourceId> add = const [],
    Iterable<skir.ResourceId> remove = const [],
  }) {
    final conversion = _codec();
    final page = _resource(pageId);
    final decoded = conversion.authoring.decodeResourceOrThrow(page);
    final root = decoded.content.rootValue;
    if (root is! RecordValue || root.fields["elements"] is! ListValue) {
      throw StateError("The Page elements relation is unavailable");
    }
    final current = (root.fields["elements"]! as ListValue).values;
    final removed = remove.toSet();
    final values = <skir.ResourceId>{
      for (final value in current)
        if (value case ReferenceValue(:final id) when !removed.contains(id)) id,
      ...add,
    };
    final proposed = root.withField(
      "elements",
      ListValue([for (final id in values) ReferenceValue(id)]),
    );
    return _contentCommit(page, proposed, {DataPath.root.field("elements")});
  }

  List<GraphGridRect> _placeGraphRects({
    required List<GraphGridRect> source,
    required List<GraphGridRect> obstacles,
    required Offset anchor,
  }) {
    final bounds = source.graphBounds!;
    return const GraphIncrementalPlacer().placeGroup(
      obstacles: obstacles,
      group: [for (final rect in source) rect.translate(-bounds.x, -bounds.y)],
      anchor: anchor,
    );
  }
}

DataValue _rewriteReferences(
  DataValue value,
  Map<skir.ResourceId, skir.ResourceId> replacements,
) => switch (value) {
  ReferenceValue(:final id) => ReferenceValue(replacements[id] ?? id),
  ListValue(:final values) => ListValue([
    for (final item in values) _rewriteReferences(item, replacements),
  ]),
  MapValue(:final entries) => MapValue([
    for (final entry in entries)
      DataMapEntry(
        key: _rewriteReferences(entry.key, replacements),
        value: _rewriteReferences(entry.value, replacements),
      ),
  ]),
  RecordValue(:final fields) => RecordValue({
    for (final field in fields.entries)
      field.key: _rewriteReferences(field.value, replacements),
  }),
  PolymorphicValue(:final concreteType, :final value) => PolymorphicValue(
    concreteType: concreteType,
    value: _rewriteReferences(value, replacements),
  ),
  _ => value,
};

extension on Iterable<PageElement> {
  List<GraphGridRect> get graphRects => [
    for (final element in this)
      if (element case PageElementEntry(
        entry: DefinitionPageEntry(:final definition),
      ))
        if (definition.placement.kind == EntryPlacementKind.graph)
          GraphGridRect(
            x: definition.placement.x,
            y: definition.placement.y,
            width: definition.placement.width,
            height: definition.placement.height,
          ),
  ];
}

extension on GraphPlacement {
  GraphGridRect get graphRect =>
      GraphGridRect(x: x, y: y, width: width, height: height);
}
