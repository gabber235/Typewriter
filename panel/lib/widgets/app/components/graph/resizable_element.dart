import "dart:io" show Platform;
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/generic/components/cursor_controller.dart";

import "graph.dart";

enum _ResizableSlot {
  child,
  gestureDetector,
}

/// A widget that makes its child resizable by adding a gesture detector handle
/// in the bottom-right corner.
///
/// This implementation uses a slotted render object widget to ensure proper
/// hit testing for the gesture detector handle, even when it extends outside
/// the bounds of the child widget.
class ResizableElement extends HookConsumerWidget {
  const ResizableElement({
    required this.element,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
    required this.child,
    required this.cellSize,
    this.handleSize = 25,
    super.key,
  });

  final GraphElement element;
  final GraphResizeCallback? onResizeStart;
  final GraphResizeCallback? onResizeUpdate;
  final GraphResizeCallback? onResizeEnd;
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

    final newWidth = max(originalWidth + deltaCellWidth, 1);
    final newHeight = max(originalHeight + deltaCellHeight, 1);

    return (newWidth, newHeight);
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

    return _ResizableElementSlotted(
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
            : !kIsWeb && Platform.isMacOS
                ? SystemMouseCursors.grab
                : SystemMouseCursors.resizeUpLeftDownRight,
        child: GestureDetector(
          onPanStart: onResizeStart != null
              ? (details) {
                  ref
                      .read(cursorControllerProvider.notifier)
                      .cursor(SystemMouseCursors.grabbing);
                  animationController.forward();
                  startData.value =
                      (details.localPosition, element.width, element.height);
                  onResizeStart!(element.id, element.width, element.height);
                }
              : null,
          onPanUpdate: onResizeUpdate != null
              ? (details) {
                  final delta = details.localPosition - startData.value!.$1;
                  final (newWidth, newHeight) = _calculateNewSize(
                    delta.dx,
                    delta.dy,
                    startData.value!.$2,
                    startData.value!.$3,
                  );
                  onResizeUpdate!(element.id, newWidth, newHeight);
                }
              : null,
          onPanEnd: onResizeEnd != null
              ? (details) {
                  final delta = details.localPosition - startData.value!.$1;
                  final (newWidth, newHeight) = _calculateNewSize(
                    delta.dx,
                    delta.dy,
                    startData.value!.$2,
                    startData.value!.$3,
                  );
                  onResizeEnd!(element.id, newWidth, newHeight);
                  startData.value = null;
                  ref.read(cursorControllerProvider.notifier).reset();
                  if (!isHovering.value) {
                    animationController.reverse();
                  }
                }
              : null,
          child: Container(
            width: handleSize,
            height: handleSize,
            color: Colors.transparent,
          ),
        ),
      ),
      child: child,
    );
  }
}

