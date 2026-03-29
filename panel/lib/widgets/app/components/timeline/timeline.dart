import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/hooks/delayed_execution.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/timeline/timeline_controller.dart";
import "package:typewriter_panel/logic/timeline/timeline_data.dart";
import "package:typewriter_panel/logic/timeline/timeline_layout.dart";
import "package:typewriter_panel/logic/timeline/timeline_placement.dart";
import "package:typewriter_panel/logic/timeline/timeline_viewport.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_headers.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_intents.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_plane_surface.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_ruler.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";

export "package:typewriter_panel/widgets/app/components/timeline/timeline_keyframe_surface.dart";
export "package:typewriter_panel/widgets/app/components/timeline/timeline_segment_surface.dart";

class TimelineCommitPayload {
  const TimelineCommitPayload({
    required this.id,
    required this.startFrame,
    required this.endFrame,
  });

  final TimelineIdentifier id;
  final int startFrame;
  final int endFrame;
}

typedef TimelineCommit =
    Future<void> Function(List<TimelineCommitPayload> changes);

class Timeline extends HookConsumerWidget {
  const Timeline({
    required this.data,
    this.onElementsCommited,
    this.resolveTargets,
    super.key,
  });

  final TimelineData data;
  final TimelineCommit? onElementsCommited;
  final List<TimelineIdentifier> Function(TimelineIdentifier? focusedId)?
  resolveTargets;

