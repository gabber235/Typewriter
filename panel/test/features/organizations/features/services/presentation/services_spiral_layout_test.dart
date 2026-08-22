import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const layout = ServicesSpiralLayout();

  test("empty and single topologies are supported", () {
    final empty = layout.layout(cellSize: 40, nodes: [], connections: []);
    expect(empty.elements, isEmpty);

    final single = layout.layout(
      cellSize: 40,
      nodes: [_node("host", width: 5, height: 3)],
      connections: [],
    );
    expect(single.elements.single.width, 5);
    expect(single.elements.single.height, 3);
  });

  test("identical topology has deterministic placements", () {
    final nodes = [
      _node("realm", width: 3, height: 2),
      _node("host", width: 5, height: 4),
      _node("engine", width: 2, height: 5),
      _node("custom", width: 4, height: 4),
    ];
    final connections = [
      _connection("host.realm", "host", "realm"),
      _connection("host.engine", "host", "engine"),
    ];

    final first = layout.layout(
      cellSize: 40,
      nodes: nodes,
      connections: connections,
    );
    final second = layout.layout(
      cellSize: 40,
      nodes: nodes.reversed.toList(),
      connections: connections.reversed.toList(),
    );

    expect(_placements(first), _placements(second));
    expect(first.edges, second.edges);
  });

  test("variable nodes and packed components never overlap", () {
    final nodes = [
      for (var index = 0; index < 24; index++)
        _node("node.$index", width: 2 + index % 5, height: 2 + index % 4),
    ];
    final connections = [
      for (var index = 1; index < 12; index++)
        _connection("edge.$index", "node.0", "node.$index"),
    ];

    final data = layout.layout(
      cellSize: 32,
      nodes: nodes,
      connections: connections,
    );

    for (var left = 0; left < data.elements.length; left++) {
      for (var right = left + 1; right < data.elements.length; right++) {
        expect(
          _overlapsWithGap(data.elements[left], data.elements[right]),
          isFalse,
          reason:
              "${data.elements[left].id} overlaps ${data.elements[right].id}",
        );
      }
    }
    final xs = data.elements.map((element) => element.x).toSet();
    final ys = data.elements.map((element) => element.y).toSet();
    expect(xs.length, greaterThan(2));
    expect(ys.length, greaterThan(2));
  });

  test("dangling relationships stay absent while orphan nodes remain", () {
    final data = layout.layout(
      cellSize: 40,
      nodes: [_node("orphan"), _node("custom")],
      connections: [_connection("missing", "missing", "orphan")],
    );

    expect(data.elements.map((element) => element.id.id), {"orphan", "custom"});
    expect(data.edges, isEmpty);
  });
}

ServicesSpiralNode _node(String id, {int width = 4, int height = 4}) =>
    ServicesSpiralNode(
      id: GraphIdentifier(id),
      width: width,
      height: height,
      builder: (_) => const SizedBox.shrink(),
    );

ServicesSpiralConnection _connection(String id, String source, String target) =>
    ServicesSpiralConnection(
      id: id,
      source: GraphIdentifier(source),
      target: GraphIdentifier(target),
      color: Colors.blue,
    );

Map<String, (int, int, int, int)> _placements(GraphData data) => {
  for (final element in data.elements)
    element.id.id: (element.x, element.y, element.width, element.height),
};

bool _overlapsWithGap(GraphElement left, GraphElement right) {
  const gap = 1;
  return left.x - gap < right.x + right.width &&
      left.x + left.width + gap > right.x &&
      left.y - gap < right.y + right.height &&
      left.y + left.height + gap > right.y;
}
