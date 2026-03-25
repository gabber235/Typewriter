import "dart:async";
import "dart:math" as math;

import "package:collection/collection.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_placement.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_plane.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";

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

typedef TimelineCommit = Future<void> Function(TimelineCommitPayload change);
typedef TimelineMoveCommit =
    Future<void> Function(List<TimelineCommitPayload> changes);

class Timeline extends HookWidget {
  const Timeline({
    required this.data,
    this.onElementMoved,
    this.onElementResized,
    this.resolveMoveTargets,
    super.key,
  });

  final TimelineData data;
  final TimelineMoveCommit? onElementMoved;
  final TimelineCommit? onElementResized;
  final List<TimelineIdentifier> Function(TimelineIdentifier draggedId)?
  resolveMoveTargets;

  @override
  Widget build(BuildContext context) {
    final controller = useTimelineController(
        headerWidth: context.responsive(mobile: 100, desktop: 200),
    );

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

            List<MoveTimelinePreview> resolveMovePreviews(
              TimelineIdentifier draggedId,
            ) {
              final targetIds = resolveMoveTargets?.call(draggedId);
              final orderedIds = targetIds == null || targetIds.isEmpty
                  ? {draggedId}
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

            List<TimelinePreview> resolveResizeSessionSeeds(
              TimelineIdentifier id,
              TimelineInteractionMode mode,
            ) {
              final source = data.elementsById[id];
              if (source is! TimelineSegment) return const [];

              final preview = buildResizePreview(source, mode);
              if (preview == null) return const [];

              final adjacent = findAdjacentPreview(id, mode);
              return adjacent == null ? [preview] : [preview, adjacent];
            }

            Future<void> commitPreview(List<TimelinePreview> previews) async {
              if (previews.isEmpty) return;

              final moves = <TimelineCommitPayload>[];
              final awaits = <Future<void>>[];

              for (final preview in previews) {
                final commit = TimelineCommitPayload(
                  id: preview.id,
                  startFrame: preview.startFrame,
                  endFrame: preview.endFrame,
                );
                if (preview is MoveTimelinePreview) {
                  moves.add(commit);
                  continue;
                }
                if (onElementResized != null) {
                  awaits.add(onElementResized!(commit));
                }
              }

              if (moves.isNotEmpty && onElementMoved != null) {
                awaits.add(onElementMoved!(moves));
              }

              await Future.wait(awaits);
            }

            final plane = _TimelinePlaneSurface(
              controller: controller,
              style: style,
              viewport: viewport,
              placement: placement,
              onCommitPreview: commitPreview,
              resolveMovePreviews: resolveMovePreviews,
              resolveResizeSessionSeeds: resolveResizeSessionSeeds,
            );

            return Row(
              children: [
                SizedBox(
                  width: headerWidth,
                  child: Column(
                    children: [
                      _TimelineTopLeftHeader(viewport: viewport, style: style),
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
                      Expanded(child: plane),
                    ],
                  ),
                ),
              ],
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
      child: Center(
        child: Text("Timeline", style: textTheme.titleSmall),
      ),
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
        decoration: BoxDecoration(
          color: style.palette.headerBackground,
        ),
        child: Stack(
          children: [
            for (final trackLayout in placement.tracks.where((element) => element.isVisible(viewport)))
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
    required this.onCommitPreview,
    required this.resolveMovePreviews,
    required this.resolveResizeSessionSeeds,
  });

  final TimelineController controller;
  final TimelineStyle style;
  final TimelineViewport viewport;
  final TimelinePlacementResult placement;
  final Future<void> Function(List<TimelinePreview> previews) onCommitPreview;
  final List<MoveTimelinePreview> Function(TimelineIdentifier id)
  resolveMovePreviews;
  final List<TimelinePreview> Function(
    TimelineIdentifier id,
    TimelineInteractionMode mode,
  )
  resolveResizeSessionSeeds;

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
        controller.panBy(dx: scrollDelta.dx, dy: scrollDelta.dy);
      }
    }

    return ClipRect(
      child: Listener(
        onPointerSignal: handlePointerSignal,
        onPointerPanZoomUpdate: (event) {
          controller.panBy(dx: -event.panDelta.dx, dy: -event.panDelta.dy);
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
            controller.panBy(dx: -focalDelta.dx, dy: -focalDelta.dy);

            final scaleDelta = details.scale / lastScale.value;
            lastScale.value = details.scale;
            zoomAtPointer(details.localFocalPoint.dx, scaleDelta);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              if (controller.inPreview) return;
              controller.panBy(dx: -details.delta.dx, dy: -details.delta.dy);
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
                        onCommitPreview: onCommitPreview,
                        resolveMovePreviews: resolveMovePreviews,
                        resolveResizeSessionSeeds: resolveResizeSessionSeeds,
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

class TimelineSegmentSurface extends HookWidget {
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
  Widget build(BuildContext context) {
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
              },
              onHorizontalDragUpdate: (details) {
                totalDelta.value += details.delta.dx;
                controller.updateInteraction(totalDelta.value);
              },
              onHorizontalDragCancel: controller.cancelInteraction,
              onHorizontalDragEnd: (_) {
                data.onCommitPreview(controller.finishInteractionSession());
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
                previews: data.resolveResizeSessionSeeds(
                  segment.id,
                  TimelineInteractionMode.resizeStart,
                ),
              );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () =>
                data.onCommitPreview(controller.finishInteractionSession()),
            onCancel: controller.cancelInteraction,
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
                previews: data.resolveResizeSessionSeeds(
                  segment.id,
                  TimelineInteractionMode.resizeEnd,
                ),
              );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () =>
                data.onCommitPreview(controller.finishInteractionSession()),
            onCancel: controller.cancelInteraction,
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

class TimelineKeyframeSurface extends HookWidget {
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
  Widget build(BuildContext context) {
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
        },
        onHorizontalDragUpdate: (details) {
          totalDelta.value += details.delta.dx;
          controller.updateInteraction(totalDelta.value);
        },
        onHorizontalDragCancel: controller.cancelInteraction,
        onHorizontalDragEnd: (_) =>
            data.onCommitPreview(controller.finishInteractionSession()),
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
