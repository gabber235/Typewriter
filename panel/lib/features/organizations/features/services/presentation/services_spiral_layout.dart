import "dart:collection";
import "dart:math";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class ServicesSpiralNode {
  const ServicesSpiralNode({
    required this.id,
    required this.width,
    required this.height,
    required this.builder,
    this.priority = 0,
  });

  final GraphIdentifier id;
  final int width;
  final int height;
  final int priority;
  final WidgetBuilder builder;
}

class ServicesSpiralConnection {
  const ServicesSpiralConnection({
    required this.id,
    required this.source,
    required this.target,
    required this.color,
  });

  final String id;
  final GraphIdentifier source;
  final GraphIdentifier target;
  final Color color;
}

class ServicesSpiralLayout {
  const ServicesSpiralLayout({this.gap = 1});

  final int gap;

  GraphData layout({
    required double cellSize,
    required List<ServicesSpiralNode> nodes,
    required List<ServicesSpiralConnection> connections,
  }) {
    assert(gap >= 0);
    final orderedNodes = nodes.toList()..sort(_compareNodes);
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
    final components =
        _components(orderedNodes, validConnections)
            .map((component) => _layoutComponent(component, validConnections))
            .toList()
          ..sort((left, right) => left.id.compareTo(right.id));
    final occupied = <Point<int>>{};
    final placements = <GraphIdentifier, _GridPlacement>{};

    for (final component in components) {
      final origin = _firstAvailable(
        width: component.width,
        height: component.height,
        occupied: occupied,
      );
      _occupy(
        origin: origin,
        width: component.width,
        height: component.height,
        occupied: occupied,
      );
      for (final entry in component.placements.entries) {
        placements[entry.key] = entry.value.translate(origin.x, origin.y);
      }
    }

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
        _edge(connection, elementsById),
    ];
    return GraphData(cellSize: cellSize, elements: elements, edges: edges);
  }

  List<List<ServicesSpiralNode>> _components(
    List<ServicesSpiralNode> nodes,
    List<ServicesSpiralConnection> connections,
  ) {
    final nodesById = {for (final node in nodes) node.id: node};
    final adjacency = <GraphIdentifier, Set<GraphIdentifier>>{
      for (final node in nodes) node.id: {},
    };
    for (final connection in connections) {
      adjacency[connection.source]!.add(connection.target);
      adjacency[connection.target]!.add(connection.source);
    }
    final unseen = nodesById.keys.toSet();
    final components = <List<ServicesSpiralNode>>[];
    while (unseen.isNotEmpty) {
      final start = unseen.reduce(_firstIdentifier);
      final queue = Queue<GraphIdentifier>()..add(start);
      final component = <ServicesSpiralNode>[];
      unseen.remove(start);
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        component.add(nodesById[current]!);
        final neighbors = adjacency[current]!.where(unseen.contains).toList()
          ..sort((left, right) => left.id.compareTo(right.id));
        for (final neighbor in neighbors) {
          unseen.remove(neighbor);
          queue.add(neighbor);
        }
      }
      components.add(component);
    }
    return components;
  }

  _ComponentPlacement _layoutComponent(
    List<ServicesSpiralNode> component,
    List<ServicesSpiralConnection> connections,
  ) {
    final ids = component.map((node) => node.id).toSet();
    final incoming = <GraphIdentifier, int>{for (final id in ids) id: 0};
    final outgoing = <GraphIdentifier, List<GraphIdentifier>>{};
    for (final connection in connections) {
      if (!ids.contains(connection.source) ||
          !ids.contains(connection.target)) {
        continue;
      }
      incoming[connection.target] = incoming[connection.target]! + 1;
      (outgoing[connection.source] ??= []).add(connection.target);
    }
    final roots = component.where((node) => incoming[node.id] == 0).toList()
      ..sort((left, right) => left.id.id.compareTo(right.id.id));
    final ordered = <ServicesSpiralNode>[];
    final queued = <GraphIdentifier>{};
    final byId = {for (final node in component) node.id: node};
    final queue = Queue<GraphIdentifier>();
    final orderedRoots = roots.isEmpty
        ? (component.toList()..sort(_compareNodes))
        : roots;
    for (final root in orderedRoots) {
      if (queued.add(root.id)) queue.add(root.id);
    }
    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      ordered.add(byId[current]!);
      final children = (outgoing[current] ?? const <GraphIdentifier>[]).toList()
        ..sort((left, right) => left.id.compareTo(right.id));
      for (final child in children) {
        if (queued.add(child)) queue.add(child);
      }
    }
    for (final node in [...component]..sort(_compareNodes)) {
      if (queued.add(node.id)) ordered.add(node);
    }

    final occupied = <Point<int>>{};
    final placements = <GraphIdentifier, _GridPlacement>{};
    for (final node in ordered) {
      final origin = _firstAvailable(
        width: node.width,
        height: node.height,
        occupied: occupied,
      );
      placements[node.id] = _GridPlacement(
        x: origin.x,
        y: origin.y,
        width: node.width,
        height: node.height,
      );
      _occupy(
        origin: origin,
        width: node.width,
        height: node.height,
        occupied: occupied,
      );
    }
    final minX = placements.values.map((placement) => placement.x).reduce(min);
    final minY = placements.values.map((placement) => placement.y).reduce(min);
    final normalized = {
      for (final entry in placements.entries)
        entry.key: entry.value.translate(-minX, -minY),
    };
    final width = normalized.values
        .map((placement) => placement.x + placement.width)
        .reduce(max);
    final height = normalized.values
        .map((placement) => placement.y + placement.height)
        .reduce(max);
    final id = normalized.keys
        .map((identifier) => identifier.id)
        .reduce((left, right) => left.compareTo(right) <= 0 ? left : right);
    return _ComponentPlacement(
      id: id,
      width: width,
      height: height,
      placements: normalized,
    );
  }

  Point<int> _firstAvailable({
    required int width,
    required int height,
    required Set<Point<int>> occupied,
  }) {
    for (final candidate in _spiral()) {
      if (_fits(
        origin: candidate,
        width: width,
        height: height,
        occupied: occupied,
      )) {
        return candidate;
      }
    }
    throw StateError("The services spiral did not produce a placement");
  }

  bool _fits({
    required Point<int> origin,
    required int width,
    required int height,
    required Set<Point<int>> occupied,
  }) {
    for (var x = origin.x - gap; x < origin.x + width + gap; x++) {
      for (var y = origin.y - gap; y < origin.y + height + gap; y++) {
        if (occupied.contains(Point(x, y))) return false;
      }
    }
    return true;
  }

  void _occupy({
    required Point<int> origin,
    required int width,
    required int height,
    required Set<Point<int>> occupied,
  }) {
    for (var x = origin.x; x < origin.x + width; x++) {
      for (var y = origin.y; y < origin.y + height; y++) {
        occupied.add(Point(x, y));
      }
    }
  }

  Iterable<Point<int>> _spiral() sync* {
    var x = 0;
    var y = 0;
    var length = 1;
    yield const Point(0, 0);
    while (true) {
      for (var step = 0; step < length; step++) {
        yield Point(++x, y);
      }
      for (var step = 0; step < length; step++) {
        yield Point(x, ++y);
      }
      length++;
      for (var step = 0; step < length; step++) {
        yield Point(--x, y);
      }
      for (var step = 0; step < length; step++) {
        yield Point(x, --y);
      }
      length++;
    }
  }

  GraphEdge _edge(
    ServicesSpiralConnection connection,
    Map<GraphIdentifier, GraphElement> elements,
  ) {
    final source = elements[connection.source]!;
    final target = elements[connection.target]!;
    final sourceCenter = Offset(
      source.x + source.width / 2,
      source.y + source.height / 2,
    );
    final targetCenter = Offset(
      target.x + target.width / 2,
      target.y + target.height / 2,
    );
    final delta = targetCenter - sourceCenter;
    final horizontal = delta.dx.abs() >= delta.dy.abs();
    final (sourceSide, targetSide) = horizontal
        ? delta.dx >= 0
              ? (EdgeSide.right, EdgeSide.left)
              : (EdgeSide.left, EdgeSide.right)
        : delta.dy >= 0
        ? (EdgeSide.bottom, EdgeSide.top)
        : (EdgeSide.top, EdgeSide.bottom);
    return GraphEdge(
      id: connection.id,
      source: connection.source,
      target: connection.target,
      color: connection.color,
      sourceSide: sourceSide,
      targetSide: targetSide,
    );
  }

  static GraphIdentifier _firstIdentifier(
    GraphIdentifier left,
    GraphIdentifier right,
  ) => left.id.compareTo(right.id) <= 0 ? left : right;

  static int _compareNodes(ServicesSpiralNode left, ServicesSpiralNode right) =>
      left.id.id.compareTo(right.id.id);
}

class _ComponentPlacement {
  const _ComponentPlacement({
    required this.id,
    required this.width,
    required this.height,
    required this.placements,
  });

  final String id;
  final int width;
  final int height;
  final Map<GraphIdentifier, _GridPlacement> placements;
}

class _GridPlacement {
  const _GridPlacement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  _GridPlacement translate(int dx, int dy) =>
      _GridPlacement(x: x + dx, y: y + dy, width: width, height: height);
}
