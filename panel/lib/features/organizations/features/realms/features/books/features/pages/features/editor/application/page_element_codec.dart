part of "page_elements.dart";

List<PageElement> _decodePageElements(
  skir.ResourceId pageId,
  Iterable<skir.AuthoringResource> resources,
  Iterable<skir.AuthoringEdge> edges,
  Map<skir.ResourceId, skir.PresentationSubject> subjects,
  RealmEditorCatalogSnapshot snapshot,
) {
  final codec = TypedAuthoringCodec(snapshot);
  final byId = {for (final resource in resources) resource.id: resource};
  final page = byId[pageId];
  if (page == null) return const [];
  final pageType = codec.decodeResourceOrThrow(page).content.rootType;
  final ownershipRelation = snapshot.relations.values
      .where(
        (relation) =>
            relation.sourceEndpoint?.owner == pageType &&
            relation.sourceEndpoint?.path == DataPath.root.field("elements"),
      )
      .singleOrNull;
  if (ownershipRelation == null) {
    throw StateError("The Page elements relation is unavailable");
  }
  final localIds = <skir.ResourceId>{
    for (final edge in edges)
      if (edge.source == pageId)
        if (edge.origin
            case skir.AuthoringEdgeOrigin_declaredRelationWrapper(:final value)
            when value.relationId.value == ownershipRelation.id &&
                byId[edge.target]?.definition.toDomain() ==
                    CoreResourceDefinitionIds.element)
          edge.target,
  };
  final ordinaryEdges = [
    for (final edge in edges)
      if (edge.origin is skir.AuthoringEdgeOrigin_ordinaryReferenceWrapper)
        edge,
  ];
  final local = <PageElement>[];
  for (final id in localIds) {
    final resource = byId[id];
    if (resource == null) continue;
    final decoded = codec.decodeResourceOrThrow(resource);
    final data = decoded.content.rootValue;
    final placementValue = elementPlacementPath.read(data).valueOrNull;
    if (placementValue == null) continue;
    final placement = decodePlacement(placementValue);
    final definition = snapshot.elements.values
        .where((entry) => entry.definition.type == decoded.content.rootType)
        .firstOrNull
        ?.definition
        .toElementDefinition();
    final outgoing = [
      for (final edge in ordinaryEdges)
        if (edge.source == id) _elementLink(edge, edge.target, codec.registry),
    ];
    final incoming = [
      for (final edge in ordinaryEdges)
        if (edge.target == id) _elementLink(edge, edge.source, codec.registry),
    ];

    if (placement case TimelineSegmentPlacement(
      :final startFrame,
      :final endFrame,
    )) {
      if (definition != null && data is RecordValue) {
        local.add(
          PageElement.cue(
            cue: Cue.segment(
              id: id.value,
              startFrame: startFrame,
              endFrame: endFrame,
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
    if (placement case TimelineKeyframePlacement(:final frame)) {
      if (definition != null && data is RecordValue) {
        local.add(
          PageElement.cue(
            cue: Cue.keyframe(
              id: id.value,
              frame: frame,
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
      GraphPlacement(:final x, :final y, :final width, :final height) =>
        EntryPlacement(x: x, y: y, width: width, height: height),
      TimelineEntryPlacement(:final trackIndex) => EntryPlacement(
        kind: EntryPlacementKind.timelineEntry,
        x: trackIndex,
        y: 0,
        width: 1,
        height: 1,
      ),
      _ => const EntryPlacement(x: 0, y: 0, width: 1, height: 1),
    };
    final entry = definition != null && data is RecordValue
        ? PageEntry.definition(
            definition: EntryDefinition(
              id: id.value,
              elementDefinition: definition,
              placement: entryPlacement,
              data: data,
              inwardEdges: incoming,
              outwardEdges: outgoing,
            ),
          )
        : PageEntry.missingElementDefinition(
            id: id.value,
            name: data is RecordValue
                ? data.requiredStringField("name")
                : id.value,
            placement: entryPlacement,
            inwardLinks: incoming,
            outwardLinks: outgoing,
          );
    local.add(PageElement.entry(entry: entry));
  }

  final relatedIds = <skir.ResourceId>{
    for (final edge in ordinaryEdges)
      if (localIds.contains(edge.source) && !localIds.contains(edge.target))
        edge.target,
    for (final edge in ordinaryEdges)
      if (localIds.contains(edge.target) && !localIds.contains(edge.source))
        edge.source,
  };
  final related = <PageElement>[];
  for (final id in relatedIds) {
    final resource = byId[id];
    final inward = [
      for (final edge in ordinaryEdges)
        if (edge.target == id && localIds.contains(edge.source))
          _elementLink(edge, edge.source, codec.registry),
    ];
    final outward = [
      for (final edge in ordinaryEdges)
        if (edge.source == id && localIds.contains(edge.target))
          _elementLink(edge, edge.target, codec.registry),
    ];
    if (resource == null) {
      related.add(
        PageElement.entry(entry: PageEntry.nonexistent(id: id.value)),
      );
      continue;
    }
    final decoded = codec.decodeResource(resource).valueOrNull;
    final definition = decoded == null
        ? null
        : snapshot.elements.values
              .where(
                (entry) => entry.definition.type == decoded.content.rootType,
              )
              .firstOrNull
              ?.definition
              .toElementDefinition();
    final owner = edges
        .where((edge) {
          if (edge.target != id) return false;
          return switch (edge.origin) {
            skir.AuthoringEdgeOrigin_declaredRelationWrapper(:final value) =>
              value.relationId.value == ownershipRelation.id,
            _ => false,
          };
        })
        .map((edge) => edge.source)
        .firstOrNull;
    final subject = subjects[id];
    final typedSubject = subject == null
        ? null
        : codec.decodeSubject(subject).valueOrNull;
    final name = _resourceName(resource, codec) ?? id.value;
    related.add(
      PageElement.entry(
        entry: definition != null && owner != null && typedSubject != null
            ? PageEntry.reference(
                id: id.value,
                name: name,
                subject: typedSubject,
                elementDefinition: definition,
                pageId: owner.value,
                inwardLinks: inward,
                outwardLinks: outward,
              )
            : PageEntry.unavailableReference(
                id: id.value,
                name: name,
                inwardLinks: inward,
                outwardLinks: outward,
              ),
      ),
    );
  }
  return [...local, ...related];
}

ElementLink _elementLink(
  skir.AuthoringEdge edge,
  skir.ResourceId other,
  TypeRegistry registry,
) {
  final origin = edge.origin;
  if (origin is! skir.AuthoringEdgeOrigin_ordinaryReferenceWrapper) {
    throw StateError("Expected an ordinary reference edge");
  }
  final path = SkirEditorCodec(registry)
      .decodePath(origin.value.path)
      .valueOrNull;
  return ElementLink(
    linkId: edge.id.value,
    otherId: other.value,
    path: origin.value.slot,
    sourcePath: path,
  );
}

String? _resourceName(
  skir.AuthoringResource resource,
  TypedAuthoringCodec codec,
) {
  final value = codec.decodeResource(resource).valueOrNull?.content.rootValue;
  if (value is! RecordValue) return null;
  final name = value.fields["name"];
  return name is StringValue ? name.value : null;
}

String _elementName(PageElement element) => switch (element) {
  PageElementEntry(entry: DefinitionPageEntry(:final definition)) =>
    definition.name,
  PageElementEntry(entry: MissingElementDefinitionPageEntry(:final name)) =>
    name,
  PageElementEntry(entry: ReferencePageEntry(:final name)) => name,
  PageElementEntry(entry: UnavailableReferencePageEntry(:final name)) => name,
  PageElementEntry(entry: NonexistentPageEntry(:final id)) => id,
  PageElementCue(:final cue) => cue.elementDefinition.name,
  _ => "Element",
};
