import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const layout = ServicesPackedLayout();

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

  test("one child is centered directly below its host", () {
    final data = layout.layout(
      cellSize: 40,
      nodes: [_node("host"), _node("engine")],
      connections: [_connection("host.engine", "host", "engine")],
    );
    final elements = _elementsById(data);
    final host = elements["host"]!;
    final engine = elements["engine"]!;

    expect(_centerX(engine), _centerX(host));
    expect(engine.y, host.y + host.height + 1);
    expect(data.edges.single.sourceSide, EdgeSide.bottom);
    expect(data.edges.single.targetSide, EdgeSide.top);
  });

  test("two children share a balanced row below their host", () {
    final data = layout.layout(
      cellSize: 40,
      nodes: [_node("host"), _node("engine"), _node("realm")],
      connections: [
        _connection("host.engine", "host", "engine"),
        _connection("host.realm", "host", "realm"),
      ],
    );
    final elements = _elementsById(data);
    final host = elements["host"]!;
    final engine = elements["engine"]!;
    final realm = elements["realm"]!;

    expect(engine.y, host.y + host.height + 1);
    expect(realm.y, engine.y);
    expect(_centerX(engine) + _centerX(realm), _centerX(host) * 2);
  });

  test("disconnected components pack across both axes", () {
    final data = layout.layout(
      cellSize: 32,
      nodes: [for (var index = 0; index < 12; index++) _node("node.$index")],
      connections: [],
    );
    final width = data.elements
        .map((element) => element.x + element.width)
        .reduce((left, right) => left > right ? left : right);
    final height = data.elements
        .map((element) => element.y + element.height)
        .reduce((left, right) => left > right ? left : right);

    expect(
      data.elements.map((element) => element.x).toSet().length,
      greaterThan(1),
    );
    expect(
      data.elements.map((element) => element.y).toSet().length,
      greaterThan(1),
    );
    expect((width - height).abs(), lessThanOrEqualTo(5));
  });

  test("variable nodes and packed components never overlap", () {
    final nodes = [
      for (var index = 0; index < 24; index++)
        _node("node.$index", width: 2 + index % 5, height: 2 + index % 4),
    ];
    final connections = [
      _connection("host.engine", "node.0", "node.1"),
      _connection("host.realm", "node.0", "node.2"),
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

ServicesPackedNode _node(String id, {int width = 4, int height = 4}) =>
    ServicesPackedNode(
      id: GraphIdentifier(id),
      width: width,
      height: height,
      builder: (_) => const SizedBox.shrink(),
    );

ServicesPackedConnection _connection(String id, String source, String target) =>
    ServicesPackedConnection(
      id: id,
      source: GraphIdentifier(source),
      target: GraphIdentifier(target),
      color: Colors.blue,
    );

Map<String, GraphElement> _elementsById(GraphData data) => {
  for (final element in data.elements) element.id.id: element,
};

Map<String, (int, int, int, int)> _placements(GraphData data) => {
  for (final element in data.elements)
    element.id.id: (element.x, element.y, element.width, element.height),
};

int _centerX(GraphElement element) => element.x * 2 + element.width;

bool _overlapsWithGap(GraphElement left, GraphElement right) {
  const gap = 1;
  return left.x - gap < right.x + right.width &&
      left.x + left.width + gap > right.x &&
      left.y - gap < right.y + right.height &&
      left.y + left.height + gap > right.y;
}
