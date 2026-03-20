import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";

class SceneCueIndex {
  const SceneCueIndex({
    required this.entries,
    required this.cuesById,
    required this.parentByCueId,
    required this.childrenByCueId,
    required this.rootCueIdsByEntryId,
  });

  factory SceneCueIndex.fromPageElements(List<PageElement> elements) {
    final entries = <PageEntry>[];
    final cuesById = <String, Cue>{};
    final parentByCueId = <String, String>{};
    final childrenByCueId = <String, List<String>>{};
    final rootCueIdsByEntryId = <String, List<String>>{};

    for (final element in elements) {
      switch (element) {
        case PageElementEntry(entry: final entry):
          entries.add(entry);
          rootCueIdsByEntryId[entry.id] = _childIds(_entryOutwardLinks(entry));
        case PageElementCue(cue: final cue):
          cuesById[cue.id] = cue;

          final parentIds = _parentIds(cue);
          assert(
            parentIds.length <= 1,
            "Cue ${cue.id} has multiple parents in scene data.",
          );

          if (parentIds.isNotEmpty) {
            parentByCueId[cue.id] = parentIds.single;
          }

          if (cue case Segment(outwardLinks: final outwardLinks)) {
            childrenByCueId[cue.id] = _childIds(outwardLinks);
          }
        case PageElementGroup():
      }
    }

    return SceneCueIndex(
      entries: entries,
      cuesById: cuesById,
      parentByCueId: parentByCueId,
      childrenByCueId: childrenByCueId,
      rootCueIdsByEntryId: rootCueIdsByEntryId,
    );
  }

  final List<PageEntry> entries;
  final Map<String, Cue> cuesById;
  final Map<String, String> parentByCueId;
  final Map<String, List<String>> childrenByCueId;
  final Map<String, List<String>> rootCueIdsByEntryId;
}

List<String> _childIds(List<ElementLink> links) {
  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in links) {
    if (link.path != "children") {
      continue;
    }
    if (!seenIds.add(link.otherId)) {
      continue;
    }
    ids.add(link.otherId);
  }

  return ids;
}

List<String> _parentIds(Cue cue) {
  final inwardLinks = switch (cue) {
    Segment(:final inwardLinks) => inwardLinks,
    Keyframe(:final inwardLinks) => inwardLinks,
    _ => throw StateError("Unknown cue type"),
  };

  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in inwardLinks) {
    if (link.path != "parent") {
      continue;
    }
    if (!seenIds.add(link.otherId)) {
      continue;
    }
    ids.add(link.otherId);
  }

  return ids;
}

List<ElementLink> _entryOutwardLinks(PageEntry entry) {
  return switch (entry) {
    DefinitionPageEntry(definition: final definition) =>
      definition.outwardEdges,
    NoBlueprintPageEntry(:final outwardLinks) => outwardLinks,
    _ => const <ElementLink>[],
  };
}
