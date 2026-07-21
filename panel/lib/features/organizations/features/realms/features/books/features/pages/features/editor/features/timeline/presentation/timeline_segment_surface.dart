import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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
                  horizontal: data.element.hasChildren
                      ? style.edgeHandleWidth / 2
                      : 0,
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