/// Internal slotted widget that handles the layout and positioning logic.
class _ResizableElementSlotted
    extends SlottedMultiChildRenderObjectWidget<_ResizableSlot, RenderBox> {
  const _ResizableElementSlotted({
    required this.handleSize,
    required this.animationProgress,
    required this.outlineColor,
    required this.child,
    required this.gestureDetector,
  });

  final double handleSize;
  final double animationProgress;
  final Color outlineColor;
  final Widget child;
  final Widget gestureDetector;

  @override
  Iterable<_ResizableSlot> get slots => _ResizableSlot.values;

  @override
  Widget? childForSlot(_ResizableSlot slot) {
    switch (slot) {
      case _ResizableSlot.child:
        return child;
      case _ResizableSlot.gestureDetector:
        return gestureDetector;
    }
  }

  @override
  SlottedContainerRenderObjectMixin<_ResizableSlot, RenderBox>
      createRenderObject(BuildContext context) {
    return _RenderResizableElement(
      handleSize: handleSize,
      animationProgress: animationProgress,
      outlineColor: outlineColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizableElement renderObject,
  ) {
    renderObject
      ..handleSize = handleSize
      ..animationProgress = animationProgress
      ..outlineColor = outlineColor;
  }
}

/// Render object that positions the child and gesture detector handle.
///
/// This render object is transparent in terms of layout - it passes constraints
/// directly to its child and adopts the child's size. However, it positions
/// the gesture detector handle in the bottom-right corner and ensures proper
/// hit testing for it.
///
/// **Layout Strategy**:
/// - **Child**: Gets the incoming constraints and is positioned at (0,0)
/// - **Gesture detector**: Gets tight constraints based on handle size and is
///   positioned at the bottom-right corner of the child
/// - **This render object**: Adopts the child's size exactly
///
/// **Hit Testing**:
/// The gesture detector handle may extend outside the bounds of this render
/// object (when positioned at bottom-right of child). We override hit testing
/// to ensure the gesture detector can still receive hits even when outside
/// our bounds.
class _RenderResizableElement extends RenderBox
    with SlottedContainerRenderObjectMixin<_ResizableSlot, RenderBox> {
  _RenderResizableElement({
    required double handleSize,
    required double animationProgress,
    required Color outlineColor,
  })  : _handleSize = handleSize,
        _animationProgress = animationProgress,
        _outlineColor = outlineColor;

  double _handleSize;
  double get handleSize => _handleSize;
  set handleSize(double value) {
    if (_handleSize == value) return;
    _handleSize = value;
    markNeedsLayout();
  }

  double _animationProgress;
  double get animationProgress => _animationProgress;
  set animationProgress(double value) {
    if (_animationProgress == value) return;
    _animationProgress = value;
    markNeedsPaint();
  }

  Color _outlineColor;
  Color get outlineColor => _outlineColor;
  set outlineColor(Color value) {
    if (_outlineColor == value) return;
    _outlineColor = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    final childRenderBox = childForSlot(_ResizableSlot.child);
    final gestureDetectorRenderBox =
        childForSlot(_ResizableSlot.gestureDetector);

    if (childRenderBox == null) {
      size = constraints.smallest;
      return;
    }

    // Layout the child with the incoming constraints
    childRenderBox.layout(constraints, parentUsesSize: true);
    (childRenderBox.parentData! as BoxParentData).offset = Offset.zero;

    // Adopt the child's size
    size = childRenderBox.size;

    if (gestureDetectorRenderBox != null) {
      gestureDetectorRenderBox.layout(
        BoxConstraints.tight(Size(_handleSize, _handleSize)),
      );

      final handleOffset = Offset(
        size.width - _handleSize / 2,
        size.height - _handleSize / 2,
      );
      (gestureDetectorRenderBox.parentData! as BoxParentData).offset =
          handleOffset;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final childRenderBox = childForSlot(_ResizableSlot.child);
    final gestureDetectorRenderBox =
        childForSlot(_ResizableSlot.gestureDetector);

    if (childRenderBox != null) {
      final childParentData = childRenderBox.parentData! as BoxParentData;
      context.paintChild(childRenderBox, childParentData.offset + offset);
    }

    if (gestureDetectorRenderBox != null) {
      final handleParentData =
          gestureDetectorRenderBox.parentData! as BoxParentData;
      context.paintChild(
        gestureDetectorRenderBox,
        handleParentData.offset + offset,
      );

      _paintOutline(context, offset, handleParentData.offset);
    }
  }

  void _paintOutline(
    PaintingContext context,
    Offset offset,
    Offset handleOffset,
  ) {
    if (_animationProgress <= 0) return;

    final paint = Paint()
      ..color = _outlineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final padding = 2.0 * _animationProgress + 3.0;

    final handleCenter = offset +
        handleOffset +
        Offset(handleSize / 2 + padding, handleSize / 2 + padding);
    final cornerRadius = 10.0;

    final path = Path()
      ..moveTo(handleCenter.dx - cornerRadius, handleCenter.dy)
      ..arcToPoint(
        Offset(handleCenter.dx, handleCenter.dy - cornerRadius),
        clockwise: false,
        radius: Radius.circular(cornerRadius),
      );

    final metrics = path.computeMetrics();
    final metric = metrics.firstOrNull;
    if (metric == null) {
      return;
    }
    final totalLength = metric.length;
    final half = totalLength / 2;
    final currentHalf = half * _animationProgress;
    final start = half - currentHalf;
    final end = half + currentHalf;
    final subPath = metric.extractPath(start, end);

    context.canvas.drawPath(subPath, paint);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    if (size.contains(position) && hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final childRenderBox = childForSlot(_ResizableSlot.child);
    final gestureDetectorRenderBox =
        childForSlot(_ResizableSlot.gestureDetector);

    if (gestureDetectorRenderBox != null) {
      final handleParentData =
          gestureDetectorRenderBox.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: handleParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return gestureDetectorRenderBox.hitTest(
            result,
            position: transformed,
          );
        },
      );
      if (isHit) return true;
    }

    if (childRenderBox != null) {
      final childParentData = childRenderBox.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (result, transformed) {
          return childRenderBox.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }

    return false;
  }

  @override
  bool hitTestSelf(Offset position) => false;
}
