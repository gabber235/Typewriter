import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/empty_entry_page.dart";
import "package:typewriter_panel/widgets/app/components/entry.dart";
import "package:typewriter_panel/widgets/app/components/inner_element_node.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/generic/components/shimmer.dart";
import "package:typewriter_panel/widgets/generic/components/surface.dart";

class EntryScene extends HookConsumerWidget {
  const EntryScene({required this.pageId, super.key});

  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageElements = ref.watch(pageElementsProvider(pageId));

    return pageElements(
      name: "elements",
      builder: (elements) {
        if (elements.isEmpty) {
          return EmptyEntryPage();
        }

        final sceneView = _SceneViewData.create(
          pageId: pageId,
          elements: elements,
        );

        assert(
          sceneView.timelineData.tracks.length ==
              elements.whereType<PageElementEntry>().length,
          "Scene track count must match page entry count.",
        );

        return Timeline(
          data: sceneView.timelineData,
          onElementMoved: (change) => _commitSceneMove(
            ref: ref,
            pageId: pageId,
            elements: elements,
            cueId: change.id.id,
            absoluteStartFrame: change.absoluteStartFrame,
            absoluteEndFrame: change.absoluteEndFrame,
          ),
          onElementResized: (change) => _commitSceneResize(
            ref: ref,
            pageId: pageId,
            elements: elements,
            cueId: change.id.id,
            absoluteStartFrame: change.absoluteStartFrame,
            absoluteEndFrame: change.absoluteEndFrame,
          ),
        );
      },
      loading: (_) => ShimmerBox.rectangle(
        width: double.infinity,
        height: double.infinity,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _ResolvedCueFrames {
  const _ResolvedCueFrames({
    required this.localStartFrame,
    required this.localEndFrame,
    required this.absoluteStartFrame,
    required this.absoluteEndFrame,
  });

  final int localStartFrame;
  final int localEndFrame;
  final int absoluteStartFrame;
  final int absoluteEndFrame;
}

_ResolvedCueFrames _resolveCueFrames({
  required String cueId,
  required int absoluteStartFrame,
  required int absoluteEndFrame,
  required _CueIndex index,
  required _ParentInfo? parentInfo,
  required TimelineInteractionMode mode,
}) {
  final cue = index.cuesById[cueId];
  if (cue == null) {
    return _ResolvedCueFrames(
      localStartFrame: absoluteStartFrame,
      localEndFrame: absoluteEndFrame,
      absoluteStartFrame: absoluteStartFrame,
      absoluteEndFrame: absoluteEndFrame,
    );
  }

  final isRoot = parentInfo == null;
  final parentStartFrame = parentInfo?.startFrame ?? 0;

  switch (mode) {
    case TimelineInteractionMode.move:
      if (isRoot) {
        return _ResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final desiredLocalStart = absoluteStartFrame - parentStartFrame;
      final duration = absoluteEndFrame - absoluteStartFrame;
      final maxLocalStart = parentInfo?.duration != null
          ? math.max(0, parentInfo!.duration! - duration)
          : desiredLocalStart;
      final resolvedLocalStart = desiredLocalStart
          .clamp(0, math.max(0, maxLocalStart))
          .toInt();

      return _ResolvedCueFrames(
        localStartFrame: resolvedLocalStart,
        localEndFrame: resolvedLocalStart + duration,
        absoluteStartFrame: parentStartFrame + resolvedLocalStart,
        absoluteEndFrame: parentStartFrame + resolvedLocalStart + duration,
      );

    case TimelineInteractionMode.resizeStart:
      if (cue is! Segment) {
        return _ResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final baseLocalStart = cue.startFrame;
      final baseLocalEnd = cue.endFrame;

      if (isRoot) {
        final newDuration = absoluteEndFrame - absoluteStartFrame;
        final newLocalStart = baseLocalEnd - newDuration;
        return _ResolvedCueFrames(
          localStartFrame: newLocalStart.clamp(0, baseLocalEnd).toInt(),
          localEndFrame: baseLocalEnd,
          absoluteStartFrame: newLocalStart.clamp(0, baseLocalEnd).toInt(),
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final requiredDuration = _requiredDurationForChildren(cueId, index);
      final maxStart = baseLocalEnd - requiredDuration;
      final newLocalStart = absoluteStartFrame - parentStartFrame;
      final clampedLocalStart = newLocalStart
          .clamp(0, math.max(0, maxStart))
          .toInt();

      return _ResolvedCueFrames(
        localStartFrame: clampedLocalStart,
        localEndFrame: baseLocalEnd,
        absoluteStartFrame: parentStartFrame + clampedLocalStart,
        absoluteEndFrame: absoluteEndFrame,
      );

    case TimelineInteractionMode.resizeEnd:
      if (cue is! Segment) {
        return _ResolvedCueFrames(
          localStartFrame: absoluteStartFrame,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final baseLocalStart = cue.startFrame;
      final baseLocalEnd = cue.endFrame;

      if (isRoot) {
        return _ResolvedCueFrames(
          localStartFrame: baseLocalStart,
          localEndFrame: absoluteEndFrame,
          absoluteStartFrame: absoluteStartFrame,
          absoluteEndFrame: absoluteEndFrame,
        );
      }

      final minEnd =
          baseLocalStart + _requiredDurationForChildren(cueId, index);
      final maxEnd = parentInfo?.duration ?? absoluteEndFrame;
      final newLocalEnd = (absoluteEndFrame - parentStartFrame)
          .clamp(minEnd, maxEnd)
          .toInt();

      return _ResolvedCueFrames(
        localStartFrame: baseLocalStart,
        localEndFrame: newLocalEnd,
        absoluteStartFrame: absoluteStartFrame,
        absoluteEndFrame: parentStartFrame + newLocalEnd,
      );
  }
}

int _requiredDurationForChildren(String cueId, _CueIndex index) {
  var requiredDuration = 0;

  for (final childCueId in index.childrenByCueId[cueId] ?? const <String>[]) {
    final childCue = index.cuesById[childCueId];
    if (childCue == null) continue;

    final childEndFrame = switch (childCue) {
      Segment(endFrame: final endFrame) => endFrame,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };
    requiredDuration = math.max(requiredDuration, childEndFrame);
  }

  return requiredDuration;
}

_ParentInfo? _findParentInfo(String cueId, _CueIndex index) {
  final parentCueId = index.parentByCueId[cueId];
  if (parentCueId == null) return null;

  final parentCue = index.cuesById[parentCueId];
  if (parentCue == null) return null;

  final parentStartFrame = switch (parentCue) {
    Segment(startFrame: final startFrame) => startFrame,
    Keyframe(frame: final frame) => frame,
    _ => 0,
  };

  final parentDuration = switch (parentCue) {
    Segment(startFrame: final start, endFrame: final end) => end - start,
    Keyframe() => null,
    _ => null,
  };

  return _ParentInfo(startFrame: parentStartFrame, duration: parentDuration);
}

class _ParentInfo {
  const _ParentInfo({required this.startFrame, this.duration});

  final int startFrame;
  final int? duration;
}

Future<void> _commitSceneMove({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required String cueId,
  required int absoluteStartFrame,
  required int absoluteEndFrame,
}) {
  final index = _CueIndex.fromPageElements(elements);
  final parentInfo = _findParentInfo(cueId, index);

  final resolved = _resolveCueFrames(
    cueId: cueId,
    absoluteStartFrame: absoluteStartFrame,
    absoluteEndFrame: absoluteEndFrame,
    index: index,
    parentInfo: parentInfo,
    mode: TimelineInteractionMode.move,
  );

  return ref.read(pageElementsProvider(pageId).notifier).moveCues([
    (cueId, resolved.localStartFrame, resolved.localEndFrame),
  ]);
}

Future<void> _commitSceneResize({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required String cueId,
  required int absoluteStartFrame,
  required int absoluteEndFrame,
}) {
  final index = _CueIndex.fromPageElements(elements);

  final baseCue = index.cuesById[cueId];
  if (baseCue is! Segment) return Future.value();

  final baseStartFrame = baseCue.startFrame;
  final baseAbsoluteStart = _absoluteFrame(baseStartFrame, cueId, index);

  final mode = absoluteStartFrame == baseAbsoluteStart
      ? TimelineInteractionMode.resizeEnd
      : TimelineInteractionMode.resizeStart;

  final parentInfo = _findParentInfo(cueId, index);

  final resolved = _resolveCueFrames(
    cueId: cueId,
    absoluteStartFrame: absoluteStartFrame,
    absoluteEndFrame: absoluteEndFrame,
    index: index,
    parentInfo: parentInfo,
    mode: mode,
  );

  return ref.read(pageElementsProvider(pageId).notifier).resizeCues([
    (cueId, resolved.localStartFrame, resolved.localEndFrame),
  ]);
}

int _absoluteFrame(int localFrame, String cueId, _CueIndex index) {
  var currentCueId = cueId;
  var absoluteOffset = localFrame;

  while (true) {
    final parentCueId = index.parentByCueId[currentCueId];
    if (parentCueId == null) break;

    final parentCue = index.cuesById[parentCueId];
    if (parentCue == null) break;

    final parentStartFrame = switch (parentCue) {
      Segment(startFrame: final startFrame) => startFrame,
      Keyframe(frame: final frame) => frame,
      _ => 0,
    };

    absoluteOffset += parentStartFrame;
    currentCueId = parentCueId;
  }

  return absoluteOffset;
}

class _CueIndex {
  const _CueIndex({
    required this.entries,
    required this.cuesById,
    required this.parentByCueId,
    required this.childrenByCueId,
    required this.rootCueIdsByEntryId,
  });

  factory _CueIndex.fromPageElements(List<PageElement> elements) {
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

    return _CueIndex(
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

class _SceneViewData {
  const _SceneViewData({required this.timelineData});

  factory _SceneViewData.create({
    required String pageId,
    required List<PageElement> elements,
  }) {
    final index = _CueIndex.fromPageElements(elements);
    final entriesById = <String, PageEntry>{};
    final cuesById = <String, Cue>{};

    for (final element in elements) {
      switch (element) {
        case PageElementEntry(entry: final entry):
          entriesById[entry.id] = entry;
        case PageElementCue(cue: final cue):
          cuesById[cue.id] = cue;
        case PageElementGroup():
      }
    }

    final tracks = [
      for (final entry in index.entries)
        TimelineTrack(
          id: TimelineIdentifier(entry.id),
          header: (context) => EntryNode(entry: entry),
          elements: _buildTimelineElements(
            pageId: pageId,
            rootCueIds: index.rootCueIdsByEntryId[entry.id] ?? const <String>[],
            cuesById: cuesById,
            index: index,
          ),
        ),
    ];

    return _SceneViewData(timelineData: TimelineData(tracks: tracks));
  }

  final TimelineData timelineData;
}

List<TimelineElement> _buildTimelineElements({
  required String pageId,
  required List<String> rootCueIds,
  required Map<String, Cue> cuesById,
  required _CueIndex index,
}) {
  final items = <(String, int, int, List<String>)>[];

  for (final rootCueId in rootCueIds) {
    _collectTimelineItems(cueId: rootCueId, index: index, items: items);
  }

  items.sort((a, b) {
    final frameCompare = a.$2.compareTo(b.$2);
    if (frameCompare != 0) return frameCompare;

    final endCompare = b.$3.compareTo(a.$3);
    if (endCompare != 0) return endCompare;

    return a.$1.compareTo(b.$1);
  });

  final itemMap = <String, (int, int, List<String>)>{};
  for (final item in items) {
    itemMap[item.$1] = (item.$2, item.$3, item.$4);
  }

  final childIds = <String>{};
  for (final item in items) {
    for (final childId in item.$4) {
      childIds.add(childId);
    }
  }

  final timelineItems = <TimelineElement>[];

  for (final item in items) {
    if (childIds.contains(item.$1)) continue;

    final cue = cuesById[item.$1];
    if (cue == null) continue;

    final selectableId = CueIdentifier(pageId: pageId, id: cue.id);
    final children = item.$4;

    if (children.isEmpty) {
      if (cue is Segment) {
        timelineItems.add(
          TimelineSegment(
            id: TimelineIdentifier(item.$1),
            startFrame: item.$2,
            endFrame: item.$3,
            builder: (context, data) => _SceneTimelineSegmentWidget(
              data: data,
              cue: cue,
              selectableId: selectableId,
            ),
            color: cue.blueprint.color,
            children: [],
          ),
        );
      } else if (cue is Keyframe) {
        timelineItems.add(
          TimelineKeyframe(
            id: TimelineIdentifier(item.$1),
            frame: item.$2,
            builder: (context, data) => _SceneTimelineKeyframeWidget(
              data: data,
              selectableId: selectableId,
              cue: cue,
            ),
            color: cue.blueprint.color,
          ),
        );
      }
    } else {
      final childElements = _buildChildElements(
        pageId: pageId,
        childIds: children,
        cuesById: cuesById,
        itemMap: itemMap,
      );

      if (cue is Segment) {
        timelineItems.add(
          TimelineSegment(
            id: TimelineIdentifier(item.$1),
            startFrame: item.$2,
            endFrame: item.$3,
            builder: (context, data) => _SceneTimelineSegmentWidget(
              data: data,
              cue: cue,
              selectableId: selectableId,
            ),
            color: cue.blueprint.color,
            children: childElements,
          ),
        );
      }
    }
  }

  return timelineItems;
}

List<TimelineElement> _buildChildElements({
  required String pageId,
  required List<String> childIds,
  required Map<String, Cue> cuesById,
  required Map<String, (int, int, List<String>)> itemMap,
}) {
  final elements = <TimelineElement>[];

  for (final childId in childIds) {
    final childCue = cuesById[childId];
    if (childCue == null) continue;

    final childSelectableId = CueIdentifier(pageId: pageId, id: childCue.id);
    final childData = itemMap[childId];
    if (childData == null) continue;

    final children = childData.$3;

    if (children.isEmpty) {
      if (childCue is Segment) {
        elements.add(
          TimelineSegment(
            id: TimelineIdentifier(childId),
            startFrame: childData.$1,
            endFrame: childData.$2,
            builder: (context, data) => _SceneTimelineSegmentWidget(
              data: data,
              cue: childCue,
              selectableId: childSelectableId,
            ),
            color: childCue.blueprint.color,
            children: [],
          ),
        );
      } else if (childCue is Keyframe) {
        elements.add(
          TimelineKeyframe(
            id: TimelineIdentifier(childId),
            frame: childData.$1,
            builder: (context, data) => _SceneTimelineKeyframeWidget(
              data: data,
              selectableId: childSelectableId,
              cue: childCue,
            ),
            color: childCue.blueprint.color,
          ),
        );
      }
    } else {
      final grandChildElements = _buildChildElements(
        pageId: pageId,
        childIds: children,
        cuesById: cuesById,
        itemMap: itemMap,
      );

      if (childCue is Segment) {
        elements.add(
          TimelineSegment(
            id: TimelineIdentifier(childId),
            startFrame: childData.$1,
            endFrame: childData.$2,
            builder: (context, data) => _SceneTimelineSegmentWidget(
              data: data,
              cue: childCue,
              selectableId: childSelectableId,
            ),
            color: childCue.blueprint.color,
            children: grandChildElements,
          ),
        );
      }
    }
  }

  return elements;
}

void _collectTimelineItems({
  required String cueId,
  required _CueIndex index,
  required List<(String, int, int, List<String>)> items,
}) {
  final cue = index.cuesById[cueId];
  if (cue == null) return;

  final absoluteStartFrame = _absoluteFrameForCue(cueId, index);
  final absoluteEndFrame = switch (cue) {
    Segment(startFrame: final start, endFrame: final end) =>
      absoluteStartFrame + (end - start),
    Keyframe(frame: final frame) => absoluteStartFrame,
    _ => absoluteStartFrame,
  };

  final children = index.childrenByCueId[cueId] ?? const <String>[];

  items.add((cueId, absoluteStartFrame, absoluteEndFrame, children));

  for (final childId in children) {
    _collectTimelineItems(cueId: childId, index: index, items: items);
  }
}

int _absoluteFrameForCue(String cueId, _CueIndex index) {
  var currentCueId = cueId;
  var offset = 0;

  while (true) {
    final cue = index.cuesById[currentCueId];
    if (cue == null) break;

    final localStart = switch (cue) {
      Segment(startFrame: final start) => start,
      Keyframe(frame: final f) => f,
      _ => 0,
    };

    offset += localStart;

    final parentId = index.parentByCueId[currentCueId];
    if (parentId == null) break;
    currentCueId = parentId;
  }

  return offset;
}

Color _fillColor(BuildContext context, Cue cue, TimelineElementBuildData data) {
  final isDeprecated = cue.blueprint.hasModifier<DeprecatedModifier>();
  if (!isDeprecated && !data.isPreview) {
    return cue.blueprint.color;
  }

  final previewAlpha = data.isPrimaryPreview
      ? 0.44
      : data.isRelatedPreview
      ? 0.24
      : 0.0;
  final deprecationAlpha = isDeprecated ? 0.7 : 0.0;
  return Color.alphaBlend(
    cue.blueprint.color.withValues(alpha: previewAlpha + deprecationAlpha),
    Surface.colorOf(context),
  );
}

class _SceneTimelineSegmentWidget extends HookWidget {
  const _SceneTimelineSegmentWidget({
    required this.data,
    required this.cue,
    required this.selectableId,
  });

  final TimelineElementBuildData data;
  final Cue cue;
  final CueIdentifier selectableId;

  bool get isDeprecated => cue.blueprint.hasModifier<DeprecatedModifier>();

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final fillColor = _fillColor(context, cue, data);

    return Selector(
      focusNode: focusNode,
      selectableId: selectableId,
      builder: (isSelected, isFocused, isHovered) {
        final foregroundColor = isFocused
            ? Colors.white
            : fillColor.onBrightness(Brightness.dark);

        final outlineColor = isSelected
            ? isFocused
                  ? Colors.white
                  : foregroundColor
            : Colors.transparent;

        return TimelineSegmentSurface(
          data: data,
          fillColor: fillColor,
          outlineColor: outlineColor,
          outlineWidth: 3.0,
          child: _SceneCueCard(
            cue: cue,
            isDeprecated: isDeprecated,
            foregroundColor: foregroundColor,
          ),
        );
      },
    );
  }
}

class _SceneTimelineKeyframeWidget extends HookWidget {
  const _SceneTimelineKeyframeWidget({
    required this.data,
    required this.selectableId,
    required this.cue,
  });

  final TimelineElementBuildData data;
  final CueIdentifier selectableId;
  final Cue cue;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final background = _fillColor(context, cue, data);

    return Selector(
      focusNode: focusNode,
      selectableId: selectableId,
      builder: (isSelected, isFocused, isHovered) {
        final outlineColor = isSelected
            ? context.isDarkMode
                  ? Colors.white
                  : background.onBrightness(Brightness.dark)
            : background;

        final fillColor = isFocused ? Colors.white : background;

        return TimelineKeyframeSurface(
          data: data,
          fillColor: fillColor,
          outlineColor: outlineColor,
          outlineWidth: 3.0,
          child: const SizedBox.shrink(),
        );
      },
    );
  }
}

class _SceneCueCard extends StatelessWidget {
  const _SceneCueCard({
    required this.isDeprecated,
    required this.cue,
    required this.foregroundColor,
  });

  final Cue cue;
  final bool isDeprecated;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return InnerElementNode(
      name: cue.blueprint.name,
      blueprint: cue.blueprint,
      color: foregroundColor,
      isDeprecated: isDeprecated,
    );
  }
}
