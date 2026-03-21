import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";

typedef SceneCueTimelineItem = (String, int, int, List<String>);

class SceneCueGraphIndex {
  const SceneCueGraphIndex({
    required this.entries,
    required this.cuesById,
    required this.parentByCueId,
    required this.childrenByCueId,
    required this.rootCueIdsByEntryId,
  });

  factory SceneCueGraphIndex.fromPageElements(List<PageElement> elements) {
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
          if (parentIds.isNotEmpty) {
            parentByCueId[cue.id] = parentIds.single;
          }

          if (cue case Segment(outwardLinks: final outwardLinks)) {
            childrenByCueId[cue.id] = _childIds(outwardLinks);
          }
        case PageElementGroup():
      }
    }

    return SceneCueGraphIndex(
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

List<SceneCueTimelineItem> collectSceneTimelineItems({
  required List<String> rootCueIds,
  required SceneCueGraphIndex index,
}) {
  final items = <SceneCueTimelineItem>[];
  for (final rootCueId in rootCueIds) {
    _collectTimelineItems(cueId: rootCueId, index: index, items: items);
  }
  return items;
}

int absoluteFrameForCue(String cueId, SceneCueGraphIndex index) {
  var currentCueId = cueId;
  var offset = 0;

  while (true) {
    final cue = index.cuesById[currentCueId];
    if (cue == null) break;

    final localStart = switch (cue) {
      Segment(startFrame: final start) => start,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };

    offset += localStart;

    final parentId = index.parentByCueId[currentCueId];
    if (parentId == null) break;
    currentCueId = parentId;
  }

  return offset;
}

void _collectTimelineItems({
  required String cueId,
  required SceneCueGraphIndex index,
  required List<SceneCueTimelineItem> items,
}) {
  final cue = index.cuesById[cueId];
  if (cue == null) return;

  final absoluteStartFrame = absoluteFrameForCue(cueId, index);
  final absoluteEndFrame = switch (cue) {
    Segment(startFrame: final start, endFrame: final end) =>
      absoluteStartFrame + (end - start),
    Keyframe() => absoluteStartFrame,
    _ => absoluteStartFrame,
  };

  final children = index.childrenByCueId[cueId] ?? const <String>[];

  items.add((cueId, absoluteStartFrame, absoluteEndFrame, children));

  for (final childId in children) {
    _collectTimelineItems(cueId: childId, index: index, items: items);
  }
}

List<String> _childIds(List<ElementLink> links) {
  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in links) {
    if (link.path != "children") continue;
    if (!seenIds.add(link.otherId)) continue;
    ids.add(link.otherId);
  }

  return ids;
}

List<String> _parentIds(Cue cue) {
  final inwardLinks = switch (cue) {
    Segment(:final inwardLinks) => inwardLinks,
    Keyframe(:final inwardLinks) => inwardLinks,
    _ => const <ElementLink>[],
  };

  final ids = <String>[];
  final seenIds = <String>{};

  for (final link in inwardLinks) {
    if (link.path != "parent") continue;
    if (!seenIds.add(link.otherId)) continue;
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
