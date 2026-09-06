import "package:typewriter_panel/typewriter_panel.dart";

import "services_packed_packer.dart";

class ServicesPackedLayout {
  const ServicesPackedLayout({this.gap = 1});

  final int gap;

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
