import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_placement.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";

class TimelinePlane extends MultiChildRenderObjectWidget {
  const TimelinePlane({
    required this.placement,
    required this.viewport,
    required this.style,
    super.key,
    super.children,
  });

  final TimelinePlacementResult placement;
  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTimelinePlane(
      timelinePlacement: placement,
      viewport: viewport,
      style: style,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTimelinePlane renderObject,
  ) {
    renderObject
      ..timelinePlacement = placement
      ..viewport = viewport
      ..style = style;
  }
}

class TimelinePlaneChild extends ParentDataWidget<_TimelinePlaneParentData> {
  const TimelinePlaneChild({
    required this.rect,
    required this.childRect,
    required this.color,
    required super.child,
    super.key,
  });

  final Rect rect;
  final Rect? childRect;
  final Color color;

  @override
  void applyParentData(RenderObject renderObject) {
    renderObject.parentData! as _TimelinePlaneParentData
      ..rect = rect
      ..childRect = childRect
      ..color = color;
    final parent = renderObject.parent;
    if (parent is RenderObject) {
      parent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => TimelinePlane;
}

class _TimelinePlaneParentData extends ContainerBoxParentData<RenderBox> {
  Rect rect = Rect.zero;
  Rect? childRect;
  Color color = Colors.transparent;
}

class RenderTimelinePlane extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TimelinePlaneParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TimelinePlaneParentData> {
  RenderTimelinePlane({
    required TimelinePlacementResult timelinePlacement,
    required TimelineViewport viewport,
    required TimelineStyle style,
  }) : _timelinePlacement = timelinePlacement,
       _viewport = viewport,
       _style = style;

  TimelinePlacementResult _timelinePlacement;
  TimelineViewport _viewport;
  TimelineStyle _style;

  TimelinePlacementResult get timelinePlacement => _timelinePlacement;

  set timelinePlacement(TimelinePlacementResult value) {
    if (_timelinePlacement == value) return;
    _timelinePlacement = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  set viewport(TimelineViewport value) {
    if (_viewport == value) return;
    _viewport = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  TimelineViewport get viewport => _viewport;

  set style(TimelineStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsLayout();
    markNeedsPaint();
  }

  TimelineStyle get style => _style;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! _TimelinePlaneParentData) {
      child.parentData = _TimelinePlaneParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _TimelinePlaneParentData;
      child.layout(BoxConstraints.tight(parentData.rect.size));
      parentData.offset =
          parentData.rect.topLeft -
          Offset(viewport.horizontalOffset, viewport.verticalOffset);
      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    canvas.drawRect(bounds, Paint()..color = _style.palette.trackBackground);
    _paintTracks(canvas, offset);
    _paintElementBackgrounds(canvas, offset);
    _paintGrid(canvas, offset);
    defaultPaint(context, offset);
  }

  void _paintTracks(Canvas canvas, Offset offset) {
    final dividerPaint = Paint()
      ..color = _style.palette.headerDivider
      ..strokeWidth = 1;
    for (final track in _timelinePlacement.tracks) {
      final rect = Rect.fromLTWH(
        offset.dx,
        offset.dy + track.top - viewport.verticalOffset,
        size.width,
        track.height,
      );
      final screenRect = offset & size;
      if (!rect.overlaps(screenRect)) continue;
      final visibleRect = rect.intersect(screenRect);
      canvas
        ..drawRect(visibleRect, Paint()..color = track.backgroundColor)
        ..drawLine(rect.bottomLeft, rect.bottomRight, dividerPaint);
    }
  }

  void _paintElementBackgrounds(Canvas canvas, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _TimelinePlaneParentData;
      final childRect = parentData.childRect;
      child = parentData.nextSibling;
      if (childRect == null) continue;
      final rect = Rect.fromLTWH(
        offset.dx + childRect.left - viewport.horizontalOffset,
        offset.dy + childRect.top - viewport.verticalOffset,
        childRect.width,
        childRect.height,
      );
      final screenRect = offset & size;
      if (!rect.overlaps(screenRect)) continue;
      final color = Color.alphaBlend(
        parentData.color.withValues(alpha: 0.25),
        style.palette.trackBackground,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(8)),
        Paint()..color = color,
      );
    }
  }

  void _paintGrid(Canvas canvas, Offset offset) {
    final minorStep = _tickStep(
      _viewport.pixelsPerFrame,
      _style.gridMinorMinSpacing,
    );
    final majorStep = _tickStep(
      _viewport.pixelsPerFrame,
      _style.gridMajorMinSpacing,
    );
    final startMinor = (_viewport.visibleStartFrame ~/ minorStep) * minorStep;
    for (
      var frame = startMinor;
      frame <= _viewport.visibleEndFrame + majorStep;
      frame += minorStep
    ) {
      final x =
          offset.dx + _viewport.frameToPixel(frame) - viewport.horizontalOffset;
      final isMajor = frame % majorStep == 0;
      final paint = Paint()
        ..color = isMajor ? _style.palette.gridMajor : _style.palette.gridMinor
        ..strokeWidth = isMajor ? 1.2 : 1;
      canvas.drawLine(
        Offset(x, offset.dy),
        Offset(x, offset.dy + size.height),
        paint,
      );
    }
  }

  int _tickStep(double pixelsPerFrame, double minSpacing) {
    for (final step in _style.gridTickSteps) {
      if (step * pixelsPerFrame >= minSpacing) {
        return step;
      }
    }
    return _style.gridTickSteps.last;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final children = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      children.add(child);
      final parentData = child.parentData! as _TimelinePlaneParentData;
      child = parentData.nextSibling;
    }

    for (final child in children.reversed) {
      final parentData = child.parentData! as _TimelinePlaneParentData;
      if (result.addWithPaintOffset(
        offset: parentData.offset,
        position: position,
        hitTest: (result, transformed) =>
            child.hitTest(result, position: transformed),
      )) {
        return true;
      }
    }
    return false;
  }
}
