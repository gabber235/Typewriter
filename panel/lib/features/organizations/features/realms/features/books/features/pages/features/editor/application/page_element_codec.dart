part of "page_elements.dart";

TypedValue _initialElementValue(
  ElementDefinition definition,
  TypeRegistry registry,
  SkirEditorCodec codec,
) {
  final initial = NamedType(
    definition.rootType,
  ).createInitialValue(registry: registry);
  final value = initial.valueOrNull;
  if (value == null) {
    throw ApiException.badRequest(initial.diagnostics.join("; "));
  }
  final encoded = codec.encodeValue(value);
  return encoded.valueOrNull ??
      (throw ApiException.badRequest(encoded.diagnostics.join("; ")));
}

List<PageElement> _decodePageElements(
  wire.PageDocument document,
  RealmEditorCatalogSnapshot snapshot,
  int authoringSequence,
) {
  final codec = SkirEditorCodec(
    TypeRegistry(bootstrapTypeCatalog(snapshot.catalog.definitions)),
  );
  final localIds = document.elements.map((element) => element.id.id).toSet();
  final local = <PageElement>[];
  for (final element in document.elements) {
    final catalogEntry = snapshot.elements[element.elementType];
    final definition = catalogEntry?.definition.toElementDefinition();
    final decoded = codec.decodeValue(element.value).valueOrNull;
    final data = decoded is RecordValue ? decoded : null;
    final outgoing = [
      for (final reference in document.references)
        if (reference.source.id == element.id.id)
          ElementLink(
            linkId: "${reference.source.id}:${reference.slot}",
            otherId: reference.target.id,
            path: reference.slot,
          ),
    ];
    final incoming = [
      for (final reference in document.references)
        if (reference.target.id == element.id.id)
          ElementLink(
            linkId: "${reference.source.id}:${reference.slot}",
            otherId: reference.source.id,
            path: reference.slot,
          ),
    ];
    final placement = element.placement;
    if (placement case wire.ElementPlacement_timelineSegmentWrapper(
      value: final timing,
    )) {
      if (definition != null && data != null) {
        local.add(
          PageElement.cue(
            cue: Cue.segment(
              id: element.id.id,
              authoringSequence: authoringSequence,
              startFrame: timing.startFrame,
              endFrame: timing.endFrame,
              elementDefinition: definition,
              data: data,
              inwardLinks: incoming,
              outwardLinks: outgoing,
            ),
          ),
        );
      }
      continue;
    }
    if (placement case wire.ElementPlacement_timelineKeyframeWrapper(
      value: final timing,
    )) {
      if (definition != null && data != null) {
        local.add(
          PageElement.cue(
            cue: Cue.keyframe(
              id: element.id.id,
              authoringSequence: authoringSequence,
              frame: timing.frame,
              elementDefinition: definition,
              data: data,
              inwardLinks: incoming,
            ),
          ),
        );
      }
      continue;
    }
    final entryPlacement = switch (placement) {
      wire.ElementPlacement_graphWrapper(:final value) => EntryPlacement(
        x: value.x,
        y: value.y,
        width: value.width,
        height: value.height,
      ),
      wire.ElementPlacement_timelineEntryWrapper(:final value) =>
        EntryPlacement(
          kind: EntryPlacementKind.timelineEntry,
          x: value.trackIndex,
          y: 0,
          width: 1,
          height: 1,
        ),
      _ => const EntryPlacement(x: 0, y: 0, width: 1, height: 1),
    };
    final entry = definition != null && data != null
        ? PageEntry.definition(
            definition: EntryDefinition(
              id: element.id.id,
              authoringSequence: authoringSequence,
              name: element.name,
              elementDefinition: definition,
              placement: entryPlacement,
              data: data,
              inwardEdges: incoming,
              outwardEdges: outgoing,
            ),
          )
        : PageEntry.missingElementDefinition(
            id: element.id.id,
            name: element.name,
            placement: entryPlacement,
            inwardLinks: incoming,
            outwardLinks: outgoing,
          );
    local.add(PageElement.entry(entry: entry));
  }

  final related = <PageElement>[];
  for (final summary in document.crossPageTargets) {
    if (localIds.contains(summary.id.id)) continue;
    if (!summary.exists || summary.elementType == null) {
      related.add(
        PageElement.entry(entry: PageEntry.nonexistent(id: summary.id.id)),
      );
      continue;
    }
    final catalogEntry = snapshot.elements[summary.elementType];
    final page = summary.page;
    if (catalogEntry == null || page == null) continue;
    related.add(
      PageElement.entry(
        entry: PageEntry.reference(
          id: summary.id.id,
          name: summary.name ?? summary.id.id,
          elementDefinition: catalogEntry.definition.toElementDefinition(),
          pageId: page.id,
        ),
      ),
    );
  }
  return [...local, ...related];
}

RecordValue _elementValue(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.data,
  PageElementCue(cue: Segment(:final data) || Keyframe(:final data)) => data,
  _ => throw StateError("The element has no editable value"),
};

String _elementName(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.name,
  PageElementCue(:final cue) => cue.elementDefinition.name,
  _ => element.id,
};
