import "dart:collection";
import "dart:math";

import "package:typewriter_panel/typewriter_panel.dart";

class ServicesPackedPacker {
  const ServicesPackedPacker({required this.gap});

  final int gap;

  List<ServicesPackedComponentPlacement> components(
    List<ServicesPackedNode> nodes,
    List<ServicesPackedConnection> connections,
  ) =>
      _components(
          nodes,
          connections,
        ).map((component) => _layoutComponent(component, connections)).toList()
        ..sort((left, right) => left.id.compareTo(right.id));

  Map<GraphIdentifier, ServicesPackedGridPlacement> pack(
    List<ServicesPackedComponentPlacement> components,
  ) {
    final packed = <_PackedComponent>[];
    final placements = <GraphIdentifier, ServicesPackedGridPlacement>{};
    for (final component in components) {
      final origin = _bestOrigin(component, packed);
      packed.add(
        _PackedComponent(
          x: origin.x,
          y: origin.y,
          width: component.width,
          height: component.height,
        ),
      );
      for (final entry in component.placements.entries) {
        placements[entry.key] = entry.value.translate(origin.x, origin.y);
      }
    }
    return placements;
  }

  List<List<ServicesPackedNode>> _components(
    List<ServicesPackedNode> nodes,
    List<ServicesPackedConnection> connections,
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
    final components = <List<ServicesPackedNode>>[];
    while (unseen.isNotEmpty) {
      final start = unseen.reduce(_firstIdentifier);
      final queue = Queue<GraphIdentifier>()..add(start);
      final component = <ServicesPackedNode>[];
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

  ServicesPackedComponentPlacement _layoutComponent(
    List<ServicesPackedNode> component,
    List<ServicesPackedConnection> connections,
  ) {
    final ranks = _ranks(component, connections);
    final rows = <int, List<ServicesPackedNode>>{};
    for (final node in component) {
      (rows[ranks[node.id]!] ??= []).add(node);
    }
    for (final row in rows.values) {
      row.sort(compareNodes);
    }
    final orderedRanks = rows.keys.toList()..sort();
    final naturalRowWidths = {
      for (final rank in orderedRanks) rank: _rowWidth(rows[rank]!),
    };
    var componentWidth = naturalRowWidths.values.reduce(max);
    final singleRows = orderedRanks
        .where((rank) => rows[rank]!.length == 1)
        .toList();
    if (singleRows.isNotEmpty &&
        componentWidth.isEven != naturalRowWidths[singleRows.first]!.isEven) {
      componentWidth++;
    }
    final placements = <GraphIdentifier, ServicesPackedGridPlacement>{};
    var y = 0;
    for (final rank in orderedRanks) {
      final row = rows[rank]!;
      final naturalWidth = naturalRowWidths[rank]!;
      final extraSpacing =
          row.length > 1 && naturalWidth.isEven != componentWidth.isEven
          ? 1
          : 0;
      final rowWidth = naturalWidth + extraSpacing;
      var x = (componentWidth - rowWidth) ~/ 2;
      final rowHeight = row.map((node) => node.height).reduce(max);
      for (var index = 0; index < row.length; index++) {
        final node = row[index];
        placements[node.id] = ServicesPackedGridPlacement(
          x: x,
          y: y,
          width: node.width,
          height: node.height,
        );
        x += node.width + gap;
        if (index == 0) x += extraSpacing;
      }
      y += rowHeight + gap;
    }
    final id = component
        .map((node) => node.id.id)
        .reduce((left, right) => left.compareTo(right) <= 0 ? left : right);
    return ServicesPackedComponentPlacement(
      id: id,
      width: componentWidth,
      height: y - gap,
      placements: placements,
    );
  }

  Map<GraphIdentifier, int> _ranks(
    List<ServicesPackedNode> component,
    List<ServicesPackedConnection> connections,
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
    for (final targets in outgoing.values) {
      targets.sort((left, right) => left.id.compareTo(right.id));
    }
    final queue =
        SplayTreeSet<GraphIdentifier>(
          (left, right) => left.id.compareTo(right.id),
        )..addAll(
          incoming.entries
              .where((entry) => entry.value == 0)
              .map((entry) => entry.key),
        );
    final ranks = <GraphIdentifier, int>{for (final id in queue) id: 0};
    while (queue.isNotEmpty) {
      final current = queue.first;
      queue.remove(current);
      for (final target in outgoing[current] ?? const []) {
        ranks[target] = max(ranks[target] ?? 0, ranks[current]! + 1);
        incoming[target] = incoming[target]! - 1;
        if (incoming[target] == 0) queue.add(target);
      }
    }
    final fallbackRank = ranks.values.isEmpty
        ? 0
        : ranks.values.reduce(max) + 1;
    for (final node in component.toList()..sort(compareNodes)) {
      ranks.putIfAbsent(node.id, () => fallbackRank);
    }
    return ranks;
  }

  int _rowWidth(List<ServicesPackedNode> row) =>
      row.fold(0, (width, node) => width + node.width) + gap * (row.length - 1);

  Point<int> _bestOrigin(
    ServicesPackedComponentPlacement component,
    List<_PackedComponent> packed,
  ) {
    if (packed.isEmpty) return const Point(0, 0);
    final xs = <int>{0};
    final ys = <int>{0};
    for (final placement in packed) {
      xs.add(placement.x + placement.width + gap);
      ys.add(placement.y + placement.height + gap);
    }
    Point<int>? best;
    _PlacementScore? bestScore;
    for (final y in ys.toList()..sort()) {
      for (final x in xs.toList()..sort()) {
        final candidate = _PackedComponent(
          x: x,
          y: y,
          width: component.width,
          height: component.height,
        );
        if (packed.any((other) => candidate.overlaps(other, gap))) continue;
        final score = _score(candidate, packed);
        if (bestScore == null || _compareScores(score, bestScore) < 0) {
          best = Point(x, y);
          bestScore = score;
        }
      }
    }
    return best!;
  }

  _PlacementScore _score(
    _PackedComponent candidate,
    List<_PackedComponent> packed,
  ) {
    final width = [
      candidate.x + candidate.width,
      for (final placement in packed) placement.x + placement.width,
    ].reduce(max);
    final height = [
      candidate.y + candidate.height,
      for (final placement in packed) placement.y + placement.height,
    ].reduce(max);
    return (
      longestSide: max(width, height),
      area: width * height,
      imbalance: (width - height).abs(),
      y: candidate.y,
      x: candidate.x,
    );
  }

  int _compareScores(_PlacementScore left, _PlacementScore right) {
    for (final comparison in [
      left.longestSide.compareTo(right.longestSide),
      left.area.compareTo(right.area),
      left.imbalance.compareTo(right.imbalance),
      left.y.compareTo(right.y),
      left.x.compareTo(right.x),
    ]) {
      if (comparison != 0) return comparison;
    }
    return 0;
  }

  GraphEdge edge(
    ServicesPackedConnection connection,
    Map<GraphIdentifier, GraphElement> elements,
  ) => GraphEdge(
    id: connection.id,
    source: connection.source,
    target: connection.target,
    color: connection.color,
    sourceSide: EdgeSide.bottom,
    targetSide: EdgeSide.top,
  );

  static GraphIdentifier _firstIdentifier(
    GraphIdentifier left,
    GraphIdentifier right,
  ) => left.id.compareTo(right.id) <= 0 ? left : right;

  static int compareNodes(ServicesPackedNode left, ServicesPackedNode right) =>
      left.id.id.compareTo(right.id.id);
}

class _PackedComponent {
  const _PackedComponent({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  bool overlaps(_PackedComponent other, int gap) =>
      x - gap < other.x + other.width &&
      x + width + gap > other.x &&
      y - gap < other.y + other.height &&
      y + height + gap > other.y;
}

typedef _PlacementScore = ({
  int longestSide,
  int area,
  int imbalance,
  int y,
  int x,
});
