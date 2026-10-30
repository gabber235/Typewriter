import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const layout = ServicesPackedLayout();

  test("empty and single topologies are supported", () {
    final empty = layout.layout(cellSize: 40, nodes: [], connections: []);
    expect(empty.elements, isEmpty);

    final single = layout.layout(
      cellSize: 40,
      nodes: [packedNode("host", width: 5, height: 3)],
      connections: [],
    );
    expect(single.elements.single.width, 5);
    expect(single.elements.single.height, 3);
  });

  test("identical topology has deterministic placements", () {
    final nodes = [
      packedNode("realm", width: 3, height: 2),
      packedNode("host", width: 5, height: 4),
      packedNode("engine", width: 2, height: 5),
      packedNode("custom", width: 4, height: 4),
    ];
    final connections = [
      packedConnection("host.realm", "host", "realm"),
      packedConnection("host.engine", "host", "engine"),
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

    expect(
      {
        for (final element in first.elements)
          element.id.id: (element.x, element.y, element.width, element.height),
      },
      {
        for (final element in second.elements)
          element.id.id: (element.x, element.y, element.width, element.height),
      },
    );
    expect(first.edges, second.edges);
  });

  test("one child is centered directly below its host", () {
    final data = layout.layout(
      cellSize: 40,
      nodes: [packedNode("host"), packedNode("engine")],
      connections: [packedConnection("host.engine", "host", "engine")],
    );
    final elements = {
      for (final element in data.elements) element.id.id: element,
    };
    final host = elements["host"]!;
    final engine = elements["engine"]!;

    expect(engine.x * 2 + engine.width, host.x * 2 + host.width);
    expect(engine.y, host.y + host.height + 1);
    expect(data.edges.single.sourceSide, EdgeSide.bottom);
    expect(data.edges.single.targetSide, EdgeSide.top);
  });

  test("two children share a balanced row below their host", () {
    final data = layout.layout(
      cellSize: 40,
      nodes: [packedNode("host"), packedNode("engine"), packedNode("realm")],
      connections: [
        packedConnection("host.engine", "host", "engine"),
        packedConnection("host.realm", "host", "realm"),
      ],
    );
    final elements = {
      for (final element in data.elements) element.id.id: element,
    };
    final host = elements["host"]!;
    final engine = elements["engine"]!;
    final realm = elements["realm"]!;

    expect(engine.y, host.y + host.height + 1);
    expect(realm.y, engine.y);
    expect(
      (engine.x * 2 + engine.width) + (realm.x * 2 + realm.width),
      (host.x * 2 + host.width) * 2,
    );
  });

  test("disconnected components pack across both axes", () {
    final data = layout.layout(
      cellSize: 32,
      nodes: [
        for (var index = 0; index < 12; index++) packedNode("node.$index"),
      ],
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
        packedNode("node.$index", width: 2 + index % 5, height: 2 + index % 4),
    ];
    final connections = [
      packedConnection("host.engine", "node.0", "node.1"),
      packedConnection("host.realm", "node.0", "node.2"),
    ];
    final data = layout.layout(
      cellSize: 32,
      nodes: nodes,
      connections: connections,
    );

    bool overlapsWithGap(GraphElement left, GraphElement right) {
      const gap = 1;
      return left.x - gap < right.x + right.width &&
          left.x + left.width + gap > right.x &&
          left.y - gap < right.y + right.height &&
          left.y + left.height + gap > right.y;
    }

    for (var left = 0; left < data.elements.length; left++) {
      for (var right = left + 1; right < data.elements.length; right++) {
        expect(
          overlapsWithGap(data.elements[left], data.elements[right]),
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
      nodes: [packedNode("orphan"), packedNode("custom")],
      connections: [packedConnection("missing", "missing", "orphan")],
    );

    expect(data.elements.map((element) => element.id.id), {"orphan", "custom"});
    expect(data.edges, isEmpty);
  });
}
