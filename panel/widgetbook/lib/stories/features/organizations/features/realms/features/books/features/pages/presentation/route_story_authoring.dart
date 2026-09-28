part of "route.stories.dart";

AuthoringSessionState pageStoryAuthoring(
  RealmPageDefinition pageDefinition,
  List<PageElement> elements,
) {
  final page = Page(
    pageId: skir.ResourceId(value: "page:example-page-id"),
    bookId: skir.ResourceId(value: "book:example-book-id"),
    name: "Example",
    rootType: pageDefinition.type,
    chapter: "",
    priority: 0,
  );
  final catalog = (pageStoryPageCatalog(
    pageDefinition,
    elements,
  ) as RealmEditorCatalogReady).value.catalog;
  final codec = SkirEditorCodec(TypeRegistry(catalog));
  final content = page.content(referenceResourceTypes.page);
  final resource = skir.AuthoringResource(
    id: page.pageId,
    definition: CoreResourceDefinitionIds.page.toWire(),
    content: skir.TypedValueEnvelope(
      rootType: codec.encodeType(content.rootType).valueOrNull!,
      rootValue: codec.encodeValue(content.rootValue).valueOrNull!,
    ),
  );
  final elementResources = [
    for (final element in elements) _wireElement(element, codec),
  ];
  return AuthoringSessionState(
    generation: skir.CatalogGeneration(value: "widgetbook"),
    sequence: 1,
    resources: {
      page.pageId: resource,
      for (final element in elementResources) element.id: element,
    },
  );
}

skir.AuthoringResource _wireElement(
  PageElement element,
  SkirEditorCodec codec,
) {
  final (id, definition, data, placement) = switch (element) {
    PageElementEntry(entry: DefinitionPageEntry(:final definition)) => (
      definition.id,
      definition.elementDefinition,
      definition.data,
      switch (definition.placement.kind) {
        EntryPlacementKind.graph => GraphPlacement(
          x: definition.placement.x,
          y: definition.placement.y,
          width: definition.placement.width,
          height: definition.placement.height,
        ),
        EntryPlacementKind.timelineEntry => TimelineEntryPlacement(
          trackIndex: definition.placement.x,
        ),
      },
    ),
    PageElementCue(:final cue) => (
      cue.id,
      cue.elementDefinition,
      cue.data,
      switch (cue) {
        Segment(:final startFrame, :final endFrame) => TimelineSegmentPlacement(
          startFrame: startFrame,
          endFrame: endFrame,
        ),
        Keyframe(:final frame) => TimelineKeyframePlacement(frame: frame),
        _ => throw StateError("Unknown story cue"),
      },
    ),
    _ => throw StateError("Unsupported story element"),
  };
  return skir.AuthoringResource(
    id: skir.ResourceId(value: id),
    definition: CoreResourceDefinitionIds.element.toWire(),
    content: skir.TypedValueEnvelope(
      rootType: codec.encodeType(definition.rootType).valueOrNull!,
      rootValue: codec
          .encodeValue(data.withField("placement", placementValue(placement)))
          .valueOrNull!,
    ),
  );
}
