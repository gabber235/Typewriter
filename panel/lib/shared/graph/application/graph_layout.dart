import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class GraphInteractionPreview {
  const GraphInteractionPreview({
    this.movingIds = const {},
    this.moveDelta = (0, 0),
    this.resize,
  });

  final Set<GraphIdentifier> movingIds;
  final (int, int) moveDelta;
  final GraphResizePreview? resize;
}

class GraphResizePreview {
  const GraphResizePreview({
    required this.id,
    required this.width,
    required this.height,
  });

  final GraphIdentifier id;
  final int width;
  final int height;
}

class GraphPlacedElement {
  const GraphPlacedElement({required this.element, required this.bounds});

  final GraphElement element;
  final Rect bounds;

  GraphIdentifier get id => element.id;
  Offset get position => bounds.topLeft;

  bool isVisibleIn(Rect viewport) => bounds.overlaps(viewport);
}

class GraphPlacedEdge {
  const GraphPlacedEdge({
    required this.edge,
    required this.source,
    required this.target,
    required this.sourcePoint,
    required this.targetPoint,
  });

  final GraphEdge edge;
  final GraphPlacedElement source;
  final GraphPlacedElement target;
  final Offset sourcePoint;
  final Offset targetPoint;
}

class GraphLayoutResult {
  GraphLayoutResult({
    required this.data,
    required Map<GraphIdentifier, GraphPlacedElement> placementsById,
  }) : placementsById = Map.unmodifiable(placementsById),
       paintOrder = List.unmodifiable(
         placementsById.values.sortedBy((placed) => placed.element),
       );

  final GraphData data;
  final Map<GraphIdentifier, GraphPlacedElement> placementsById;
  final List<GraphPlacedElement> paintOrder;

  Iterable<GraphPlacedElement> visibleElements(
    Rect viewport, {
    double overscan = 0,
    Set<String> retainedIds = const {},
  }) {
    assert(overscan >= 0);
    final cullingBounds = viewport.inflate(overscan);
    return paintOrder.where(
      (placed) =>
          retainedIds.contains(placed.id.id) ||
          placed.isVisibleIn(cullingBounds),
    );
  }

  List<GraphPlacedEdge> edgesFor(Iterable<GraphIdentifier> elementIds) {
    final edges = <String, GraphEdge>{};
    for (final id in elementIds) {
      for (final edge in data.elementsConnectedEdges[id] ?? const []) {
        edges[edge.id] = edge;
      }
    }

    return edges.values.map(_placeEdge).nonNulls.toList(growable: false);
  }

  GraphPlacedEdge? _placeEdge(GraphEdge edge) {
    final source = placementsById[edge.source];
    final target = placementsById[edge.target];
    if (source == null || target == null) return null;

    return GraphPlacedEdge(
      edge: edge,
      source: source,
      target: target,
      sourcePoint: _connectionPoint(source.bounds, edge.sourceSide),
      targetPoint: _connectionPoint(target.bounds, edge.targetSide),
    );
  }

  Offset get centerOfMass {
    if (placementsById.isEmpty) return Offset.zero;

    var totalMass = 0.0;
    var weightedX = 0.0;
    var weightedY = 0.0;
    for (final placed in placementsById.values) {
      final area = placed.bounds.width * placed.bounds.height;
      final mass = 1.0 + area * 0.001;
      totalMass += mass;
      weightedX += placed.bounds.center.dx * mass;
      weightedY += placed.bounds.center.dy * mass;
    }
    return Offset(weightedX / totalMass, weightedY / totalMass);
  }

  static Offset _connectionPoint(Rect bounds, EdgeSide side) {
    return switch (side) {
      EdgeSide.top => Offset(bounds.center.dx, bounds.top),
      EdgeSide.bottom => Offset(bounds.center.dx, bounds.bottom),
      EdgeSide.left => Offset(bounds.left, bounds.center.dy),
      EdgeSide.right => Offset(bounds.right, bounds.center.dy),
    };
  }
}

class GraphLayoutEngine {
  const GraphLayoutEngine();

  GraphLayoutResult build({
    required GraphData data,
    GraphInteractionPreview preview = const GraphInteractionPreview(),
  }) {
    final placements = <GraphIdentifier, GraphPlacedElement>{};
    final (moveX, moveY) = preview.moveDelta;

    for (final element in data.elements) {
      final isMoving = preview.movingIds.contains(element.id);
      final resize = preview.resize?.id == element.id ? preview.resize : null;
      final x = element.x + (isMoving ? moveX : 0);
      final y = element.y + (isMoving ? moveY : 0);
      final width = resize?.width ?? element.width;
      final height = resize?.height ?? element.height;
      placements[element.id] = GraphPlacedElement(
        element: element,
        bounds: Rect.fromLTWH(
          x * data.cellSize,
          y * data.cellSize,
          width * data.cellSize,
          height * data.cellSize,
        ),
      );
    }

    return GraphLayoutResult(data: data, placementsById: placements);
  }
}
