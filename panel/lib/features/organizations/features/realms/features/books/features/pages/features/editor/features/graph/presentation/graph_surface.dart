import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class GraphSurface extends MultiChildRenderObjectWidget {
  GraphSurface({
    required this.layout,
    required this.viewport,
    required this.dotColor,
    required List<GraphPlacedElement> visibleElements,
    required Widget Function(GraphPlacedElement placed) buildChild,
    super.key,
  }) : visibleIds = Set.unmodifiable(
         visibleElements.map((placed) => placed.id),
       ),
       super(
         children: [
           for (final placed in visibleElements)
             GraphSurfaceChild(
               key: ValueKey(placed.id),
               placed: placed,
               child: buildChild(placed),
             ),
         ],
       );

  final GraphLayoutResult layout;
  final Rect viewport;
  final Color dotColor;
  final Set<GraphIdentifier> visibleIds;

  @override
  RenderGraphSurface createRenderObject(BuildContext context) {
    return RenderGraphSurface(
      layout: layout,
      viewport: viewport,
      dotColor: dotColor,
      visibleIds: visibleIds,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGraphSurface renderObject,
  ) {
    renderObject
      ..graphLayout = layout
      ..viewport = viewport
      ..dotColor = dotColor
      ..visibleIds = visibleIds;
  }
}

class GraphSurfaceChild extends ParentDataWidget<GraphSurfaceParentData> {
  const GraphSurfaceChild({
    required this.placed,
    required super.child,
    super.key,
  });

  final GraphPlacedElement placed;

  @override
  void applyParentData(RenderObject renderObject) {
    final parentData = renderObject.parentData! as GraphSurfaceParentData;
    if (parentData.placed == placed) return;
    parentData.placed = placed;
    final parent = renderObject.parent;
    if (parent is RenderObject) parent.markNeedsLayout();
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GraphSurface;
}

class GraphSurfaceParentData extends ContainerBoxParentData<RenderBox> {
  GraphPlacedElement? placed;
}

class RenderGraphSurface extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, GraphSurfaceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, GraphSurfaceParentData> {
  RenderGraphSurface({
    required GraphLayoutResult layout,
    required Rect viewport,
    required Color dotColor,
    required Set<GraphIdentifier> visibleIds,
  }) : _layout = layout,
       _viewport = viewport,
       _dotColor = dotColor,
       _visibleIds = visibleIds;

  GraphLayoutResult _layout;
  GraphLayoutResult get graphLayout => _layout;
  set graphLayout(GraphLayoutResult value) {
    if (identical(_layout, value)) return;
    _layout = value;
    markNeedsLayout();
  }

  Rect _viewport;
  Rect get viewport => _viewport;
  set viewport(Rect value) {
    if (_viewport == value) return;
    _viewport = value;
    markNeedsPaint();
  }

  Color _dotColor;
  Color get dotColor => _dotColor;
  set dotColor(Color value) {
    if (_dotColor == value) return;
    _dotColor = value;
    markNeedsPaint();
  }

  Set<GraphIdentifier> _visibleIds;
  Set<GraphIdentifier> get visibleIds => _visibleIds;
  set visibleIds(Set<GraphIdentifier> value) {
    if (setEquals(_visibleIds, value)) return;
    _visibleIds = value;
    markNeedsPaint();
  }

  @visibleForTesting
  List<GraphPlacedEdge> get visibleEdges => graphLayout.edgesFor(visibleIds);

  @visibleForTesting
  ({int stride, double fadingOpacity, double radius}) get dotPattern {
    final pattern = _dotPattern;
    return (
      stride: pattern.stride,
      fadingOpacity: pattern.fadingOpacity,
      radius: pattern.radius,
    );
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! GraphSurfaceParentData) {
      child.parentData = GraphSurfaceParentData();
    }
  }

  @override
  void performLayout() {
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as GraphSurfaceParentData;
      final placed = parentData.placed;
      assert(placed != null, "Graph placement must be provided");
      child.layout(
        BoxConstraints(
          minWidth: graphLayout.data.cellSize,
          minHeight: graphLayout.data.cellSize,
          maxWidth: placed!.bounds.width,
          maxHeight: placed.bounds.height,
        ),
      );
      parentData.offset = placed.position;
      child = parentData.nextSibling;
    }
    size = const Size(1, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintDots(context, offset);
    _paintEdges(context, offset);
    defaultPaint(context, offset);
  }

  void _paintDots(PaintingContext context, Offset offset) {
    final cellSize = graphLayout.data.cellSize;
    final pattern = _dotPattern;
    final spacing = cellSize * pattern.stride;
    final nextStride = pattern.stride * 2;
    final startX = (viewport.left / spacing).ceil() * spacing;
    final startY = (viewport.top / spacing).ceil() * spacing;
    final opaquePaint = Paint()..color = dotColor;
    final fadingPaint = Paint()
      ..color = dotColor.withValues(alpha: dotColor.a * pattern.fadingOpacity);
    for (var x = startX; x <= viewport.right; x += spacing) {
      final column = (x / cellSize).round();
      for (var y = startY; y <= viewport.bottom; y += spacing) {
        final row = (y / cellSize).round();
        final isRetained = column % nextStride == 0 && row % nextStride == 0;
        if (!isRetained && pattern.fadingOpacity <= 0) continue;
        context.canvas.drawCircle(
          offset + Offset(x, y),
          pattern.radius,
          isRetained ? opaquePaint : fadingPaint,
        );
      }
    }
  }

  _DotPattern get _dotPattern {
    const maximumDotsAcross = 32;
    final visibleGridIntervals =
        max(viewport.width, viewport.height) / graphLayout.data.cellSize;
    final level = max(0.0, log(visibleGridIntervals / maximumDotsAcross) / ln2);
    final completedLevels = level.floor();
    return _DotPattern(
      stride: 1 << completedLevels,
      fadingOpacity: 1 - (level - completedLevels),
      radius: (2 * pow(2, level)).toDouble(),
    );
  }

  void _paintEdges(PaintingContext context, Offset offset) {
    final paint = Paint()
      ..strokeWidth = min(graphLayout.data.cellSize / 10, 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final placed in visibleEdges) {
      context.canvas.drawLine(
        offset + placed.sourcePoint,
        offset + placed.targetPoint,
        paint..color = placed.edge.color,
      );
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestChildren(result, position: position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

class _DotPattern {
  const _DotPattern({
    required this.stride,
    required this.fadingOpacity,
    required this.radius,
  });

  final int stride;
  final double fadingOpacity;
  final double radius;
}
