import "dart:math" as math;
import "dart:math";

import "package:collection/collection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/entries.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/graph_direction.dart";

class Point<T> {
  final T x, y;
  const Point(this.x, this.y);
}

class GraphBounds {
  final int minX, minY, maxX, maxY;

  const GraphBounds(this.minX, this.minY, this.maxX, this.maxY);

  int get width => maxX - minX + 1;
  int get height => maxY - minY + 1;

  bool overlaps(GraphBounds other, int offsetX, int offsetY) {
    final myLeft = minX + offsetX;
    final myRight = maxX + offsetX;
    final myTop = minY + offsetY;
    final myBottom = maxY + offsetY;

    return !(myRight < other.minX ||
        myLeft > other.maxX ||
        myBottom < other.minY ||
        myTop > other.maxY);
  }

  bool overlapsWith(GraphBounds other) {
    return !(maxX < other.minX ||
        minX > other.maxX ||
        maxY < other.minY ||
        minY > other.maxY);
  }

  GraphBounds offset(int offsetX, int offsetY) {
    return GraphBounds(
      minX + offsetX,
      minY + offsetY,
      maxX + offsetX,
      maxY + offsetY,
    );
  }

  @override
  String toString() {
    return "GraphBounds(($minX, $minY), ($maxX, $maxY))";
  }
}

class LocalGraphLayout {
  final List<List<EntryDefinition>> layers;
  final GraphDirection direction;
  final GraphBounds bounds;

  const LocalGraphLayout(this.layers, this.direction, this.bounds);
}

List<int> generateGroupSizes(int totalEntries) {
  if (totalEntries <= 3) return [totalEntries];

  final random = math.Random();
  final numGroups = random.nextInt(3) + 2;
  final splitPoints = <int>[];

  for (int i = 0; i < numGroups - 1; i++) {
    splitPoints.add(random.nextInt(totalEntries - 1) + 1);
  }
  splitPoints.sort();

  final sizes = <int>[];
  int prev = 0;
  for (final point in splitPoints) {
    sizes.add(point - prev);
    prev = point;
  }
  sizes.add(totalEntries - prev);

  return sizes.where((size) => size > 0).toList();
}

List<List<EntryDefinition>> splitIntoGroups(
  List<EntryDefinition> entries,
  List<int> groupSizes,
) {
  final groups = <List<EntryDefinition>>[];
  int entryIndex = 0;

  for (final size in groupSizes) {
    groups.add(entries.sublist(entryIndex, entryIndex + size));
    entryIndex += size;
  }

  return groups;
}

List<List<EntryDefinition>> distributeIntoLayers(
  List<EntryDefinition> entries,
  int numLayers,
) {
  final layers = <List<EntryDefinition>>[];
  final random = math.Random();

  for (int i = 0; i < numLayers; i++) {
    layers.add(<EntryDefinition>[]);
  }

  for (final entry in entries) {
    final layerIndex = random.nextInt(numLayers);
    layers[layerIndex].add(entry);
  }

  return layers.where((layer) => layer.isNotEmpty).toList();
}

LocalGraphLayout layoutSingleGraph(
  List<EntryDefinition> groupEntries,
  GraphDirection direction,
) {
  const entryWidth = 3;
  const entryHeight = 1;
  const mainAxisSpacing = 2;
  const crossAxisSpacing = 1;

  final numLayers = math.max(2, math.min(20, (groupEntries.length / 2).ceil()));
  final layers = distributeIntoLayers(groupEntries, numLayers);
  final newLayers = <List<EntryDefinition>>[];

  final maxEntriesInALayer = layers
      .map((layer) => layer.length)
      .reduce(math.max);

  final maxLayerCross =
      maxEntriesInALayer *
          (direction.cross(entryWidth, entryHeight) + crossAxisSpacing) +
      crossAxisSpacing;

  var mainAxisPosition = switch (direction) {
    GraphDirection.leftToRight => 0,
    GraphDirection.rightToLeft => numLayers * (entryWidth + mainAxisSpacing),
    GraphDirection.topToBottom => 0,
    GraphDirection.bottomToTop => numLayers * (entryHeight + mainAxisSpacing),
  };

  for (int layerIndex = 0; layerIndex < layers.length; layerIndex++) {
    final layer = layers[layerIndex];

    final points = crossPoints(
      layer.length,
      direction.cross(entryWidth, entryHeight),
      maxLayerCross,
    );
    assert(
      points.length == layer.length,
      "The cross points should be the equal to the number of layers",
    );

    final newLayer = <EntryDefinition>[];

    for (int entryIndex = 0; entryIndex < layer.length; entryIndex++) {
      final main = mainAxisPosition;
      final cross = points[entryIndex];

      final positioned = layer[entryIndex].copyWith(
        placement: EntryPlacement(
          x: direction.main(main, cross),
          y: direction.cross(main, cross),
          width: entryWidth,
          height: entryHeight,
        ),
      );
      newLayer.add(positioned);
    }

    newLayers.add(newLayer);
    mainAxisPosition += entryWidth + mainAxisSpacing;
  }
  final positionedEntries = newLayers.expand((layer) => layer).toList();

  final minX = positionedEntries.map((e) => e.placement.x).reduce(min);
  final minY = positionedEntries.map((e) => e.placement.y).reduce(min);
  final maxX = positionedEntries
      .map((e) => e.placement.x + e.placement.width)
      .reduce(max);
  final maxY = positionedEntries
      .map((e) => e.placement.y + e.placement.height)
      .reduce(max);

  return LocalGraphLayout(
    newLayers,
    direction,
    GraphBounds(minX, minY, maxX, maxY),
  );
}

