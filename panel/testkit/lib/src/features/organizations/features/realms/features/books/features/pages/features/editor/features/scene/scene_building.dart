part of "scene.dart";

extension SceneElementsDslBuilding on SceneElementsDsl {
  List<PageElement> build() {
    if (_entries.isEmpty) return const [];

    final elements = <PageElement>[];
    final usedIds = <String>{};

    for (var entryIndex = 0; entryIndex < _entries.length; entryIndex++) {
      final entryDsl = _entries[entryIndex];
      assert(usedIds.add(entryDsl.id), "Duplicate scene id ${entryDsl.id}");

      final entryName = entryDsl.name ?? "Scene Entry ${entryIndex + 1}";
      final entryBlueprint = entryDsl.elementDefinition(
        id: "${entryDsl.id}_blueprint",
        name: entryName,
      );
      final outwardEdges = <ElementLink>[];
      final cueElements = <PageElement>[];

      for (
        var childIndex = 0;
        childIndex < entryDsl.children.length;
        childIndex++
      ) {
        final child = entryDsl.children[childIndex];
        final linkId = entryDsl.id.linkTo(child.id, childIndex);
        outwardEdges.add(
          ElementLink(linkId: linkId, otherId: child.id, path: "children"),
        );
        cueElements.addAll(
          child.buildElements(
            parentId: entryDsl.id,
            parentLinkId: linkId,
            usedIds: usedIds,
          ),
        );
      }

      final entryData = {
        "entryType": StringValue(
          outwardEdges.length.isEven ? "entity" : "title",
        ),
        "label": StringValue(entryName),
      }.mergedWith(entryDsl.data);

      final entry = EntryDefinition(
        id: entryDsl.id,
        name: entryName,
        elementDefinition: entryBlueprint,
        placement:
            entryDsl.placement ??
            EntryPlacement(
              x: 40 + ((entryIndex % 4) * 220),
              y: 32 + ((entryIndex ~/ 4) * 120),
              width: 180,
              height: 72,
            ),
        data: entryData,
        inwardEdges: const [],
        outwardEdges: outwardEdges,
      );

      elements
        ..add(PageElement.entry(entry: PageEntry.definition(definition: entry)))
        ..addAll(cueElements);
    }

    return elements;
  }
}

extension on SceneCueDsl {
  List<PageElement> buildElements({
    required String parentId,
    required String parentLinkId,
    required Set<String> usedIds,
  }) {
    assert(usedIds.add(id), "Duplicate scene id $id");

    if (this case SceneKeyframeDsl keyframeDsl) {
      final keyframeName = keyframeDsl.name ?? id;
      final keyframe = Cue.keyframe(
        id: keyframeDsl.id,
        elementDefinition: keyframeDsl.elementDefinition(
          id: "${keyframeDsl.id}_blueprint",
          name: keyframeName,
        ),
        frame: keyframeDsl.frame,
        data: {
          "channel": const StringValue("scene"),
          "event": const StringValue("trigger"),
          "label": StringValue(keyframeName),
        }.mergedWith(keyframeDsl.data),
        inwardLinks: [
          ElementLink(linkId: parentLinkId, otherId: parentId, path: "parent"),
        ],
      );

      return [PageElement.cue(cue: keyframe)];
    }

    final segmentDsl = this as SceneSegmentDsl;
    final segmentName = segmentDsl.name ?? id;
    final outwardLinks = <ElementLink>[];
    final children = <PageElement>[];

    for (
      var childIndex = 0;
      childIndex < segmentDsl.children.length;
      childIndex++
    ) {
      final child = segmentDsl.children[childIndex];
      final linkId = segmentDsl.id.linkTo(child.id, childIndex);
      outwardLinks.add(
        ElementLink(linkId: linkId, otherId: child.id, path: "children"),
      );
      children.addAll(
        child.buildElements(
          parentId: segmentDsl.id,
          parentLinkId: linkId,
          usedIds: usedIds,
        ),
      );
    }

    final segment = Cue.segment(
      id: segmentDsl.id,
      elementDefinition: segmentDsl.elementDefinition(
        id: "${segmentDsl.id}_blueprint",
        name: segmentName,
      ),
      startFrame: segmentDsl.start,
      endFrame: segmentDsl.end,
      data: {
        "channel": const StringValue("scene"),
        "label": StringValue(segmentName),
        "mode": const StringValue("cinematic"),
      }.mergedWith(segmentDsl.data),
      inwardLinks: [
        ElementLink(linkId: parentLinkId, otherId: parentId, path: "parent"),
      ],
      outwardLinks: outwardLinks,
    );

    return [PageElement.cue(cue: segment), ...children];
  }
}

extension on _SceneEntryDsl {
  ElementDefinition elementDefinition({
    required String id,
    required String name,
  }) {
    return generateSceneElementDefinition(
      id: id,
      name: name,
      icon: icon ?? "solar:video-frame-bold",
    ).withColor(color);
  }
}

extension on SceneCueDsl {
  ElementDefinition elementDefinition({
    required String id,
    required String name,
  }) {
    if (this case SceneKeyframeDsl(:final icon, :final color)) {
      return generateSceneElementDefinition(
        id: id,
        name: name,
        icon: icon ?? "fa7-solid:star",
      ).withColor(color);
    }
    final segment = this as SceneSegmentDsl;
    return generateSceneElementDefinition(
      id: id,
      name: name,
      icon: segment.icon ?? "fa-solid:video",
    ).withColor(segment.color);
  }
}

extension on ElementDefinition {
  ElementDefinition withColor(Color? value) {
    if (value == null) return this;
    return copyWith(color: value);
  }
}

extension on Map<String, DataValue> {
  RecordValue mergedWith(RecordValue? overrides) {
    if (overrides == null) return RecordValue(this);
    return RecordValue({...this, ...overrides.fields});
  }
}

extension on String {
  String linkTo(String childId, int index) => "${this}_${childId}_$index";
}
