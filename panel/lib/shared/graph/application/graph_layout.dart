import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "graph_layout.freezed.dart";

/// Transient geometry shown while a move or resize is still in progress.
///
/// It is derived from [GraphInteractionController] state and never mutates the
/// authoritative [GraphData] snapshot.
@freezed
abstract class GraphInteractionPreview with _$GraphInteractionPreview {
  const factory GraphInteractionPreview({
    @Default(<GraphIdentifier>{}) Set<GraphIdentifier> movingIds,
    @Default((0, 0)) (int, int) moveDelta,
    GraphResizePreview? resize,
  }) = _GraphInteractionPreview;
}

/// Transient dimensions for the element currently being resized.
@freezed
abstract class GraphResizePreview with _$GraphResizePreview {
  const factory GraphResizePreview({
    required GraphIdentifier id,
    required int width,
    required int height,
  }) = _GraphResizePreview;
}

/// A graph element with pixel bounds calculated from a snapshot and preview.
@freezed
abstract class GraphPlacedElement with _$GraphPlacedElement {
  const factory GraphPlacedElement({
    required GraphElement element,
    required Rect bounds,
  }) = _GraphPlacedElement;

  const GraphPlacedElement._();

  GraphIdentifier get id => element.id;
  Offset get position => bounds.topLeft;

  /// Whether this placement intersects the supplied scene viewport.
  bool isVisibleIn(Rect viewport) => bounds.overlaps(viewport);
}

/// An edge whose endpoints and connection points have been resolved by
/// [GraphLayoutResult].
@freezed
abstract class GraphPlacedEdge with _$GraphPlacedEdge {
  const factory GraphPlacedEdge({
    required GraphEdge edge,
    required GraphPlacedElement source,
    required GraphPlacedElement target,
    required Offset sourcePoint,
    required Offset targetPoint,
  }) = _GraphPlacedEdge;
}

/// Immutable placement result for one graph snapshot.
///
/// [paintOrder] sorts nodes by priority for rendering. Visibility culling is a
/// presentation optimization and never changes the underlying snapshot.
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

  /// Returns placements intersecting [viewport], plus retained identifiers.
  ///
  /// [overscan] expands the culling rectangle in scene pixels. Retained nodes
  /// stay mounted even when outside it, which preserves focus and interaction
  /// continuity during viewport changes.
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

  /// Resolves unique edges attached to [elementIds] for painting.
  ///
  /// Edges with an unresolved endpoint are omitted because no connection point
  /// can be calculated for them.
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
    final center = graphCenterOfMass(
      placementsById.values.map((placed) {
        final bounds = placed.bounds;
        return GraphGridRect(
          x: (bounds.left / data.cellSize).round(),
          y: (bounds.top / data.cellSize).round(),
          width: (bounds.width / data.cellSize).round(),
          height: (bounds.height / data.cellSize).round(),
        );
      }),
      cellSize: data.cellSize,
    );
    return center == null ? Offset.zero : center * data.cellSize;
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

/// Converts grid coordinates and transient interaction state into pixel
/// placements used by the graph render surface.
class GraphLayoutEngine {
  const GraphLayoutEngine();

  /// Builds a placement result without changing [data].
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
