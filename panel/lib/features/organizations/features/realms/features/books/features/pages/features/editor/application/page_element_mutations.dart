part of "page_elements.dart";

/// Mutations exposed by the page coordinator for graph, timeline, and
/// lifecycle changes.
///
/// Placement batches preserve each owner's expected value and retain a draft
/// when one result is uncertain or conflicting. Creation, deletion, duplication
/// and page moves use the authoring batch contract directly.
mixin _PageElementMutations
    on _$PageElements, _PageElementMutationContext, _PageElementValues {
  Future<void> moveAll(List<(String, int, int)> changed) => _commitPlacements(
    changed,
    (element, x, y) => skir.ElementPlacement.createGraph(
      x: x,
      y: y,
      width: _graph(element).width,
      height: _graph(element).height,
    ),
  );

  Future<void> resizeAll(List<(String, int, int)> changed) => _commitPlacements(
    changed,
    (element, width, height) => skir.ElementPlacement.createGraph(
      x: _graph(element).x,
      y: _graph(element).y,
      width: width,
      height: height,
    ),
  );

  Future<void> updateCues(List<(String, int, int)> changed) =>
      _commitPlacements(
        changed,
        (element, start, end) => switch (element) {
          skir.ElementPlacement_timelineSegmentWrapper() =>
            skir.ElementPlacement.createTimelineSegment(
              startFrame: start,
              endFrame: end,
            ),
          skir.ElementPlacement_timelineKeyframeWrapper() =>
            skir.ElementPlacement.createTimelineKeyframe(frame: start),
          _ => throw ApiException.badRequest("The element is not a cue"),
        },
      );

  Future<void> _commitPlacements(
    List<(String, int, int)> changed,
    skir.ElementPlacement Function(skir.ElementPlacement, int, int) placement,
  ) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final owners = EditorOwnerRegistry(
      workspace: ref.read(localWorkControllerProvider),
    );
    final changes = <TransactionalEditorSource, Map<DataPath, DataValue>>{};
    try {
      for (final (id, first, second) in changed) {
        final target = _target(id);
        final owner = owners.editor(target) as TransactionalEditorSource;
        final current = encodeElementPlacement(
          owner.value(elementPlacementPath).valueOrNull!,
        );
        changes[owner] = {
          elementPlacementPath: elementPlacementValue(
            placement(current, first, second),
          ),
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

  skir.GraphPlacement _graph(skir.ElementPlacement element) =>
      switch (element) {
        skir.ElementPlacement_graphWrapper(:final value) => value,
        _ => throw ApiException.badRequest("The element is not on a graph"),
      };

  Future<void> deleteAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return;
    await _submit(
      _commands.deleteElements([
        for (final id in elementIds) recordId("element:$id"),
      ]),
    );
  }

  Future<List<String>> createEntries(
    List<ElementDefinition> definitions,
    EntryPlacementKind placementKind, {
    Offset? preferredGraphAnchor,
    List<DataValue>? initialValues,
  }) async {
    state.ensureReady();
    if (definitions.isEmpty) return const [];
    if (initialValues != null && initialValues.length != definitions.length) {
      throw ArgumentError.value(
        initialValues.length,
        "initialValues",
        "Expected one initial value per definition",
      );
    }
    final codec = _codec();
    final registry = codec.registry;
    final ids = [
      for (final _ in definitions) newResourceId(AuthoringResource.element).id,
    ];
    final graphPlacements = switch (placementKind) {
      EntryPlacementKind.graph => _placeCreatedGraphEntries(
        definitions.length,
        preferredGraphAnchor,
      ),
      EntryPlacementKind.timelineEntry => const <GraphGridRect>[],
    };

    await _submit(
      _commands.createElements([
        for (final indexed in definitions.indexed)
          skir.PageElement(
            id: recordId("element:${ids[indexed.$1]}"),
            page: _pageId,
            elementType: indexed.$2.typeId.uuid,
            schemaRevision: indexed.$2.rootType.revision,
            value: _initialElementValue(
              indexed.$2,
              ids[indexed.$1],
              indexed.$2.name,
              registry,
              codec.codec,
              initialValues?[indexed.$1],
            ),
            placement: switch (placementKind) {
              EntryPlacementKind.graph => skir.ElementPlacement.createGraph(
                x: graphPlacements[indexed.$1].x,
                y: graphPlacements[indexed.$1].y,
                width: graphPlacements[indexed.$1].width,
                height: graphPlacements[indexed.$1].height,
              ),
              EntryPlacementKind.timelineEntry =>
                skir.ElementPlacement.createTimelineEntry(
                  trackIndex: indexed.$1,
                ),
            },
          ),
      ]),
    );
    return ids;
  }

  List<GraphGridRect> _placeCreatedGraphEntries(
    int count,
    Offset? preferredGraphAnchor,
  ) {
    final obstacles = _document.elements.graphRects;
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

  Future<List<String>> duplicateAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return const [];
    final elements = {for (final item in _document.elements) item.id.id: item};
    final ids = {
      for (final id in elementIds) id: newResourceId(AuthoringResource.element),
    };
    final selected = [for (final id in elementIds) elements[id]!];
    final graphElements = selected
        .where((element) => element.placement.graphRect != null)
        .toList(growable: false);
    final graphPlacements = <String, skir.ElementPlacement>{};
    if (graphElements.isNotEmpty) {
      final sourceBounds = graphElements
          .map((element) => element.placement.graphRect!)
          .graphBounds!;
      graphPlacements.addAll(
        _placeGraphElements(
          elements: graphElements,
          obstacles: _document.elements.graphRects,
          anchor: Offset(
            sourceBounds.right + 1 + sourceBounds.width / 2,
            sourceBounds.center.dy,
          ),
        ),
      );
    }
    await _submit(
      _commands.duplicateElements({
        for (final element in selected)
          element: (
            id: ids[element.id.id]!,
            placement: graphPlacements[element.id.id] ?? element.placement,
          ),
      }),
    );
    return [for (final id in elementIds) ids[id]!.id];
  }

  Future<List<String>> duplicateAndLink(
    List<String> elementIds,
    DataPath path,
  ) async {
    state.ensureReady();
    if (elementIds.isEmpty) return const [];
    final elements = {for (final item in _document.elements) item.id.id: item};
    final entries = {
      for (final item in state.requireValue)
        if (item case PageElementEntry(
          entry: DefinitionPageEntry(:final definition),
        ))
          definition.id: definition,
    };
    final selected = [for (final id in elementIds) elements[id]!];
    final ids = {
      for (final id in elementIds) id: newResourceId(AuthoringResource.element),
    };
    final graphElements = selected
        .where((element) => element.placement.graphRect != null)
        .toList(growable: false);
    final graphPlacements = <String, skir.ElementPlacement>{};
    if (graphElements.isNotEmpty) {
      final sourceBounds = graphElements
          .map((element) => element.placement.graphRect!)
          .graphBounds!;
      graphPlacements.addAll(
        _placeGraphElements(
          elements: graphElements,
          obstacles: _document.elements.graphRects,
          anchor: Offset(
            sourceBounds.right + 1 + sourceBounds.width / 2,
            sourceBounds.center.dy,
          ),
        ),
      );
    }
    final conversion = _codec();
    final codec = conversion.codec;
    final encodedPath = codec.encodePath(path).valueOrNull;
    if (encodedPath == null) {
      throw ApiException.badRequest("The reference path cannot be encoded");
    }
    final rewrites = [
      for (final id in elementIds)
        skir.ReferenceRewrite(
          source: recordId("element:$id"),
          target: ids[id]!,
        ),
    ];
    final operations = <skir.AuthoringOperation>[
      for (final element in selected)
        skir.AuthoringOperation.createDuplicateElement(
          sourceId: element.id,
          expectedValue: element.value,
          newId: ids[element.id.id]!,
          page: element.page,
          placement: graphPlacements[element.id.id] ?? element.placement,
          referenceRewrites: rewrites,
          valueMutations: const [],
        ),
      for (final element in selected)
        skir.AuthoringOperation.createPatchElement(
          id: element.id,
          page: null,
          placement: null,
          valueMutations: [
            skir.ExpectedElementValueMutation(
              expected: codec
                  .encodeValue(
                    path.read(entries[element.id.id]!.data).valueOrNull!,
                  )
                  .valueOrNull!,
              mutation: skir.ElementValueMutation.createSetValue(
                path: encodedPath,
                value: codec
                    .encodeValue(
                      entries[element.id.id]!.referenceDropValues(
                            EntryIdentifier(
                              ids[element.id.id]!.id,
                              elementType: entries[element.id.id]!
                                  .elementDefinition
                                  .rootType,
                            ),
                            conversion.registry,
                          )[path] ??
                          (throw ApiException.conflict(
                            "The selected reference field changed",
                          )),
                    )
                    .valueOrNull!,
              ),
            ),
          ],
          elementType: null,
        ),
    ];
    await _submit(_commands.applyPreviewed(operations));
    return [for (final id in elementIds) ids[id]!.id];
  }

  Future<void> moveEntriesToPage(
    List<String> elementIds,
    String targetPageId,
  ) async {
    state.ensureReady();
    if (elementIds.isEmpty || targetPageId == _pageId.id) return;
    final elements = {for (final item in _document.elements) item.id.id: item};
    final selected = [for (final id in elementIds) elements[id]!];
    await ref.withReadyPageElements(targetPageId, (target) async {
      final graphElements = selected
          .where((element) => element.placement.graphRect != null)
          .toList(growable: false);
      final graphPlacements = <String, skir.ElementPlacement>{};
      if (graphElements.isNotEmpty) {
        final obstacles = target._document.elements.graphRects;
        graphPlacements.addAll(
          _placeGraphElements(
            elements: graphElements,
            obstacles: obstacles,
            anchor:
                graphCenterOfMass(obstacles, cellSize: entryGraphCellSize) ??
                Offset.zero,
          ),
        );
      }
      await _submit(
        _commands.moveElementsToPage([
          for (final element in selected)
            (element, graphPlacements[element.id.id] ?? element.placement),
        ], recordId("page:$targetPageId")),
      );
    });
  }

  Future<void> replaceEntryType(
    String elementId,
    ElementDefinition definition,
    RecordValue value,
  ) async {
    state.ensureReady();
    final element = _document.elements.singleWhere(
      (element) => element.id.id == elementId,
    );
    final encoded = _codec().codec.encodeValue(value);
    final wireValue = encoded.valueOrNull;
    if (wireValue == null) {
      throw ApiException.badRequest(encoded.diagnostics.join("; "));
    }
    await _submit(
      _commands.replaceElementType(
        element: element,
        elementType: definition.typeId.uuid,
        schemaRevision: definition.rootType.revision,
        value: wireValue,
      ),
    );
  }

  Map<String, skir.ElementPlacement> _placeGraphElements({
    required List<skir.PageElement> elements,
    required List<GraphGridRect> obstacles,
    required Offset anchor,
  }) {
    final sourceRects = [
      for (final element in elements) element.placement.graphRect!,
    ];
    final sourceBounds = sourceRects.graphBounds!;
    final localRects = [
      for (final rect in sourceRects)
        rect.translate(-sourceBounds.x, -sourceBounds.y),
    ];
    final placed = const GraphIncrementalPlacer().placeGroup(
      obstacles: obstacles,
      group: localRects,
      anchor: anchor,
    );
    return {
      for (final indexed in elements.indexed)
        indexed.$2.id.id: placed[indexed.$1].elementPlacement,
    };
  }
}

extension on Iterable<skir.PageElement> {
  List<GraphGridRect> get graphRects => [
    for (final element in this)
      if (element.placement case skir.ElementPlacement_graphWrapper(
        :final value,
      ))
        GraphGridRect(
          x: value.x,
          y: value.y,
          width: value.width,
          height: value.height,
        ),
  ];
}

extension on skir.ElementPlacement {
  GraphGridRect? get graphRect => switch (this) {
    skir.ElementPlacement_graphWrapper(:final value) => GraphGridRect(
      x: value.x,
      y: value.y,
      width: value.width,
      height: value.height,
    ),
    _ => null,
  };
}

extension on GraphGridRect {
  skir.ElementPlacement get elementPlacement =>
      skir.ElementPlacement.createGraph(
        x: x,
        y: y,
        width: width,
        height: height,
      );
}
