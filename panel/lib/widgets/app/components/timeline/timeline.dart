import "dart:async";
import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_controller.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_data.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_plane.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";
import "package:typewriter_panel/widgets/generic/components/drag_handle.dart";

typedef TimelineCommit =
    Future<void> Function((TimelineIdentifier, int, int) change);

class Timeline extends HookWidget {
  const Timeline({
    required this.data,
    this.onElementMoved,
    this.onElementResized,
    super.key,
  });

  final TimelineData data;
  final TimelineCommit? onElementMoved;
  final TimelineCommit? onElementResized;

  @override
  Widget build(BuildContext context) {
    final controller = useMemoized(TimelineController.new);
    useEffect(() => controller.dispose, [controller]);
    useListenable(controller);

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = TimelineStyle.fallback(Theme.of(context));
        final headerWidth = controller.headerWidth
            .clamp(
              style.minHeaderWidth,
              math.min(style.maxHeaderWidth, constraints.maxWidth * 0.55),
            )
            .toDouble();
        final handleWidth = 16.0;
        final bodyHeight = math.max(
          0.0,
          constraints.maxHeight - style.rulerHeight,
        );
        final planeWidth = math.max(
          0.0,
          constraints.maxWidth - headerWidth - handleWidth,
        );
        final provisionalViewport = TimelineViewport(
          headerWidth: headerWidth,
          planeWidth: planeWidth,
          planeHeight: bodyHeight,
          horizontalOffset: controller.horizontalOffset,
          verticalOffset: controller.verticalOffset,
          pixelsPerFrame: controller.pixelsPerFrame,
          overscanFrames: style.overscanFrames,
        );

        final layoutEngine = TimelineLayoutEngine(style: style);
        final provisionalLayout = layoutEngine.build(
          data: data,
          viewport: provisionalViewport,
          preview: controller.preview,
        );
        final viewport = provisionalViewport.copyWith(
          horizontalOffset: controller.horizontalOffset.clamp(
            0,
            math.max(0, provisionalLayout.contentWidth - planeWidth),
          ),
          verticalOffset: controller.verticalOffset.clamp(
            0,
            math.max(0, provisionalLayout.contentHeight - bodyHeight),
          ),
        );
        final layout = layoutEngine.build(
          data: data,
          viewport: viewport,
          preview: controller.preview,
        );

        Future<void> commitPreview(TimelinePreview? preview) async {
          if (preview == null) return;
          final change = (
            TimelineIdentifier(preview.id),
            preview.startFrame,
            preview.endFrame,
          );
          final callback = switch (preview.mode) {
            TimelineInteractionMode.move => onElementMoved,
            TimelineInteractionMode.resizeStart => onElementResized,
            TimelineInteractionMode.resizeEnd => onElementResized,
          };
          if (callback != null) {
            unawaited(callback(change));
          }
        }

        final plane = _TimelinePlaneSurface(
          controller: controller,
          style: style,
          viewport: viewport,
          layout: layout,
          onCommitPreview: commitPreview,
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
                      data: data,
                      layout: layout,
                      style: style,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: handleWidth,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Timeline", style: textTheme.titleSmall),
                Text(
                  "Frames ${viewport.visibleStartFrame} to ${viewport.visibleEndFrame}",
                  style: textTheme.bodySmall?.copyWith(
                    color: style.palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTrackHeaders extends StatelessWidget {
  const _TimelineTrackHeaders({
    required this.data,
    required this.layout,
    required this.style,
  });

  final TimelineData data;
  final TimelineLayoutResult layout;
  final TimelineStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.palette.headerBackground,
          border: Border(right: BorderSide(color: style.palette.headerDivider)),
        ),
        child: Stack(
          children: [
            for (final trackLayout in layout.tracks)
              Positioned(
                top: trackLayout.top,
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
    final background = Paint()..color = style.palette.rulerBackground;
    canvas.drawRect(Offset.zero & size, background);

    final minorStep = _tickStep(viewport.pixelsPerFrame, 12);
    final majorStep = _tickStep(viewport.pixelsPerFrame, 80);
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
      final x = viewport.frameToPixel(frame);
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
    const steps = [1, 2, 5, 10, 20, 40, 100, 200, 400];
    for (final step in steps) {
      if (step * pixelsPerFrame >= minSpacing) {
        return step;
      }
    }
    return steps.last;
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
    required this.layout,
    required this.onCommitPreview,
  });

  final TimelineController controller;
  final TimelineStyle style;
  final TimelineViewport viewport;
  final TimelineLayoutResult layout;
  final Future<void> Function(TimelinePreview? preview) onCommitPreview;

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
              if (controller.preview != null) return;
              controller.panBy(dx: -details.delta.dx, dy: -details.delta.dy);
            },
            child: TimelinePlane(
              layout: layout,
              viewport: viewport,
              style: style,
              children: [
                for (final placed in layout.visibleElements)
                  TimelinePlaneChild(
                    rect: placed.rect,
                    child: placed.element.builder(
                      context,
                      TimelineElementBuildData(
                        placed: placed,
                        style: style,
                        controller: controller,
                        onCommitPreview: onCommitPreview,
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
                controller.startMove(
                  id: segment.id.id,
                  startFrame: segment.startFrame,
                  endFrame: segment.endFrame,
                );
              },
              onHorizontalDragUpdate: (details) {
                totalDelta.value += details.delta.dx;
                controller.updateInteraction(totalDelta.value);
              },
              onHorizontalDragCancel: controller.cancelInteraction,
              onHorizontalDragEnd: (_) =>
                  data.onCommitPreview(controller.finishInteraction()),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
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
              controller.startResizeStart(
                id: segment.id.id,
                startFrame: segment.startFrame,
                endFrame: segment.endFrame,
              );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () => data.onCommitPreview(controller.finishInteraction()),
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
              controller.startResizeEnd(
                id: segment.id.id,
                startFrame: segment.startFrame,
                endFrame: segment.endFrame,
              );
            },
            onUpdate: (details) {
              totalDelta.value += details.delta.dx;
              controller.updateInteraction(totalDelta.value);
            },
            onEnd: () => data.onCommitPreview(controller.finishInteraction()),
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
          controller.startMove(
            id: keyframe.id.id,
            startFrame: keyframe.frame,
            endFrame: keyframe.frame,
          );
        },
        onHorizontalDragUpdate: (details) {
          totalDelta.value += details.delta.dx;
          controller.updateInteraction(totalDelta.value);
        },
        onHorizontalDragCancel: controller.cancelInteraction,
        onHorizontalDragEnd: (_) =>
            data.onCommitPreview(controller.finishInteraction()),
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