List<int> crossPoints(int count, int size, int maxTotalSize) {
  final emptySpace = maxTotalSize - count * size;
  final emptySpacePerPoint = emptySpace / (count + 1);
  final crossPoints = <int>[];

  for (int i = 0; i < count; i++) {
    crossPoints.add((emptySpacePerPoint * (i + 1) + size * i).round());
  }

  return crossPoints;
}

Point<int> findNonOverlappingPosition(
  GraphBounds newGraph,
  List<GraphBounds> existingGraphs,
  GraphDirection direction,
) {
  const padding = 3;

  if (existingGraphs.isEmpty) {
    return const Point(0, 0);
  }

  final maxCross = existingGraphs
      .map((g) => direction.cross(g.maxX, g.maxY))
      .reduce(max);

  final cross = maxCross + padding;

  return Point(direction.main(0, cross), direction.cross(0, cross));
}

List<ElementLink> generateEdgesForLayers(List<List<EntryDefinition>> layers) {
  final random = math.Random();
  final edges = <ElementLink>[];

  if (layers.length < 2) {
    return edges;
  }

  for (int layerIndex = 0; layerIndex < layers.length - 1; layerIndex++) {
    final currentLayer = layers[layerIndex];
    final nextLayer = layers[layerIndex + 1];

    if (currentLayer.isEmpty || nextLayer.isEmpty) continue;

    for (final entry in currentLayer) {
      final connectionsCount = random.nextInt(nextLayer.length) + 1;

      final targets = nextLayer
          .sorted((a, b) {
            final distanceA = entry.placement.distanceSquaredTo(a.placement);
            final distanceB = entry.placement.distanceSquaredTo(b.placement);
            return distanceA.compareTo(distanceB);
          })
          .sublist(0, connectionsCount);

      for (final target in targets) {
        final edge = ElementLink(
          linkId: "${entry.id}_${target.id}",
          otherId: target.id,
          path: "connections",
        );
        edges.add(edge);
      }
    }
  }

  return edges;
}

List<EntryDefinition> applyEdgesToEntries(
  List<EntryDefinition> entries,
  List<ElementLink> edges,
) {
  final entryIds = entries.map((e) => e.id).toSet();
  final validEdges = edges.where((edge) {
    final sourceId = edge.linkId.split("_").first;
    return entryIds.contains(sourceId) && entryIds.contains(edge.otherId);
  }).toList();

  final outwardEdgeMap = <String, List<ElementLink>>{};
  final inwardEdgeMap = <String, List<ElementLink>>{};

  for (final edge in validEdges) {
    final sourceId = edge.linkId.split("_").first;
    outwardEdgeMap.putIfAbsent(sourceId, () => []).add(edge);

    final inwardEdge = ElementLink(
      linkId: edge.linkId,
      otherId: sourceId,
      path: edge.path,
    );
    inwardEdgeMap.putIfAbsent(edge.otherId, () => []).add(inwardEdge);
  }

  return entries.map((entry) {
    return entry.copyWith(
      outwardEdges: outwardEdgeMap[entry.id] ?? [],
      inwardEdges: inwardEdgeMap[entry.id] ?? [],
    );
  }).toList();
}

List<EntryDefinition> generateDynamicGraphLayout(
  List<EntryDefinition> entries,
  GraphDirection? direction,
) {
  final random = math.Random();
  direction ??= GraphDirection.values[random.nextInt(4)];
  final groupSizes = generateGroupSizes(entries.length);
  final groups = splitIntoGroups(entries, groupSizes);

  final allEntries = <EntryDefinition>[];
  final placedGraphBounds = <GraphBounds>[];
  final allEdges = <ElementLink>[];

  for (final group in groups) {
    final localLayout = layoutSingleGraph(group, direction);

    final offset = findNonOverlappingPosition(
      localLayout.bounds,
      placedGraphBounds,
      direction,
    );

    final offsetLayers = localLayout.layers.map((layer) {
      return layer.map((entry) {
        return entry.copyWith(
          placement: entry.placement.copyWith(
            x: entry.placement.x + offset.x,
            y: entry.placement.y + offset.y,
          ),
        );
      }).toList();
    }).toList();

    final groupEdges = generateEdgesForLayers(offsetLayers);
    allEdges.addAll(groupEdges);
    allEntries.addAll(offsetLayers.expand((layer) => layer));

    placedGraphBounds.add(localLayout.bounds.offset(offset.x, offset.y));
  }

  return applyEdgesToEntries(allEntries, allEdges);
}
