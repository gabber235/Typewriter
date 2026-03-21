import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_cue_graph.dart";
import "package:typewriter_panel/logic/scene/scene_frame_resolver.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
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
          resolveMoveTargets: (draggedId) {
            final index = SceneCueGraphIndex.fromPageElements(elements);
            final roots = _resolveMoveCueRoots(
              ref: ref,
              pageId: pageId,
              index: index,
              draggedCueId: draggedId.id,
            );
            return roots.map(TimelineIdentifier.new).toList();
          },
          onElementMoved: (changes) => _commitSceneMoveBatch(
            ref: ref,
            pageId: pageId,
            elements: elements,
            changes: changes,
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

List<String> _resolveMoveCueRoots({
  required WidgetRef ref,
  required String pageId,
  required SceneCueGraphIndex index,
  required String draggedCueId,
}) {
  final draggedIdentifier = CueIdentifier(pageId: pageId, id: draggedCueId);
  final selected = ref.read(selectionProvider);
  final draggedIsSelected = selected.contains(draggedIdentifier);

  final selectedCueIds = <String>[
    for (final item in selected)
      if (item case CueIdentifier(
        pageId: final selectedPageId,
        id: final cueId,
      ) when selectedPageId == pageId && index.cuesById.containsKey(cueId))
        cueId,
  ];

  final candidateCueIds = draggedIsSelected ? selectedCueIds : [draggedCueId];
  final uniqueCandidateCueIds = <String>[];
  final candidateCueIdSet = <String>{};
  for (final cueId in candidateCueIds) {
    if (!candidateCueIdSet.add(cueId)) continue;
    uniqueCandidateCueIds.add(cueId);
  }

  final roots = <String>[];
  for (final cueId in uniqueCandidateCueIds) {
    var parentCueId = index.parentByCueId[cueId];
    var hasCandidateAncestor = false;
    while (parentCueId != null) {
      if (candidateCueIdSet.contains(parentCueId)) {
        hasCandidateAncestor = true;
        break;
      }
      parentCueId = index.parentByCueId[parentCueId];
    }

    if (!hasCandidateAncestor) {
      roots.add(cueId);
    }
  }

  if (roots.contains(draggedCueId)) {
    return [
      draggedCueId,
      for (final cueId in roots)
        if (cueId != draggedCueId) cueId,
    ];
  }

  return roots;
}

Future<void> _commitSceneMoveBatch({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required List<TimelineCommitPayload> changes,
}) {
  if (changes.isEmpty) return Future.value();

  final index = SceneCueGraphIndex.fromPageElements(elements);
  final moveChanges = <(String, int, int)>[];

  for (final change in changes) {
    final cueId = change.id.id;
    final parentInfo = findSceneParentInfo(cueId, index);

    final resolved = resolveSceneCueFrames(
      cueId: cueId,
      absoluteStartFrame: change.absoluteStartFrame,
      absoluteEndFrame: change.absoluteEndFrame,
      index: index,
      parentInfo: parentInfo,
      mode: TimelineInteractionMode.move,
    );
    moveChanges.add((cueId, resolved.localStartFrame, resolved.localEndFrame));
  }

  return ref.read(pageElementsProvider(pageId).notifier).moveCues(moveChanges);
}

Future<void> _commitSceneResize({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required String cueId,
  required int absoluteStartFrame,
  required int absoluteEndFrame,
}) {
  final index = SceneCueGraphIndex.fromPageElements(elements);

  final baseCue = index.cuesById[cueId];
  if (baseCue is! Segment) return Future.value();

  final baseStartFrame = baseCue.startFrame;
  final baseAbsoluteStart = absoluteFrameFromLocalFrame(
    baseStartFrame,
    cueId,
    index,
  );

  final mode = absoluteStartFrame == baseAbsoluteStart
      ? TimelineInteractionMode.resizeEnd
      : TimelineInteractionMode.resizeStart;

  final parentInfo = findSceneParentInfo(cueId, index);

  final resolved = resolveSceneCueFrames(
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

class _SceneViewData {
  const _SceneViewData({required this.timelineData});

  factory _SceneViewData.create({
    required String pageId,
    required List<PageElement> elements,
  }) {
    final index = SceneCueGraphIndex.fromPageElements(elements);
    final cuesById = <String, Cue>{};

    for (final element in elements) {
      switch (element) {
        case PageElementEntry():
          continue;
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
  required SceneCueGraphIndex index,
}) {
  final items = collectSceneTimelineItems(rootCueIds: rootCueIds, index: index)
    ..sort((a, b) {
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
          outlineWidth: 2.8,
          child: InnerElementNode(
            name: cue.blueprint.name,
            blueprint: cue.blueprint,
            color: foregroundColor,
            isDeprecated: isDeprecated,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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
