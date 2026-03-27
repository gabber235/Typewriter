import "dart:async";
import "dart:math" as math;

import "package:collection/collection.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/ion.dart";
import "package:iconify_flutter_plus/icons/lucide.dart";
import "package:typewriter_panel/hooks/delayed_execution.dart";
import "package:typewriter_panel/hooks/global_key.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/timeline_modes.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/selector.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_intents.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_placement.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_plane.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

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
                final element = data.elementsById[targetId];
                if (element == null) continue;
                final parentId = element.parentId;
                final parentElement = parentId == null
                    ? null
                    : data.elementsById[parentId];

                final endConstraint = parentElement != null
                    ? FrameConstraint.exact(parentElement.frameDuration)
                    : const FrameConstraint.infinite();

                previews.add(
                  MoveTimelinePreview(
                    id: targetId,
                    startFrame: element.startFrame,
                    endFrame: element.endFrame,
                    frameRange: FrameRange(
                      FrameConstraint.infinite(),
                      endConstraint,
                    ),
                  ),
                );
              }
              return previews;
            }

            TimelinePreview? buildResizePreview(
              TimelineSegment segment,
              TimelineInteractionMode mode,
            ) {
              switch (mode) {
                case TimelineInteractionMode.resizeStart:
                  final lastChildEndFrame = segment.children
                      .map((e) => e.endFrame)
                      .maxOrNull;

                  final endConstraint = lastChildEndFrame != null
                      ? FrameConstraint.exact(
                          segment.startFrame +
                              segment.frameDuration -
                              lastChildEndFrame,
                        )
                      : FrameConstraint.exact(segment.endFrame);
                  return ResizeStartTimelinePreview(
                    id: segment.id,
                    startFrame: segment.startFrame,
                    endFrame: segment.endFrame,
                    startFrameRange: FrameRange(
                      const FrameConstraint.infinite(),
                      endConstraint,
                    ),
                  );
                case TimelineInteractionMode.resizeEnd:
                  final parentId = segment.parentId;
                  final parentElement = parentId == null
                      ? null
                      : data.elementsById[parentId];

                  final lastChildEndFrame = segment.children
                      .map((e) => e.endFrame)
                      .maxOrNull;

                  final startConstraint = lastChildEndFrame != null
                      ? FrameConstraint.exact(
                          segment.startFrame + lastChildEndFrame,
                        )
                      : FrameConstraint.exact(segment.startFrame);

                  final endConstraint = parentElement != null
                      ? FrameConstraint.exact(parentElement.frameDuration)
                      : const FrameConstraint.infinite();

                  return ResizeEndTimelinePreview(
                    id: segment.id,
                    startFrame: segment.startFrame,
                    endFrame: segment.endFrame,
                    endFrameRange: FrameRange(startConstraint, endConstraint),
                  );
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

            final plane = _TimelinePlaneSurface(
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
              shortcuts: [
                if (onElementsCommited != null &&
                    currentInteractionMode is! TimelineMoveMode)
                  ActionShortcut(
                    id: "timeline_move_mode_activate",
                    label: "Move Mode",
                    description: "Go to Move Mode",
                    activators: [
                      SingleActivator(shift: true, LogicalKeyboardKey.keyM),
                    ],
                    icon: Icones(Ion.md_move),
                    onInvoke: (ref) {
                      final primaryFocusedId =
                          SelectableScope.primaryFocusedId();
                      if (primaryFocusedId == null) return;
                      final identifier = TimelineIdentifier(
                        primaryFocusedId.id,
                      );
                      ref
                          .read(currentInteractionModeProvider.notifier)
                          .setMode(TimelineMoveMode());
                      controller.startInteractionSession(
                        previews: resolveMovePreviews(identifier),
                      );
                      totalDelta.value = 0;

                      final element = placement.placementById[identifier];
                      if (element != null) {
                        controller.centerOn(viewport, element);
                      }
                      return null;
                    },
                    priority: 10,
                  ),
                if (onElementsCommited != null &&
                    (currentInteractionMode is! TimelineResizeMode ||
                        currentInteractionMode.mode ==
                            TimelineInteractionMode.resizeStart))
                  ActionShortcut(
                    id: "timeline_resize_start_mode_activate",
                    label: "Resize Start Mode",
                    description: "Resize the selected segments start",
                    activators: [
                      SingleActivator(shift: true, LogicalKeyboardKey.keyS),
                    ],
                    icon: Icones(Lucide.move_diagonal_2),
                    onInvoke: (ref) {
                      final primaryFocusedId =
                          SelectableScope.primaryFocusedId();
                      if (primaryFocusedId == null) return;
                      final identifier = TimelineIdentifier(
                        primaryFocusedId.id,
                      );
                      ref
                          .read(currentInteractionModeProvider.notifier)
                          .setMode(
                            TimelineResizeMode(
                              mode: TimelineInteractionMode.resizeStart,
                            ),
                          );
                      controller.startInteractionSession(
                        previews: resolveResizePreviews(
                          identifier,
                          TimelineInteractionMode.resizeStart,
                        ),
                      );
                      totalDelta.value = 0;
                      final element = placement.placementById[identifier];
                      if (element != null) {
                        controller.centerOn(viewport, element);
                      }
                      return null;
                    },
                    priority: 10,
                  ),

                if (onElementsCommited != null &&
                    (currentInteractionMode is! TimelineResizeMode ||
                        currentInteractionMode.mode ==
                            TimelineInteractionMode.resizeEnd))
                  ActionShortcut(
                    id: "timeline_resize_end_mode_activate",
                    label: "Resize End Mode",
                    description: "Resize the selected segments end",
                    activators: [
                      SingleActivator(shift: true, LogicalKeyboardKey.keyE),
                    ],
                    icon: Icones(Lucide.move_diagonal_2),
                    onInvoke: (ref) {
                      final primaryFocusedId =
                          SelectableScope.primaryFocusedId();
                      if (primaryFocusedId == null) return;
                      final identifier = TimelineIdentifier(
                        primaryFocusedId.id,
                      );
                      ref
                          .read(currentInteractionModeProvider.notifier)
                          .setMode(
                            TimelineResizeMode(
                              mode: TimelineInteractionMode.resizeEnd,
                            ),
                          );
                      controller.startInteractionSession(
                        previews: resolveResizePreviews(
                          identifier,
                          TimelineInteractionMode.resizeEnd,
                        ),
                      );
                      totalDelta.value = 0;
                      final element = placement.placementById[identifier];
                      if (element != null) {
                        controller.centerOn(viewport, element);
                      }
                      return null;
                    },
                    priority: 10,
                  ),

                ActionShortcut(
                  id: "timeline_zoom_in",
                  label: "Zoom In",
                  description: "Zoom the timeline in",
                  activators: [
                    for (final key in [
                      LogicalKeyboardKey.equal,
                      LogicalKeyboardKey.add,
                      LogicalKeyboardKey.numpadEqual,
                      LogicalKeyboardKey.numpadAdd,
                    ]) ...[
                      SingleActivator(key),
                      SingleActivator(key, shift: true),
                      SingleActivator(key, meta: true),
                      SingleActivator(key, meta: true, shift: true),
                      SingleActivator(key, control: true),
                      SingleActivator(key, control: true, shift: true),
                    ],
                    for (final ch in ["=", "+"]) ...[
                      CharacterActivator(ch),
                      CharacterActivator(ch, meta: true),
                      CharacterActivator(ch, control: true),
                    ],
                  ],
                  priority: -2,
                  onInvoke: (_) {
                    final planeBox =
                        planeGlobalKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (planeBox == null) return;
                    final focal = planeBox.size.center(Offset.zero);
                    final scaleDelta = math.exp(25 * 0.0025);
                    controller.zoomAt(
                      localDx: focal.dx,
                      scaleDelta: scaleDelta,
                      minPixelsPerFrame: style.minPixelsPerFrame,
                      maxPixelsPerFrame: style.maxPixelsPerFrame,
                    );
                    return null;
                  },
                ),
                ActionShortcut(
                  id: "timeline_zoom_out",
                  label: "Zoom Out",
                  description: "Zoom the timeline out",
                  activators: [
                    for (final key in [
                      LogicalKeyboardKey.minus,
                      LogicalKeyboardKey.underscore,
                      LogicalKeyboardKey.numpadSubtract,
                    ]) ...[
                      SingleActivator(key),
                      SingleActivator(key, shift: true),
                      SingleActivator(key, meta: true),
                      SingleActivator(key, meta: true, shift: true),
                      SingleActivator(key, control: true),
                      SingleActivator(key, control: true, shift: true),
                    ],
                    for (final ch in ["-", "_"]) ...[
                      CharacterActivator(ch),
                      CharacterActivator(ch, meta: true),
                      CharacterActivator(ch, control: true),
                    ],
                  ],
                  priority: -2,
                  onInvoke: (_) {
                    final planeBox =
                        planeGlobalKey.currentContext?.findRenderObject()
                            as RenderBox?;
                    if (planeBox == null) return;
                    final focal = planeBox.size.center(Offset.zero);
                    final scaleDelta = math.exp(-25 * 0.0025);
                    controller.zoomAt(
                      localDx: focal.dx,
                      scaleDelta: scaleDelta,
                      minPixelsPerFrame: style.minPixelsPerFrame,
                      maxPixelsPerFrame: style.maxPixelsPerFrame,
                    );
                    return null;
                  },
                ),
                ActionShortcut(
                  id: "timeline_zoom_reset",
                  label: "Reset Zoom",
                  description: "Reset zoom to 100% and center",
                  activators: [
                    for (final key in [
                      LogicalKeyboardKey.digit0,
                      LogicalKeyboardKey.numpad0,
                    ]) ...[
                      SingleActivator(key),
                      SingleActivator(key, meta: true),
                      SingleActivator(key, control: true),
                    ],
                  ],
                  priority: -2,
                  onInvoke: (_) {
                    controller.resetZoom(viewport, layout);
                  },
                ),
              ],
              child: Row(
                children: [
                  SizedBox(
                    width: headerWidth,
                    child: Column(
                      children: [
                        _TimelineTopLeftHeader(
                          viewport: viewport,
                          style: style,
                        ),
                        Expanded(
                          child: _TimelineTrackHeaders(
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
                        _TimelineRuler(viewport: viewport, style: style),
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

class _TimelineTopLeftHeader extends StatelessWidget {
  const _TimelineTopLeftHeader({required this.viewport, required this.style});

  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: style.rulerHeight,
      padding: EdgeInsets.symmetric(horizontal: style.headerPadding),
      decoration: BoxDecoration(
        color: style.palette.headerBackground,
        border: Border(bottom: BorderSide(color: style.palette.headerDivider)),
      ),
      child: Center(child: Text("Timeline", style: textTheme.titleSmall)),
    );
  }
}

class _TimelineTrackHeaders extends StatelessWidget {
  const _TimelineTrackHeaders({
    required this.placement,
    required this.viewport,
    required this.style,
  });

  final TimelinePlacementResult placement;
  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(color: style.palette.headerBackground),
        child: Stack(
          children: [
            for (final trackLayout in placement.tracks.where(
              (element) => element.isVisible(viewport),
            ))
              Positioned(
                top: trackLayout.top - viewport.verticalOffset,
                left: 0,
                right: 0,
                height: trackLayout.height,
                child: Container(
                  padding: EdgeInsets.all(style.headerPadding),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: style.palette.headerDivider),
                    ),
                  ),
                  child: trackLayout.track.header(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRuler extends StatelessWidget {
  const _TimelineRuler({required this.viewport, required this.style});

  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: style.rulerHeight,
      child: CustomPaint(
        painter: _TimelineRulerPainter(
          viewport: viewport,
          style: style,
          textStyle: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _TimelineRulerPainter extends CustomPainter {
  const _TimelineRulerPainter({
    required this.viewport,
    required this.style,
    required this.textStyle,
  });

  final TimelineViewport viewport;
  final TimelineStyle style;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final background = Paint()..color = style.palette.rulerBackground;
    canvas.drawRect(Offset.zero & size, background);

    final minorStep = _tickStep(
      viewport.pixelsPerFrame,
      style.gridMinorMinSpacing,
    );
    final majorStep = _tickStep(
      viewport.pixelsPerFrame,
      style.gridMajorMinSpacing,
    );
    final startFrame = (viewport.visibleStartFrame ~/ minorStep) * minorStep;

    final divider = Paint()
      ..color = style.palette.headerDivider
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      divider,
    );

    for (
      var frame = startFrame;
      frame <= viewport.visibleEndFrame + majorStep;
      frame += minorStep
    ) {
      final x = viewport.frameToPixel(frame) - viewport.horizontalOffset;
      final isMajor = frame % majorStep == 0;
      final linePaint = Paint()
        ..color = isMajor ? style.palette.gridMajor : style.palette.gridMinor
        ..strokeWidth = isMajor ? 1.2 : 1;
      final top = isMajor ? 0.0 : size.height * 0.5;
      canvas.drawLine(Offset(x, top), Offset(x, size.height), linePaint);

      if (!isMajor) continue;
      TextPainter(
          text: TextSpan(
            text: "$frame",
            style: textStyle?.copyWith(color: style.palette.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(x + 4, 6));
    }
  }

  int _tickStep(double pixelsPerFrame, double minSpacing) {
    for (final step in style.gridTickSteps) {
      if (step * pixelsPerFrame >= minSpacing) {
        return step;
      }
    }
    return style.gridTickSteps.last;
  }

  @override
  bool shouldRepaint(covariant _TimelineRulerPainter oldDelegate) {
    return oldDelegate.viewport != viewport || oldDelegate.style != style;
  }
}

class _TimelinePlaneSurface extends HookWidget {
  const _TimelinePlaneSurface({
    required this.controller,
    required this.style,
    required this.viewport,
    required this.placement,
    required this.onCommitPreviews,
    required this.resolveMovePreviews,
    required this.resolveResizePreviews,
    super.key,
  });

  final TimelineController controller;
  final TimelineStyle style;
  final TimelineViewport viewport;
  final TimelinePlacementResult placement;
  final Future<void> Function(List<TimelinePreview> previews) onCommitPreviews;
  final List<MoveTimelinePreview> Function(TimelineIdentifier id)
  resolveMovePreviews;
  final List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizePreviews;

  @override
  Widget build(BuildContext context) {
    final lastScale = useRef(1.0);
    final lastFocalPoint = useRef(Offset.zero);

    void zoomAtPointer(double localDx, double scaleDelta) {
      controller.zoomAt(
        localDx: localDx,
        scaleDelta: scaleDelta,
        minPixelsPerFrame: style.minPixelsPerFrame,
        maxPixelsPerFrame: style.maxPixelsPerFrame,
        animate: false,
      );
    }

    void handlePointerSignal(PointerSignalEvent event) {
      if (event case PointerScrollEvent(
        :final scrollDelta,
        :final localPosition,
      )) {
        final pointerDevice = event.kind;
        final zoomIntent =
            HardwareKeyboard.instance.isMetaPressed ||
            HardwareKeyboard.instance.isControlPressed ||
            pointerDevice == PointerDeviceKind.trackpad;
        if (zoomIntent) {
          final scaleDelta = math.exp(-scrollDelta.dy * 0.0025);
          zoomAtPointer(localPosition.dx, scaleDelta);
          return;
        }
        controller.panBy(
          dx: scrollDelta.dx,
          dy: scrollDelta.dy,
          animate: false,
        );
      }
    }

    return ClipRect(
      child: Listener(
        onPointerSignal: handlePointerSignal,
        onPointerPanZoomUpdate: (event) {
          controller.panBy(
            dx: -event.panDelta.dx,
            dy: -event.panDelta.dy,
            animate: false,
          );
          zoomAtPointer(event.localPosition.dx, event.scale);
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            lastScale.value = 1;
            lastFocalPoint.value = details.localFocalPoint;
          },
          onScaleUpdate: (details) {
            if (details.pointerCount < 2) return;
            final focalDelta = details.localFocalPoint - lastFocalPoint.value;
            lastFocalPoint.value = details.localFocalPoint;
            controller.panBy(
              dx: -focalDelta.dx,
              dy: -focalDelta.dy,
              animate: false,
            );

            final scaleDelta = details.scale / lastScale.value;
            lastScale.value = details.scale;
            zoomAtPointer(details.localFocalPoint.dx, scaleDelta);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              if (controller.inPreview) return;
              controller.panBy(
                dx: -details.delta.dx,
                dy: -details.delta.dy,
                animate: false,
              );
            },
            child: TimelinePlane(
              placement: placement,
              viewport: viewport,
              style: style,
              children: [
                for (final placed in placement.visibleElements)
                  TimelinePlaneChild(
                    key: Key("TimelinePlaneChild-${placed.element.id}"),
                    rect: placed.rect,
                    childRect: placed.childrenRect,
                    color: placed.element.color,
                    child: placed.element.builder(
                      context,
                      TimelineElementBuildData(
                        placed: placed,
                        style: style,
                        controller: controller,
                        onCommitPreview: onCommitPreviews,
                        resolveMovePreviews: resolveMovePreviews,
                        resolveResizePreviews: resolveResizePreviews,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TimelineSegmentSurface extends HookConsumerWidget {
  const TimelineSegmentSurface({
    required this.data,
    required this.child,
    required this.fillColor,
    required this.outlineColor,
    required this.outlineWidth,
    super.key,
  });

  final TimelineElementBuildData data;
  final Widget child;
  final Color fillColor;
  final Color outlineColor;
  final double outlineWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDelta = useState(0.0);
    final placed = data.placed;
    final style = data.style;
    final controller = data.controller;
    final segment = placed.element as TimelineSegment;
    return Stack(
      children: [
        Positioned.fill(
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) {
                totalDelta.value = 0;
                controller.startInteractionSession(
                  previews: data.resolveMovePreviews(segment.id),
                );
                ref
                    .read(currentInteractionModeProvider.notifier)
                    .setMode(TimelineMoveMode());
              },
              onHorizontalDragUpdate: (details) {
                totalDelta.value += details.delta.dx;
                controller.updateInteraction(totalDelta.value);
              },
              onHorizontalDragCancel: () {
                controller.cancelInteraction();
                ref.read(currentInteractionModeProvider.notifier).normal();
              },
              onHorizontalDragEnd: (_) {
                data.onCommitPreview(controller.finishInteractionSession());
                ref.read(currentInteractionModeProvider.notifier).normal();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: style.edgeHandleWidth / 2,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: outlineColor,
                        width: outlineWidth,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IgnorePointer(child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: style.edgeHandleWidth,
          child: _ResizeHandle(
            cursor: SystemMouseCursors.resizeLeftRight,
            onStart: () {
              totalDelta.value = 0;
              controller.startInteractionSession(
                previews: data.resolveResizePreviews(
                  segment.id,
                  TimelineInteractionMode.resizeStart,
                ),
              );
              ref
                  .read(currentInteractionModeProvider.notifier)
                  .setMode(
                    TimelineResizeMode(
                      mode: TimelineInteractionMode.resizeStart,
                    ),
                  );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () {
              data.onCommitPreview(controller.finishInteractionSession());
              ref.read(currentInteractionModeProvider.notifier).normal();
            },
            onCancel: () {
              controller.cancelInteraction();
              ref.read(currentInteractionModeProvider.notifier).normal();
            },
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: style.edgeHandleWidth,
          child: _ResizeHandle(
            cursor: SystemMouseCursors.resizeLeftRight,
            onStart: () {
              totalDelta.value = 0;
              controller.startInteractionSession(
                previews: data.resolveResizePreviews(
                  segment.id,
                  TimelineInteractionMode.resizeEnd,
                ),
              );
              ref
                  .read(currentInteractionModeProvider.notifier)
                  .setMode(
                    TimelineResizeMode(mode: TimelineInteractionMode.resizeEnd),
                  );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () {
              data.onCommitPreview(controller.finishInteractionSession());
              ref.read(currentInteractionModeProvider.notifier).normal();
            },
            onCancel: () {
              controller.cancelInteraction();
              ref.read(currentInteractionModeProvider.notifier).normal();
            },
          ),
        ),
      ],
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    required this.cursor,
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.onCancel,
  });

  final MouseCursor cursor;
  final VoidCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final VoidCallback onEnd;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onStart(),
        onHorizontalDragUpdate: onUpdate,
        onHorizontalDragCancel: onCancel,
        onHorizontalDragEnd: (_) => onEnd(),
      ),
    );
  }
}

class TimelineKeyframeSurface extends HookConsumerWidget {
  const TimelineKeyframeSurface({
    required this.data,
    required this.child,
    required this.fillColor,
    required this.outlineColor,
    required this.outlineWidth,
    super.key,
  });

  final TimelineElementBuildData data;
  final Widget child;
  final Color fillColor;
  final Color outlineColor;
  final double outlineWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalDelta = useState(0.0);
    final keyframe = data.placed.element as TimelineKeyframe;
    final style = data.style;
    final controller = data.controller;

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          totalDelta.value = 0;
          controller.startInteractionSession(
            previews: data.resolveMovePreviews(keyframe.id),
          );
          ref
              .read(currentInteractionModeProvider.notifier)
              .setMode(TimelineMoveMode());
        },
        onHorizontalDragUpdate: (details) {
          totalDelta.value += details.delta.dx;
          controller.updateInteraction(totalDelta.value);
        },
        onHorizontalDragCancel: () {
          controller.cancelInteraction();
          ref.read(currentInteractionModeProvider.notifier).normal();
        },
        onHorizontalDragEnd: (_) {
          data.onCommitPreview(controller.finishInteractionSession());
          ref.read(currentInteractionModeProvider.notifier).normal();
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: style.keyframeSize,
            height: style.keyframeSize,
            transform: Matrix4.rotationZ(math.pi / 4),
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: outlineColor, width: outlineWidth),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Center(child: IgnorePointer(child: child)),
            ),
          ),
        ),
      ),
    );
  }
}
