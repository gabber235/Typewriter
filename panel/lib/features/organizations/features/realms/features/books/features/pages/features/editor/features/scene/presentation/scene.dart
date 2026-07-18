import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/element_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/entries.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/application/scene.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/application/timeline_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/empty_entry_page.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/entry.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/inner_element_node.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/presentation/selector.dart";
import "package:typewriter_panel/shared/ui/components/shimmer.dart";
import "package:typewriter_panel/shared/ui/components/surface.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_panel/shared/utilities/context.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

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

        return HookBuilder(
          builder: (context) {
            final elementsById = useMemoized(
              () => {for (final element in elements) element.id: element},
              [elements],
            );

            final sceneView = useMemoized(
              () => _SceneViewData.create(
                pageId: pageId,
                elementsById: elementsById,
              ),
              [pageId, elementsById],
            );

            assert(
              sceneView.timelineData.tracks.length ==
                  elements.whereType<PageElementEntry>().length,
              "Scene track count must match page entry count.",
            );

            return Timeline(
              data: sceneView.timelineData,
              resolveTargets: (draggedId) {
                final roots = _resolveCues(
                  ref: ref,
                  pageId: pageId,
                  primaryCueId: draggedId?.id,
                  elementsById: elementsById,
                );
                return roots.map(TimelineIdentifier.new).toList();
              },
              onElementsCommited: (changes) =>
                  _commitSceneBatch(ref: ref, pageId: pageId, changes: changes),
            );
          },
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

Set<String> _resolveCues({
  required WidgetRef ref,
  required String pageId,
  required String? primaryCueId,
  required Map<String, PageElement> elementsById,
}) {
  final primaryIdentifier = primaryCueId != null
      ? CueIdentifier(pageId: pageId, id: primaryCueId)
      : null;
  final selected = ref.read(selectionProvider);
  if (primaryIdentifier != null) {
    if (!selected.contains(primaryIdentifier)) {
      return {primaryCueId!};
    }
  }

  return <String>{
    for (final item in selected)
      if (item case CueIdentifier(
        pageId: final selectedPageId,
        id: final cueId,
      ) when selectedPageId == pageId && elementsById.containsKey(cueId))
        cueId,
  };
}

Future<void> _commitSceneBatch({
  required WidgetRef ref,
  required String pageId,
  required List<TimelineCommitPayload> changes,
}) {
  if (changes.isEmpty) return Future.value();

  final changedCues = <(String, int, int)>[
    for (final change in changes)
      (change.id.id, change.startFrame, change.endFrame),
  ];

  return ref
      .read(pageElementsProvider(pageId).notifier)
      .updateCues(changedCues);
}

class _SceneViewData {
  const _SceneViewData({required this.timelineData});

  factory _SceneViewData.create({
    required String pageId,
    required Map<String, PageElement> elementsById,
  }) {
    final entries = elementsById.values.whereType<PageElementEntry>().toList();
    final tracks = [
      for (final entry in entries)
        TimelineTrack(
          id: TimelineIdentifier(entry.id),
          header: (context) => EntryNode(entry: entry.entry),
          elements: entry.entry.links.$2
              .map(
                (link) => _buildTimelineElement(
                  pageId: pageId,
                  element: elementsById[link.otherId]!,
                  parentId: null,
                  elementsById: elementsById,
                ),
              )
              .nonNulls
              .toList(),
        ),
    ];

    return _SceneViewData(timelineData: TimelineData(tracks: tracks));
  }

  final TimelineData timelineData;
}

TimelineElement? _buildTimelineElement({
  required String pageId,
  required PageElement element,
  required TimelineIdentifier? parentId,
  required Map<String, PageElement> elementsById,
}) {
  if (element is! PageElementCue) return null;

  final cue = element.cue;
  final selectableId = CueIdentifier(pageId: pageId, id: cue.id);
  if (cue is Keyframe) {
    return TimelineKeyframe(
      id: TimelineIdentifier(cue.id),
      frame: cue.frame,
      parentId: parentId,
      builder: (context, data) => _SceneTimelineKeyframeWidget(
        data: data,
        selectableId: selectableId,
        cue: cue,
      ),
      color: cue.blueprint.color,
    );
  }

  if (cue is! Segment) {
    throw StateError("Unexpected cue type: ${cue.runtimeType}");
  }

  final childrenId = cue.outwardLinks.map((e) => e.otherId).toSet();

  return TimelineSegment(
    id: TimelineIdentifier(cue.id),
    startFrame: cue.startFrame,
    endFrame: cue.endFrame,
    parentId: parentId,
    builder: (context, data) => _SceneTimelineSegmentWidget(
      data: data,
      cue: cue,
      selectableId: selectableId,
    ),
    color: cue.blueprint.color,
    children: childrenId
        .map(
          (childId) => _buildTimelineElement(
            pageId: pageId,
            element: elementsById[childId]!,
            parentId: TimelineIdentifier(cue.id),
            elementsById: elementsById,
          ),
        )
        .nonNulls
        .toList(),
  );
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
  final deprecationAlpha = isDeprecated ? 0.7 : 1.0;
  return Color.alphaBlend(
    cue.blueprint.color.withValues(alpha: deprecationAlpha - previewAlpha),
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
