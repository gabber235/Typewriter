import "dart:math" as math;

import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/timeline/timeline_controller.dart";
import "package:typewriter_panel/logic/timeline/timeline_data.dart";
import "package:typewriter_panel/logic/timeline/timeline_placement.dart";
import "package:typewriter_panel/logic/timeline/timeline_viewport.dart";
import "package:typewriter_panel/utils/2d_focus_traversal_policy.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_plane.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";

class TimelinePlaneSurface extends HookWidget {
  const TimelinePlaneSurface({
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
            child: FocusTraversalGroup(
              policy: TwoDFocusTraversalPolicy(),
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
      ),
    );
  }
}
