import "dart:math" as math;
import "dart:math";

import "package:typewriter_panel/logic/pages/graph_direction.dart";

export "package:typewriter_panel/logic/pages/graph_direction.dart";

// ============ DATA TYPES ============

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

/// Result of placing an item in the graph
class PlacementResult {
  final int x, y, width, height;
  const PlacementResult(this.x, this.y, this.width, this.height);

  PlacementResult offset(int offsetX, int offsetY) =>
      PlacementResult(x + offsetX, y + offsetY, width, height);
}

/// Result of laying out a single group
class GroupLayout<T> {
  final List<List<T>> layers;
  final Map<String, PlacementResult> placements;
  final GraphBounds bounds;

  const GroupLayout(this.layers, this.placements, this.bounds);
}

// ============ UTILITY FUNCTIONS ============

/// Generates random group sizes for splitting items
List<int> generateGroupSizes(int totalItems) {
  if (totalItems <= 3) return [totalItems];

  final random = math.Random();
  final numGroups = random.nextInt(3) + 2;
  final splitPoints = <int>[];

  for (int i = 0; i < numGroups - 1; i++) {
    splitPoints.add(random.nextInt(totalItems - 1) + 1);
  }
  splitPoints.sort();

  final sizes = <int>[];
  int prev = 0;
  for (final point in splitPoints) {
    sizes.add(point - prev);
    prev = point;
  }
  sizes.add(totalItems - prev);

  return sizes.where((size) => size > 0).toList();
}

/// Splits items into groups based on sizes
List<List<T>> splitIntoGroups<T>(List<T> items, List<int> groupSizes) {
  final groups = <List<T>>[];
  int index = 0;

  for (final size in groupSizes) {
    groups.add(items.sublist(index, index + size));
    index += size;
  }

  return groups;
}

/// Distributes items randomly into layers
List<List<T>> distributeIntoLayers<T>(List<T> items, int numLayers) {
  final layers = List.generate(numLayers, (_) => <T>[]);
  final random = math.Random();

  for (final item in items) {
    layers[random.nextInt(numLayers)].add(item);
  }

  return layers.where((layer) => layer.isNotEmpty).toList();
}

/// Calculates evenly spaced cross-axis positions
List<int> crossPoints(int count, int size, int maxTotalSize) {
  final emptySpace = maxTotalSize - count * size;
  final emptySpacePerPoint = emptySpace / (count + 1);
  final points = <int>[];

  for (int i = 0; i < count; i++) {
    points.add((emptySpacePerPoint * (i + 1) + size * i).round());
  }

  return points;
}

/// Finds non-overlapping position for a new group
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

// ============ CORE LAYOUT FUNCTIONS ============

/// Lays out items within layers, returns placement map
Map<String, PlacementResult> layoutLayers<T>({
  required List<List<T>> layers,
  required String Function(T) getId,
  required GraphDirection direction,
  int itemWidth = 3,
  int itemHeight = 1,
  int mainAxisSpacing = 2,
  int crossAxisSpacing = 1,
}) {
  final placements = <String, PlacementResult>{};
  if (layers.isEmpty) return placements;

  final maxEntriesInALayer = layers.map((l) => l.length).reduce(max);
  final maxLayerCross =
      maxEntriesInALayer *
          (direction.cross(itemWidth, itemHeight) + crossAxisSpacing) +
      crossAxisSpacing;

  var mainPos = switch (direction) {
    GraphDirection.leftToRight => 0,
    GraphDirection.rightToLeft => layers.length * (itemWidth + mainAxisSpacing),
    GraphDirection.topToBottom => 0,
    GraphDirection.bottomToTop =>
      layers.length * (itemHeight + mainAxisSpacing),
  };

  for (final layer in layers) {
    if (layer.isEmpty) continue;

    final points = crossPoints(
      layer.length,
      direction.cross(itemWidth, itemHeight),
      maxLayerCross,
    );

    for (int i = 0; i < layer.length; i++) {
      final main = mainPos;
      final cross = points[i];

      placements[getId(layer[i])] = PlacementResult(
        direction.main(main, cross),
        direction.cross(main, cross),
        itemWidth,
        itemHeight,
      );
    }

    mainPos += direction.main(itemWidth, itemHeight) + mainAxisSpacing;
  }

  return placements;
}

/// Calculates bounds from placements
GraphBounds boundsFromPlacements(Map<String, PlacementResult> placements) {
  if (placements.isEmpty) return const GraphBounds(0, 0, 0, 0);

  final values = placements.values.toList();
  return GraphBounds(
    values.map((p) => p.x).reduce(min),
    values.map((p) => p.y).reduce(min),
    values.map((p) => p.x + p.width).reduce(max),
    values.map((p) => p.y + p.height).reduce(max),
  );
}

/// Layouts a single group of items
GroupLayout<T> layoutSingleGroup<T>({
  required List<T> items,
  required String Function(T) getId,
  required GraphDirection direction,
  required List<List<T>> Function(List<T> items) organizeIntoLayers,
  int itemWidth = 3,
  int itemHeight = 1,
  int mainAxisSpacing = 2,
  int crossAxisSpacing = 1,
}) {
  final layers = organizeIntoLayers(items);

  final placements = layoutLayers(
    layers: layers,
    getId: getId,
    direction: direction,
    itemWidth: itemWidth,
    itemHeight: itemHeight,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
  );

  return GroupLayout(layers, placements, boundsFromPlacements(placements));
}

/// Main layout function: splits into groups, layouts each, positions without overlap
/// Returns a map of item ID to PlacementResult
///
/// [groupBy] allows custom grouping logic. If provided, it should return a list
/// of groups where items within the same group should stay together visually.
/// If not provided, items are split into random groups by position.
Map<String, PlacementResult> generateDynamicLayout<T>({
  required List<T> items,
  required String Function(T) getId,
  required List<List<T>> Function(List<T> items) organizeIntoLayers,
  List<List<T>> Function(List<T> items)? groupBy,
  GraphDirection? direction,
  int itemWidth = 3,
  int itemHeight = 1,
  int mainAxisSpacing = 2,
  int crossAxisSpacing = 1,
}) {
  if (items.isEmpty) return {};

  final random = math.Random();
  direction ??= GraphDirection.values[random.nextInt(4)];

  final List<List<T>> groups;
  if (groupBy != null) {
    groups = groupBy(items);
  } else {
    final groupSizes = generateGroupSizes(items.length);
    groups = splitIntoGroups(items, groupSizes);
  }

  final allPlacements = <String, PlacementResult>{};
  final placedBounds = <GraphBounds>[];

  for (final group in groups) {
    final layout = layoutSingleGroup(
      items: group,
      getId: getId,
      direction: direction,
      organizeIntoLayers: organizeIntoLayers,
      itemWidth: itemWidth,
      itemHeight: itemHeight,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
    );

    final offset = findNonOverlappingPosition(
      layout.bounds,
      placedBounds,
      direction,
    );

    // Apply offset to placements
    for (final entry in layout.placements.entries) {
      allPlacements[entry.key] = entry.value.offset(offset.x, offset.y);
    }

    placedBounds.add(layout.bounds.offset(offset.x, offset.y));
  }

  return allPlacements;
}