  int framesJump() {
    if (HardwareKeyboard.instance.isMetaPressed) return 100;
    if (HardwareKeyboard.instance.isControlPressed) return 50;
    if (HardwareKeyboard.instance.isShiftPressed) return 10;
    return 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickerProvider = useSingleTickerProvider();
    final controller = useTimelineController(
      tickerProvider: tickerProvider,
      headerWidth: context.responsive(mobile: 100, desktop: 200),
    );
    final planeGlobalKey = useGlobalKey();

    return LayoutBuilder(
      builder: (context, constraints) {
        return HookBuilder(
          builder: (context) {
            final style = useMemoized(
              () => TimelineStyle.fallback(Theme.of(context)),
              [Theme.of(context)],
            );
            final headerWidth = useMemoized(
              () => controller.headerWidth
                  .clamp(
                    style.minHeaderWidth,
                    math.min(style.maxHeaderWidth, constraints.maxWidth * 0.55),
                  )
                  .toDouble(),
              [controller.headerWidth, style, constraints.maxWidth],
            );
            const handleWidth = 16.0;
            final bodyHeight = useMemoized(
              () => math.max(0.0, constraints.maxHeight - style.rulerHeight),
              [constraints.maxHeight, style.rulerHeight],
            );
            final planeWidth = useMemoized(
              () => math.max(
                0.0,
                constraints.maxWidth - headerWidth - handleWidth,
              ),
              [constraints.maxWidth, headerWidth],
            );
            final viewport = useMemoized(
              () => TimelineViewport(
                headerWidth: headerWidth,
                planeWidth: planeWidth,
                planeHeight: bodyHeight,
                horizontalOffset: controller.horizontalOffset,
                verticalOffset: controller.verticalOffset,
                pixelsPerFrame: controller.pixelsPerFrame,
              ),
              [
                headerWidth,
                planeWidth,
                bodyHeight,
                controller.horizontalOffset,
                controller.verticalOffset,
                controller.pixelsPerFrame,
              ],
            );

            final layout = useMemoized(
              () => TimelineLayoutEngine().build(
                data: data,
                previews: controller.previews,
              ),
              [data, controller.previews],
            );
            final placement = useMemoized(
              () => TimelinePlacementEngine().build(
                layout: layout,
                viewport: viewport,
                style: style,
              ),
              [layout, viewport, style],
            );

            useDelayedExecution(() {
              controller.resetZoom(viewport, layout, animate: false);
              return null;
            }, []);

            List<MoveTimelinePreview> resolveMovePreviews(
              TimelineIdentifier primaryId,
            ) {
              final targetIds = resolveTargets?.call(primaryId);
              final orderedIds = targetIds == null || targetIds.isEmpty
                  ? {primaryId}
                  : targetIds.toSet();

              final previews = <MoveTimelinePreview>[];
              for (final targetId in orderedIds) {
                final preview = data.movePreview(targetId);
                if (preview == null) continue;
                previews.add(preview);
              }
              return previews;
            }

            TimelinePreview? buildResizePreview(
              TimelineSegment segment,
              TimelineInteractionMode mode,
            ) {
              switch (mode) {
                case TimelineInteractionMode.resizeStart:
                  return data.resizeStartPreview(segment.id);
                case TimelineInteractionMode.resizeEnd:
                  return data.resizeEndPreview(segment.id);
                case TimelineInteractionMode.move:
                  throw ArgumentError.value(
                    mode,
                    "mode",
                    "Invalid mode for segment resize",
                  );
              }
            }

            TimelinePreview? findAdjacentPreview(
              TimelineIdentifier id,
              TimelineInteractionMode mode,
            ) {
              final source = data.elementsById[id];
              if (source is! TimelineSegment) return null;

              final targetFrame = switch (mode) {
                TimelineInteractionMode.resizeStart => source.startFrame - 1,
                TimelineInteractionMode.resizeEnd => source.endFrame + 1,
                TimelineInteractionMode.move => null,
              };
              if (targetFrame == null) return null;

              final parentId = source.parentId;
              final parentElement = parentId == null
                  ? null
                  : data.elementsById[parentId];
              List<TimelineTrackBlockPlacement> siblings;

              final placement = layout.placementsById[source.id]!;

              if (parentElement is TimelineSegment) {
                siblings = parentElement.children
                    .where((element) => element.id != source.id)
                    .map((element) => layout.placementsById[element.id])
                    .nonNulls
                    .toList();
              } else {
                final sourceTrackId = data.trackByElementId[id];
                if (sourceTrackId == null) return null;
                siblings = data.tracks
                    .firstWhere((track) => track.id == sourceTrackId)
                    .elements
                    .where((element) => element.id != source.id)
                    .map((element) => layout.placementsById[element.id])
                    .nonNulls
                    .toList();
              }

              TimelineSegment? adjacent;
              for (final sibling in siblings) {
                if (sibling.lane != placement.lane) continue;
                final siblingElement = sibling.element;
                if (siblingElement is! TimelineSegment) continue;

                final isMatch = switch (mode) {
                  TimelineInteractionMode.resizeStart =>
                    siblingElement.endFrame == targetFrame,
                  TimelineInteractionMode.resizeEnd =>
                    siblingElement.startFrame == targetFrame,
                  TimelineInteractionMode.move => false,
                };
                if (!isMatch) continue;

                adjacent = siblingElement;
                break;
              }

              if (adjacent == null) return null;

              final adjacentMode = switch (mode) {
                TimelineInteractionMode.resizeStart =>
                  TimelineInteractionMode.resizeEnd,
                TimelineInteractionMode.resizeEnd =>
                  TimelineInteractionMode.resizeStart,
                TimelineInteractionMode.move => throw StateError(
                  "Invalid mode, should not be possible",
                ),
              };

              return buildResizePreview(adjacent, adjacentMode);
            }

            List<TimelinePreview> resolveResizePreviews(
              TimelineIdentifier id,
              TimelineInteractionMode mode,
            ) {
              final ids = resolveTargets?.call(id) ?? [id];
              return ids
                  .map((id) => data.elementsById[id])
                  .whereType<TimelineSegment>()
                  .map((element) => buildResizePreview(element, mode))
                  .nonNulls
                  .expand((preview) {
                    final adjacent = findAdjacentPreview(preview.id, mode);
                    return adjacent == null ? [preview] : [preview, adjacent];
                  })
                  .toList();
            }

            Future<void> commitPreviews(List<TimelinePreview> previews) async {
              if (previews.isEmpty) return;

              if (onElementsCommited == null) return;

              await onElementsCommited!([
                for (final preview in previews)
                  TimelineCommitPayload(
                    id: preview.id,
                    startFrame: preview.startFrame,
                    endFrame: preview.endFrame,
                  ),
              ]);
            }

            final plane = TimelinePlaneSurface(
              controller: controller,
              style: style,
              viewport: viewport,
              placement: placement,
              onCommitPreviews: commitPreviews,
              resolveMovePreviews: resolveMovePreviews,
              resolveResizePreviews: resolveResizePreviews,
              key: planeGlobalKey,
            );

            final currentInteractionMode = ref.watch(
              currentInteractionModeProvider,
            );

            final ignoreCentering = useState<List<SelectableIdentifier>>([]);
            final totalDelta = useState(0.0);

            useEffect(() {
              void onFocusChange() {
                final focused = SelectableScope.primaryFocusedId();
                if (focused == null) return;
                if (ignoreCentering.value.remove(focused)) return;
                final identifier = TimelineIdentifier(focused.id);
                final element = placement.placementById[identifier];
                if (element == null) return;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.centerOn(viewport, element);
                });
              }

              FocusManager.instance.addListener(onFocusChange);
              return () {
                FocusManager.instance.removeListener(onFocusChange);
              };
            }, [placement]);

            return ManagedActionSet(
              shortcuts: buildTimelineShortcuts(
                canCommit: onElementsCommited != null,
                currentInteractionMode: currentInteractionMode,
                controller: controller,
                style: style,
                viewport: viewport,
                layout: layout,
                placement: placement,
                planeGlobalKey: planeGlobalKey,
                resolveMovePreviews: resolveMovePreviews,
                resolveResizePreviews: resolveResizePreviews,
                totalDelta: totalDelta,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: headerWidth,
                    child: Column(
                      children: [
                        TimelineTopLeftHeader(viewport: viewport, style: style),
                        Expanded(
                          child: TimelineTrackHeaders(
                            placement: placement,
                            viewport: viewport,
                            style: style,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: handleWidth,
                    color: style.palette.headerBackground,
                    child: DragHandle(
                      axis: Axis.horizontal,
                      getSize: () => controller.headerWidth,
                      onSizeChange: controller.setHeaderWidth,
                      minSize: style.minHeaderWidth,
                      maxSize: math.min(
                        style.maxHeaderWidth,
                        constraints.maxWidth * 0.55,
                      ),
                      hitThickness: handleWidth,
                      showOnHover: true,
                      handleExtentFactor: 1,
                      handleThickness: 3,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TimelineRuler(viewport: viewport, style: style),
                        Expanded(
                          child: Actions(
                            actions: {
                              SelectedSelectorIntent:
                                  CallbackAction<SelectedSelectorIntent>(
                                    onInvoke: (intent) {
                                      // When we click on a node, it will auto focus on it, however we don't want to center the graph
                                      // on it because it will cause the graph to jump around and all around feel terrible.
                                      if (!intent.throughTap) return null;
                                      ignoreCentering.value = [
                                        ...ignoreCentering.value,
                                        intent.selectableId,
                                      ];
                                      return null;
                                    },
                                  ),

                              TimelineMoveIntent:
                                  CallbackAction<TimelineMoveIntent>(
                                    onInvoke: (intent) {
                                      assert(
                                        onElementsCommited != null,
                                        "onElementsCommited must be provided",
                                      );
                                      final direction = intent.direction;
                                      final moveDelta = switch (direction) {
                                        TraversalDirection.left => -1,
                                        TraversalDirection.right => 1,
                                        _ => 0,
                                      };

                                      final movePixels =
                                          moveDelta *
                                          controller.pixelsPerFrame *
                                          framesJump();
                                      totalDelta.value += movePixels;
                                      controller.updateInteraction(
                                        totalDelta.value,
                                      );

                                      final primaryFocusedId =
                                          SelectableScope.primaryFocusedId();
                                      if (primaryFocusedId == null) return;
                                      final identifier = TimelineIdentifier(
                                        primaryFocusedId.id,
                                      );
                                      final element =
                                          placement.placementById[identifier];
                                      if (element != null) {
                                        controller.centerOn(viewport, element);
                                      }
                                      return null;
                                    },
                                  ),
                              TimelineResizeIntent:
                                  CallbackAction<TimelineResizeIntent>(
                                    onInvoke: (intent) {
                                      assert(
                                        onElementsCommited != null,
                                        "onElementsCommited must be provided",
                                      );

                                      final direction = intent.direction;
                                      final moveDelta = switch (direction) {
                                        TraversalDirection.left => -1,
                                        TraversalDirection.right => 1,
                                        _ => 0,
                                      };

                                      final movePixels =
                                          moveDelta *
                                          controller.pixelsPerFrame *
                                          framesJump();
                                      totalDelta.value += movePixels;
                                      controller.updateInteraction(
                                        totalDelta.value,
                                      );

                                      final primaryFocusedId =
                                          SelectableScope.primaryFocusedId();
                                      if (primaryFocusedId == null) return;
                                      final identifier = TimelineIdentifier(
                                        primaryFocusedId.id,
                                      );
                                      final element =
                                          placement.placementById[identifier];
                                      if (element != null) {
                                        controller.centerOn(viewport, element);
                                      }
                                      return null;
                                    },
                                  ),

                              TimelineCenterFocusedIntent:
                                  CallbackAction<TimelineCenterFocusedIntent>(
                                    onInvoke: (intent) {
                                      final primaryFocusedId =
                                          SelectableScope.primaryFocusedId();
                                      if (primaryFocusedId == null) return;
                                      final identifier = TimelineIdentifier(
                                        primaryFocusedId.id,
                                      );
                                      final element =
                                          placement.placementById[identifier];
                                      if (element != null) {
                                        controller.centerOn(viewport, element);
                                      }
                                      return null;
                                    },
                                  ),

                              TimelineCommitIntent:
                                  CallbackAction<TimelineCommitIntent>(
                                    onInvoke: (intent) {
                                      final previews = controller
                                          .finishInteractionSession();
                                      commitPreviews(previews);
                                      return null;
                                    },
                                  ),
                            },
                            child: plane,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
