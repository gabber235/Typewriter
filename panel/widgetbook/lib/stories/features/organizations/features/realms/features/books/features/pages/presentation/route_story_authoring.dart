part of "route.stories.dart";

AuthoringSessionState pageStoryAuthoring(
  RealmPageDefinition pageDefinition,
  List<PageElement> elements,
) {
  final page = skir.Page(
    id: recordId("page:example-page-id"),
    book: recordId("book:example-book-id"),
    name: "Example",
    kind: pageDefinition.kind.toSkir(),
    chapter: "",
    priority: 0,
  );
  final catalog = (pageStoryPageCatalog(
    pageDefinition,
    elements,
  ) as RealmEditorCatalogReady).value.catalog;
  final codec = SkirEditorCodec(TypeRegistry(catalog));
  return AuthoringSessionState(
    sequence: 1,
    pages: {page.id: page},
    documents: {
      page.id: skir.PageDocument(
        page: page,
        elements: [
          for (final element in elements) _wireElement(element, page, codec),
        ],
        references: [
          for (final element in elements)
            for (final link in switch (element) {
              PageElementEntry(:final entry) => entry.links.$2,
              PageElementCue(cue: Segment(:final outwardLinks)) => outwardLinks,
              _ => const <ElementLink>[],
            })
              skir.PageReference(
                source: recordId("element:${element.id}"),
                slot: link.path,
                target: recordId("element:${link.otherId}"),
              ),
        ],
        crossPageTargets: const [],
        crossPageSources: const [],
        diagnostics: const [],
        compileStatus: skir.PageCompileStatus.createBlocked(
          lastActiveManifestId: null,
          diagnosticCount: 0,
        ),
      ),
    },
  );
}

skir.PageElement _wireElement(
  PageElement element,
  skir.Page page,
  SkirEditorCodec codec,
) {
  final (id, name, definition, data, placement) = switch (element) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) => (
      definition.id,
      definition.name,
      definition.elementDefinition,
      definition.data,
      switch (definition.placement.kind) {
        EntryPlacementKind.graph => skir.ElementPlacement.createGraph(
          x: definition.placement.x,
          y: definition.placement.y,
          width: definition.placement.width,
          height: definition.placement.height,
        ),
        EntryPlacementKind.timelineEntry =>
          skir.ElementPlacement.createTimelineEntry(
            trackIndex: definition.placement.x,
          ),
      },
    ),
    PageElementCue(:final cue) => (
      cue.id,
      cue.elementDefinition.name,
      cue.elementDefinition,
      cue.data,
      switch (cue) {
        Segment(:final startFrame, :final endFrame) =>
          skir.ElementPlacement.createTimelineSegment(
            startFrame: startFrame,
            endFrame: endFrame,
          ),
        Keyframe(:final frame) => skir.ElementPlacement.createTimelineKeyframe(
          frame: frame,
        ),
        _ => throw StateError("Unknown story cue"),
      },
    ),
    _ => throw StateError("Unsupported story element"),
  };
  return skir.PageElement(
    id: recordId("element:$id"),
    page: page.id,
    name: name,
    elementType: definition.typeId.uuid,
    schemaRevision: definition.rootType.revision,
    value: codec.encodeValue(data).valueOrNull!,
    placement: placement,
  );
}
