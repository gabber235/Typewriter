import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_builder.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/riverpod.dart";
import "package:typewriter_panel/widgets/app/components/empty_entry_page.dart";
import "package:typewriter_panel/widgets/app/components/entry.dart";
import "package:typewriter_panel/widgets/app/components/inner_element_node.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline.dart";
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
            cueId: change.$1.id,
            startFrame: change.$2,
            endFrame: change.$3,
          ),
          onElementResized: (change) => _commitSceneResize(
            ref: ref,
            pageId: pageId,
            elements: elements,
            cueId: change.$1.id,
            startFrame: change.$2,
            endFrame: change.$3,
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

Future<void> _commitSceneMove({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required String cueId,
  required int startFrame,
  required int endFrame,
}) {
  final committedTimeline = buildSceneTimelineData(
    elements,
    override: SceneTimelineOverride(
      cueId: cueId,
      mode: SceneTimelineOverrideMode.move,
      startFrame: startFrame,
      endFrame: endFrame,
    ),
  );
  final committedItem = committedTimeline.itemByCueId(cueId);
  if (committedItem == null) return Future.value();

  return ref.read(pageElementsProvider(pageId).notifier).moveCues([
    (cueId, committedItem.localStartFrame, committedItem.localEndFrame),
  ]);
}

Future<void> _commitSceneResize({
  required WidgetRef ref,
  required String pageId,
  required List<PageElement> elements,
  required String cueId,
  required int startFrame,
  required int endFrame,
}) {
  final baseTimeline = buildSceneTimelineData(elements);
  final baseItem = baseTimeline.itemByCueId(cueId);
  if (baseItem is! SceneSegmentItem) return Future.value();

  final mode = startFrame == baseItem.absoluteStartFrame
      ? SceneTimelineOverrideMode.resizeEnd
      : SceneTimelineOverrideMode.resizeStart;
  final committedTimeline = buildSceneTimelineData(
    elements,
    override: SceneTimelineOverride(
      cueId: cueId,
      mode: mode,
      startFrame: startFrame,
      endFrame: endFrame,
    ),
  );
  final committedItem = committedTimeline.itemByCueId(cueId);
  if (committedItem is! SceneSegmentItem) return Future.value();

  return ref.read(pageElementsProvider(pageId).notifier).resizeCues([
    (cueId, committedItem.localStartFrame, committedItem.localEndFrame),
  ]);
}

class _SceneViewData {
  const _SceneViewData({required this.timelineData});

  factory _SceneViewData.create({
    required String pageId,
    required List<PageElement> elements,
  }) {
    final sceneTimeline = buildSceneTimelineData(elements);
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
      for (final track in sceneTimeline.tracks)
        TimelineTrack(
          id: TimelineIdentifier(track.id.id),
          header: (context) => EntryNode(
            entry:
                entriesById[track.entryId] ??
                PageEntry.nonexistent(id: track.entryId),
          ),
          elements: _buildTimelineElements(
            pageId: pageId,
            items: track.rootItems,
            cuesById: cuesById,
          ),
        ),
    ];

    return _SceneViewData(timelineData: TimelineData(tracks: tracks));
  }

  final TimelineData timelineData;
}

List<TimelineElement> _buildTimelineElements({
  required String pageId,
  required List<SceneTimelineItem> items,
  required Map<String, Cue> cuesById,
}) {
  final timelineItems = <TimelineElement>[];

  for (final item in items) {
    final cue = cuesById[item.cueId];
    assert(cue != null, "Missing cue ${item.cueId} for timeline item.");
    if (cue == null) continue;

    final selectableId = CueIdentifier(pageId: pageId, id: cue.id);
    switch (item) {
      case SceneSegmentItem():
        final children = _buildTimelineElements(
          pageId: pageId,
          items: item.children,
          cuesById: cuesById,
        );
        timelineItems.add(
          TimelineSegment(
            id: TimelineIdentifier(item.id.id),
            startFrame: item.absoluteStartFrame,
            endFrame: item.absoluteEndFrame,
            builder: (context, data) => _SceneTimelineSegmentWidget(
              data: data,
              cue: cue,
              selectableId: selectableId,
            ),
            color: cue.blueprint.color,
            children: children,
          ),
        );
      case SceneKeyframeItem():
        timelineItems.add(
          TimelineKeyframe(
            id: TimelineIdentifier(item.id.id),
            frame: item.absoluteFrame,
            builder: (context, data) => _SceneTimelineKeyframeWidget(
              data: data,
              selectableId: selectableId,
              cue: cue,
            ),
            color: cue.blueprint.color,
          ),
        );
    }
  }

  timelineItems.sort();
  return timelineItems;
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
