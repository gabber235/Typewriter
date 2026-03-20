import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_layout.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_style.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline_viewport.dart";

class TimelinePlane extends MultiChildRenderObjectWidget {
  const TimelinePlane({
    required this.layout,
    required this.viewport,
    required this.style,
    super.key,
    super.children,
  });

  final TimelineLayoutResult layout;
  final TimelineViewport viewport;
  final TimelineStyle style;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTimelinePlane(
      timelineLayout: layout,
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
      ..timelineLayout = layout
      ..viewport = viewport
      ..style = style;
  }
}

class TimelinePlaneChild extends ParentDataWidget<_TimelinePlaneParentData> {
  const TimelinePlaneChild({
    required this.rect,
    required super.child,
    super.key,
  });

  final Rect rect;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as _TimelinePlaneParentData;
    if (parentData.rect == rect) return;
    parentData.rect = rect;
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
}

class RenderTimelinePlane extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TimelinePlaneParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TimelinePlaneParentData> {
  RenderTimelinePlane({
    required TimelineLayoutResult timelineLayout,
    required TimelineViewport viewport,
    required TimelineStyle style,
  }) : _timelineLayout = timelineLayout,
       _viewport = viewport,
       _style = style;

  TimelineLayoutResult _timelineLayout;
  TimelineViewport _viewport;
  TimelineStyle _style;

  TimelineLayoutResult get timelineLayout => _timelineLayout;

  set timelineLayout(TimelineLayoutResult value) {
    if (_timelineLayout == value) return;
    _timelineLayout = value;
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
      parentData.offset = parentData.rect.topLeft;
      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final bounds = offset & size;
    canvas.drawRect(bounds, Paint()..color = _style.palette.trackBackground);
    _paintTracks(canvas, offset);
    _paintGrid(canvas, offset);
    defaultPaint(context, offset);
  }

  void _paintTracks(Canvas canvas, Offset offset) {
    final dividerPaint = Paint()
      ..color = _style.palette.headerDivider
      ..strokeWidth = 1;
    for (final track in _timelineLayout.tracks) {
      final rect = Rect.fromLTWH(
        offset.dx,
        offset.dy + track.top,
        size.width,
        track.height,
      );
      if (!rect.overlaps(offset & size)) continue;
      canvas
        ..drawRect(rect, Paint()..color = track.backgroundColor)
        ..drawLine(rect.bottomLeft, rect.bottomRight, dividerPaint);
    }
  }

  void _paintGrid(Canvas canvas, Offset offset) {
    final minorStep = _tickStep(_viewport.pixelsPerFrame, 12);
    final majorStep = _tickStep(_viewport.pixelsPerFrame, 80);
    final startMinor = (_viewport.visibleStartFrame ~/ minorStep) * minorStep;
    for (
      var frame = startMinor;
      frame <= _viewport.visibleEndFrame + majorStep;
      frame += minorStep
    ) {
      final x = offset.dx + _viewport.frameToPixel(frame);
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
    const steps = [1, 2, 5, 10, 20, 40, 100, 200, 400];
    for (final step in steps) {
      if (step * pixelsPerFrame >= minSpacing) {
        return step;
      }
    }
    return steps.last;
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
