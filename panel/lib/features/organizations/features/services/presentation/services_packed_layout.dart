import "package:typewriter_panel/typewriter_panel.dart";


/// Adapts service topology nodes and relationships to [GraphData].
///
/// This boundary copies and sorts caller collections, drops relationships whose
/// endpoints are absent, and delegates deterministic placement to
/// [ServicesPackedPacker]. The returned graph contains every valid node and only
/// drawable edges, allowing partial live topology snapshots to render safely.
class ServicesPackedLayout {
  const ServicesPackedLayout({this.gap = 1});

  /// Number of grid cells kept between adjacent rectangles.
  final int gap;

  /// Builds the immutable graph snapshot consumed by the shared graph widgets.
  ///
  /// [cellSize] is forwarded unchanged as logical pixels per grid cell. Nodes
  /// retain their supplied builders and priorities; only their positions and
  /// valid edge endpoints are resolved here.
  GraphData layout({
    required double cellSize,
    required List<ServicesPackedNode> nodes,
    required List<ServicesPackedConnection> connections,
  }) {
    assert(gap >= 0);
    final packer = ServicesPackedPacker(gap: gap);
    final orderedNodes = nodes.toList()
      ..sort(ServicesPackedPacker.compareNodes);
    final nodesById = {for (final node in orderedNodes) node.id: node};
    final validConnections =
        connections
            .where(
              (connection) =>
                  nodesById.containsKey(connection.source) &&
                  nodesById.containsKey(connection.target),
            )
            .toList()
          ..sort((left, right) => left.id.compareTo(right.id));
    final placements = packer.pack(
      packer.components(orderedNodes, validConnections),
    );

    final elements = [
      for (final node in orderedNodes)
        GraphElement(
          id: node.id,
          x: placements[node.id]!.x,
          y: placements[node.id]!.y,
          width: node.width,
          height: node.height,
          priority: node.priority,
          builder: node.builder,
        ),
    ];
    final elementsById = {for (final element in elements) element.id: element};
    final edges = [
      for (final connection in validConnections)
        packer.edge(connection, elementsById),
    ];
    return GraphData(cellSize: cellSize, elements: elements, edges: edges);
  }
}
