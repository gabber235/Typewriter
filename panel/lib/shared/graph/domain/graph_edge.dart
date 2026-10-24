import "package:typewriter_panel/typewriter_panel.dart";

part "graph_edge.freezed.dart";

/// Directed visual connection between two [GraphElement] identities.
///
/// The endpoints may be absent from the current [GraphData] snapshot. Layout
/// omits such edges until both endpoint placements exist.
@freezed
abstract class GraphEdge with _$GraphEdge {
  const factory GraphEdge({
    required String id,
    required GraphIdentifier source,
    required GraphIdentifier target,
    required Color color,
    @Default(EdgeSide.right) EdgeSide sourceSide,
    @Default(EdgeSide.left) EdgeSide targetSide,
  }) = _GraphEdge;

  const GraphEdge._();

  /// Whether [element] is either endpoint of this edge.
  bool connectsTo(GraphElement element) {
    return source == element.id || target == element.id;
  }
}
