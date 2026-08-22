import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ResizableElement extends HookConsumerWidget {
  const ResizableElement({
    required this.element,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.child,
    required this.cellSize,
    this.handleSize = 25,
    this.onResizeCancel,
    super.key,
  });

  final GraphElement element;
  final GraphResizeCallback? onResizeStart;
  final GraphResizeCallback? onResizeUpdate;
  final GraphResizeCallback? onResizeEnd;
  final VoidCallback? onResizeCancel;
  final Widget child;
  final double cellSize;
  final double handleSize;

  (int, int) _calculateNewSize(
    double deltaWidth,
    double deltaHeight,
    int originalWidth,
    int originalHeight,
  ) {
    final deltaCellWidth = (deltaWidth / cellSize).round();
    final deltaCellHeight = (deltaHeight / cellSize).round();
    return (
      max(originalWidth + deltaCellWidth, 1),
      max(originalHeight + deltaCellHeight, 1),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController = useAnimationController(
      duration: 700.ms,
      reverseDuration: 250.ms,
    );
    final animation = useAnimation(
      CurvedAnimation(
        parent: animationController,
        curve: ElasticOutCurve(0.4),
        reverseCurve: Curves.fastLinearToSlowEaseIn,
      ),
    );
    final isHovering = useState(false);
    final startData = useState<(Offset, int, int)?>(null);

    void resetInteraction() {
      startData.value = null;
      ref.read(cursorControllerProvider.notifier).reset();
      if (!isHovering.value) animationController.reverse();
    }

    return ResizableElementSurface(
      handleSize: handleSize,
      animationProgress: animation,
      outlineColor: Theme.of(context).colorScheme.onSurface,
      gestureDetector: MouseRegion(
        onEnter: (_) {
          isHovering.value = true;
          if (startData.value != null) return;
          animationController.forward();
        },
        onExit: (_) {
          isHovering.value = false;
          if (startData.value != null) return;
          animationController.reverse();
        },
        cursor: startData.value != null
            ? SystemMouseCursors.grabbing
            : !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS
            ? SystemMouseCursors.grab
            : SystemMouseCursors.resizeUpLeftDownRight,
        child: GestureDetector(
          onPanStart: onResizeStart == null
              ? null
              : (details) {
                  ref
                      .read(cursorControllerProvider.notifier)
                      .cursor(SystemMouseCursors.grabbing);
                  animationController.forward();
                  startData.value = (
                    details.localPosition,
                    element.width,
                    element.height,
                  );
                  onResizeStart!(element.id, element.width, element.height);
                },
          onPanUpdate: onResizeUpdate == null
              ? null
              : (details) {
                  final start = startData.value;
                  if (start == null) return;
                  final delta = details.localPosition - start.$1;
                  final (width, height) = _calculateNewSize(
                    delta.dx,
                    delta.dy,
                    start.$2,
                    start.$3,
                  );
                  onResizeUpdate!(element.id, width, height);
                },
          onPanEnd: onResizeEnd == null
              ? null
              : (details) {
                  final start = startData.value;
                  if (start == null) return;
                  final delta = details.localPosition - start.$1;
                  final (width, height) = _calculateNewSize(
                    delta.dx,
                    delta.dy,
                    start.$2,
                    start.$3,
                  );
                  onResizeEnd!(element.id, width, height);
                  resetInteraction();
                },
          onPanCancel: () {
            if (startData.value == null) return;
            onResizeCancel?.call();
            resetInteraction();
          },
          child: ColoredBox(
            color: Colors.transparent,
            child: SizedBox(width: handleSize, height: handleSize),
          ),
        ),
      ),
      child: child,
    );
  }
}
