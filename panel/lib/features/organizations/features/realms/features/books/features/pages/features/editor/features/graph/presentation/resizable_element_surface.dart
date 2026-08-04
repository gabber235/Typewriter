import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

enum ResizableElementSlot { child, gestureDetector }

class ResizableElementSurface
    extends
        SlottedMultiChildRenderObjectWidget<ResizableElementSlot, RenderBox> {
  const ResizableElementSurface({
    required this.handleSize,
    required this.animationProgress,
    required this.outlineColor,
    required this.child,
    required this.gestureDetector,
    super.key,
  });

  final double handleSize;
  final double animationProgress;
  final Color outlineColor;
  final Widget child;
  final Widget gestureDetector;

  @override
  Iterable<ResizableElementSlot> get slots => ResizableElementSlot.values;

  @override
  Widget? childForSlot(ResizableElementSlot slot) {
    return switch (slot) {
      ResizableElementSlot.child => child,
      ResizableElementSlot.gestureDetector => gestureDetector,
    };
  }

  @override
  RenderResizableElementSurface createRenderObject(BuildContext context) {
    return RenderResizableElementSurface(
      handleSize: handleSize,
      animationProgress: animationProgress,
      outlineColor: outlineColor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderResizableElementSurface renderObject,
  ) {
    renderObject
      ..handleSize = handleSize
      ..animationProgress = animationProgress
      ..outlineColor = outlineColor;
  }
}

class RenderResizableElementSurface extends RenderBox
    with SlottedContainerRenderObjectMixin<ResizableElementSlot, RenderBox> {
  RenderResizableElementSurface({
    required double handleSize,
    required double animationProgress,
    required Color outlineColor,
  }) : _handleSize = handleSize,
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
    final child = childForSlot(ResizableElementSlot.child);
    final gestureDetector = childForSlot(ResizableElementSlot.gestureDetector);
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    (child.parentData! as BoxParentData).offset = Offset.zero;
    size = child.size;

    if (gestureDetector == null) return;
    gestureDetector.layout(BoxConstraints.tight(Size(handleSize, handleSize)));
    (gestureDetector.parentData! as BoxParentData).offset = Offset(
      size.width - handleSize / 2,
      size.height - handleSize / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = childForSlot(ResizableElementSlot.child);
    final gestureDetector = childForSlot(ResizableElementSlot.gestureDetector);
    if (child != null) {
      final parentData = child.parentData! as BoxParentData;
      context.paintChild(child, parentData.offset + offset);
    }
    if (gestureDetector == null) return;
    final parentData = gestureDetector.parentData! as BoxParentData;
    context.paintChild(gestureDetector, parentData.offset + offset);
    _paintOutline(context, offset, parentData.offset);
  }

  void _paintOutline(
    PaintingContext context,
    Offset offset,
    Offset handleOffset,
  ) {
    if (animationProgress <= 0) return;
    final paint = Paint()
      ..color = outlineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final padding = 2 * animationProgress + 3;
    final handleCenter =
        offset +
        handleOffset +
        Offset(handleSize / 2 + padding, handleSize / 2 + padding);
    const cornerRadius = 10.0;
    final path = Path()
      ..moveTo(handleCenter.dx - cornerRadius, handleCenter.dy)
      ..arcToPoint(
        Offset(handleCenter.dx, handleCenter.dy - cornerRadius),
        clockwise: false,
        radius: const Radius.circular(cornerRadius),
      );
    final metric = path.computeMetrics().firstOrNull;
    if (metric == null) return;
    final half = metric.length / 2;
    final currentHalf = half * animationProgress;
    context.canvas.drawPath(
      metric.extractPath(half - currentHalf, half + currentHalf),
      paint,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    if (!size.contains(position) || !hitTestSelf(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final gestureDetector = childForSlot(ResizableElementSlot.gestureDetector);
    if (gestureDetector != null &&
        _hitChild(result, position, gestureDetector)) {
      return true;
    }
    final child = childForSlot(ResizableElementSlot.child);
    return child != null && _hitChild(result, position, child);
  }

  bool _hitChild(BoxHitTestResult result, Offset position, RenderBox child) {
    final parentData = child.parentData! as BoxParentData;
    return result.addWithPaintOffset(
      offset: parentData.offset,
      position: position,
      hitTest: (result, transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }

  @override
  bool hitTestSelf(Offset position) => false;
}
