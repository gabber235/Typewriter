import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/timeline_modes.dart";
import "package:typewriter_panel/logic/timeline/timeline_data.dart";

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
