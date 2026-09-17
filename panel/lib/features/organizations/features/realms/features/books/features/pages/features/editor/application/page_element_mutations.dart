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
    EntryPlacementKind placementKind,
  ) async {
    state.ensureReady();
    if (definitions.isEmpty) return const [];
    final codec = _codec();
    final registry = codec.registry;
    final ids = [
      for (final _ in definitions) newResourceId(AuthoringResource.element).id,
    ];
    final graphY = state.requireValue
        .whereType<PageElementEntry>()
        .map((element) => element.entry)
        .whereType<DefinitionPageEntry>()
        .map((entry) => entry.definition.placement.y + 1)
        .fold(0, (maximum, value) => value > maximum ? value : maximum);

    await _submit(
      _commands.createElements([
        for (final indexed in definitions.indexed)
          skir.PageElement(
            id: recordId("element:${ids[indexed.$1]}"),
            page: _pageId,
            elementType: indexed.$2.typeId.uuid,
            schemaRevision: indexed.$2.rootType.revision,
            name: indexed.$2.name,
            value: _initialElementValue(indexed.$2, registry, codec.codec),
            placement: switch (placementKind) {
              EntryPlacementKind.graph => skir.ElementPlacement.createGraph(
                x: 0,
                y: graphY + indexed.$1,
                width: 4,
                height: 1,
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

  Future<List<String>> duplicateAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return const [];
    final elements = {for (final item in _document.elements) item.id.id: item};
    final ids = {
      for (final id in elementIds) id: newResourceId(AuthoringResource.element),
    };
    await _submit(
      _commands.duplicateElements({
        for (final id in elementIds) elements[id]!: ids[id]!,
      }),
    );
    return [for (final id in elementIds) ids[id]!.id];
  }

  Future<void> moveEntriesToPage(
    List<String> elementIds,
    String targetPageId,
  ) async {
    if (elementIds.isEmpty || targetPageId == _pageId.id) return;
    final elements = {for (final item in _document.elements) item.id.id: item};
    await _submit(
      _commands.moveElementsToPage([
        for (final id in elementIds) elements[id]!,
      ], recordId("page:$targetPageId")),
    );
  }
}
