part of "page_elements.dart";

mixin _PageElementMutations on _$PageElements, _PageElementMutationContext {
  void optimisticMoveAll(List<(String, int, int)> changed) {
    final positions = {for (final item in changed) item.$1: (item.$2, item.$3)};
    state = AsyncData([
      for (final element in state.requireValue)
        if (positions[element.id] case final position?)
          element.moveTo(position.$1, position.$2)
        else
          element,
    ]);
  }

  void optimisticResizeAll(List<(String, int, int)> changed) {
    final sizes = {for (final item in changed) item.$1: (item.$2, item.$3)};
    state = AsyncData([
      for (final element in state.requireValue)
        if (sizes[element.id] case final size?)
          element.resizeTo(size.$1, size.$2)
        else
          element,
    ]);
  }

  void optimisticCuesUpdate(List<(String, int, int)> changed) {
    final timings = {for (final item in changed) item.$1: (item.$2, item.$3)};
    state = AsyncData([
      for (final element in state.requireValue)
        if (timings[element.id] case final timing?)
          element.updateCueTo(timing.$1, timing.$2)
        else
          element,
    ]);
  }

  Future<void> moveAll(List<(String, int, int)> changed) => _optimisticPatch(
    changed,
    optimisticMoveAll,
    (element, x, y) => wire.ElementPlacement.createGraph(
      x: x,
      y: y,
      width: _graph(element).width,
      height: _graph(element).height,
    ),
  );

  Future<void> resizeAll(List<(String, int, int)> changed) => _optimisticPatch(
    changed,
    optimisticResizeAll,
    (element, width, height) => wire.ElementPlacement.createGraph(
      x: _graph(element).x,
      y: _graph(element).y,
      width: width,
      height: height,
    ),
  );

  Future<void> updateCues(List<(String, int, int)> changed) => _optimisticPatch(
    changed,
    optimisticCuesUpdate,
    (element, start, end) => switch (element.placement) {
      wire.ElementPlacement_timelineSegmentWrapper() =>
        wire.ElementPlacement.createTimelineSegment(
          startFrame: start,
          endFrame: end,
        ),
      wire.ElementPlacement_timelineKeyframeWrapper() =>
        wire.ElementPlacement.createTimelineKeyframe(frame: start),
      _ => throw ApiException.badRequest("The element is not a cue"),
    },
  );

  Future<void> _optimisticPatch(
    List<(String, int, int)> changed,
    void Function(List<(String, int, int)>) optimistic,
    wire.ElementPlacement Function(wire.PageElement, int, int) placement,
  ) async {
    state.ensureReady();
    if (changed.isEmpty) return;
    final elements = {for (final item in _document.elements) item.id.id: item};
    optimistic(changed);
    try {
      await _submit(
        _commands.changeElementPlacements([
          for (final item in changed)
            (
              elements[item.$1]!,
              placement(elements[item.$1]!, item.$2, item.$3),
            ),
        ]),
      );
    } on Object {
      _replaceFromSession();
      rethrow;
    }
  }

  wire.GraphPlacement _graph(wire.PageElement element) =>
      switch (element.placement) {
        wire.ElementPlacement_graphWrapper(:final value) => value,
        _ => throw ApiException.badRequest("The element is not on a graph"),
      };

  Future<void> deleteAll(List<String> elementIds) async {
    state.ensureReady();
    if (elementIds.isEmpty) return;
    state = AsyncData(
      state.requireValue
          .where((element) => !elementIds.contains(element.id))
          .toList(),
    );
    try {
      await _submit(
        _commands.deleteElements([
          for (final id in elementIds) recordId("element:$id"),
        ]),
      );
    } on Object {
      _replaceFromSession();
      rethrow;
    }
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
          wire.PageElement(
            id: recordId("element:${ids[indexed.$1]}"),
            page: _pageId,
            elementType: indexed.$2.typeId.uuid,
            schemaRevision: indexed.$2.rootType.revision,
            name: indexed.$2.name,
            value: _initialElementValue(indexed.$2, registry, codec.codec),
            placement: switch (placementKind) {
              EntryPlacementKind.graph => wire.ElementPlacement.createGraph(
                x: 0,
                y: graphY + indexed.$1,
                width: 4,
                height: 1,
              ),
              EntryPlacementKind.timelineEntry =>
                wire.ElementPlacement.createTimelineEntry(
                  trackIndex: indexed.$1,
                ),
            },
          ),
      ]),
    );
    _replaceFromSession();
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
    _replaceFromSession();
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
    state = AsyncData(
      state.requireValue
          .where((element) => !elementIds.contains(element.id))
          .toList(),
    );
  }
}
