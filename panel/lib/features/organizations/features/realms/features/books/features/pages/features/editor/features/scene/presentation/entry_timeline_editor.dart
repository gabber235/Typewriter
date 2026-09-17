import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Renders the timeline editor for one projected page.
///
/// Each timeline entry becomes a track. Its outward cue links become nested
/// timeline elements, while keyframes remain leaf elements. The timeline owns
/// interaction previews and this widget translates the final frame values
/// into one page element mutation batch. The projected input may include local
/// drafts, so the surface can reflect edits before the authoring session
/// confirms them.
class EntryTimelineEditor extends HookConsumerWidget {
  const EntryTimelineEditor({required this.pageId, super.key});

  /// Identifier of the page whose projected elements supply the timeline.
  final String pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationId = ref.watch(organizationIdProvider);
    final realmId = ref.watch(realmIdProvider);
    if (organizationId == null || realmId == null) {
      return const SizedBox.shrink();
    }
    final pageElements = ref.watch(
      projectedPageElementsProvider(organizationId, realmId, pageId),
    );

    return pageElements(
      name: "elements",
      builder: (elements) {
        return HookBuilder(
          builder: (context) {
            final elementsById = useMemoized(
              () => {for (final element in elements) element.id: element},
              [elements],
            );

            final timelineView = useMemoized(
              () => _TimelineViewData.create(
                pageId: pageId,
                elementsById: elementsById,
              ),
              [pageId, elementsById],
            );

            assert(
              timelineView.timelineData.tracks.length ==
                  elements.whereType<PageElementEntry>().length,
              "Timeline track count must match page entry count.",
            );

            return FloatingButton(
              icon: const Icon(Icons.add),
              onPressed: () => showAddElementSearch(context, pageId: pageId),
              child: Stack(
                children: [
                  Timeline(
                    data: timelineView.timelineData,
                    resolveTargets: (draggedId) {
                      final roots = _resolveCues(
                        ref: ref,
                        pageId: pageId,
                        primaryCueId: draggedId?.id,
                        elementsById: elementsById,
                      );
                      return roots.map(TimelineIdentifier.new).toList();
                    },
                    onElementsCommited: (changes) => _commitTimelineBatch(
                      ref: ref,
                      pageId: pageId,
                      changes: changes,
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: PageDiagnosticsBanner(pageId: pageId),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: (_) => ShimmerBox.rectangle(
        width: double.infinity,
        height: double.infinity,
        borderRadius: context.shapes.largeBorderRadius,
      ),
    );
  }
}

/// Resolves the timeline drag target set from shared selection state.
///
/// A selected cue set is used only when the dragged cue is in that set. A drag
/// that starts outside the selection affects only its own cue. Descendants are
/// not independently promoted to roots; the timeline receives the selected
/// identifiers that are present on this page and handles their hierarchy.
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
      if (item case CueIdentifier(pageId: final selectedPageId, id: final cueId)
          when selectedPageId == pageId && elementsById.containsKey(cueId))
        cueId,
  };
}

/// Hands committed timeline placement values to the page element owner.
///
/// The timeline emits only cues whose previews changed. The page coordinator
/// validates readiness, overlays the placement values on the current owner
/// state, and performs the authoring batch. This scene does not decide how
/// uncertain or conflicting persistence results are reconciled.
Future<void> _commitTimelineBatch({
  required WidgetRef ref,
  required String pageId,
  required List<TimelineCommitPayload> changes,
}) {
  if (changes.isEmpty) return Future.value();

  final changedCues = <(String, int, int)>[
    for (final change in changes)
      (change.id.id, change.startFrame, change.endFrame),
  ];

  return ref.withReadyPageElements(
    pageId,
    (elements) => elements.updateCues(changedCues),
  );
}

/// Immutable timeline input assembled from the current page projection.
///
/// Track order follows the projected page entries. Cue hierarchy is rebuilt
/// from local outward links, so the timeline does not infer relationships from
/// frame overlap or from unrelated page elements.
class _TimelineViewData {
  const _TimelineViewData({required this.timelineData});

  factory _TimelineViewData.create({
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

    return _TimelineViewData(timelineData: TimelineData(tracks: tracks));
  }

  final TimelineData timelineData;
}

/// Converts a projected cue and its descendants to timeline data.
///
/// Noncue references are omitted because they have no timeline placement.
/// The projection is expected to contain every linked local cue. A missing
/// reference is not silently turned into an invented timeline element.
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
      color: cue.elementDefinition.color,
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
    color: cue.elementDefinition.color,
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

/// Blends catalog deprecation and transient preview state into cue color.
///
/// Preview alpha distinguishes the primary dragged cue from related cues. A
/// deprecated definition remains visually identifiable while its placement is
/// still rendered from the projection.
Color _fillColor(BuildContext context, Cue cue, TimelineElementBuildData data) {
  final isDeprecated = cue.elementDefinition.isDeprecated;
  if (!isDeprecated && !data.isPreview) {
    return cue.elementDefinition.color;
  }

  final previewAlpha = data.isPrimaryPreview
      ? 0.44
      : data.isRelatedPreview
      ? 0.24
      : 0.0;
  final deprecationAlpha = isDeprecated ? 0.7 : 1.0;
  return Color.alphaBlend(
    cue.elementDefinition.color.withValues(
      alpha: deprecationAlpha - previewAlpha,
    ),
    Surface.colorOf(context),
  );
}

/// Paints a selectable segment while preserving timeline focus visuals.
class _SceneTimelineSegmentWidget extends HookWidget {
  const _SceneTimelineSegmentWidget({
    required this.data,
    required this.cue,
    required this.selectableId,
  });

  final TimelineElementBuildData data;
  final Cue cue;
  final CueIdentifier selectableId;

  bool get isDeprecated => cue.elementDefinition.isDeprecated;

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
            name: cue.elementDefinition.name,
            elementDefinition: cue.elementDefinition,
            color: foregroundColor,
            isDeprecated: isDeprecated,
            padding: EdgeInsets.symmetric(
              horizontal: context.spacing.space2,
              vertical: 0,
            ),
          ),
        );
      },
    );
  }
}

/// Paints a selectable keyframe and its focus and selection outlines.
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
