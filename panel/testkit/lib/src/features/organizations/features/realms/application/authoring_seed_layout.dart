part of "authoring_seeds.dart";

const _tagWidth = 4;
const _tagHeight = 1;
const _horizontalSpacing = 2;
const _verticalSpacing = 2;

extension on List<Tag> {
  Map<skir.ResourceId, int> _calculateLayers() {
    final tagById = {for (final tag in this) tag.tagId: tag};
    final depthCache = <skir.ResourceId, int>{};

    int calculateDepth(
      skir.ResourceId tagId, [
      Set<skir.ResourceId>? visiting,
    ]) {
      visiting ??= {};

      if (visiting.contains(tagId)) return 0;
      if (depthCache.containsKey(tagId)) return depthCache[tagId]!;

      visiting.add(tagId);

      final tag = tagById[tagId];
      if (tag == null || tag.parentIds.isEmpty) {
        depthCache[tagId] = 0;
        visiting.remove(tagId);
        return 0;
      }

      var maxParentDepth = -1;
      for (final parentId in tag.parentIds) {
        if (tagById.containsKey(parentId)) {
          maxParentDepth = max(
            maxParentDepth,
            calculateDepth(parentId, visiting),
          );
        }
      }

      depthCache[tagId] = maxParentDepth == -1 ? 0 : maxParentDepth + 1;
      visiting.remove(tagId);
      return depthCache[tagId]!;
    }

    for (final tag in this) {
      calculateDepth(tag.tagId);
    }

    return depthCache;
  }
}

extension on List<List<Tag>> {
  List<List<Tag>> _orderedForMinimalCrossing() {
    if (isEmpty) return this;

    final positionInLayer = <skir.ResourceId, int>{};

    for (int index = 0; index < first.length; index++) {
      positionInLayer[first[index].tagId] = index;
    }

    final result = <List<Tag>>[first];

    for (int layerIndex = 1; layerIndex < length; layerIndex++) {
      final layer = this[layerIndex].toList();

      layer.sort((a, b) {
        final aBarycenter = a._calculateBarycenter(positionInLayer);
        final bBarycenter = b._calculateBarycenter(positionInLayer);
        return aBarycenter.compareTo(bBarycenter);
      });

      for (int index = 0; index < layer.length; index++) {
        positionInLayer[layer[index].tagId] = index;
      }

      result.add(layer);
    }

    return result;
  }

  List<Tag> _assignCoordinates() {
    final result = <Tag>[];

    for (int layerIndex = 0; layerIndex < length; layerIndex++) {
      final layer = this[layerIndex];
      final y = layerIndex * (_tagHeight + _verticalSpacing);

      for (
        int positionIndex = 0;
        positionIndex < layer.length;
        positionIndex++
      ) {
        final tag = layer[positionIndex];
        final x = positionIndex * (_tagWidth + _horizontalSpacing);

        result.add(
          tag.copyWith(
            placement: GraphPlacement(
              x: x,
              y: y,
              width: _tagWidth,
              height: _tagHeight,
            ),
          ),
        );
      }
    }

    return result;
  }
}

extension on Tag {
  double _calculateBarycenter(Map<skir.ResourceId, int> positionInLayer) {
    if (parentIds.isEmpty) return 0;

    var sum = 0;
    var count = 0;
    for (final parentId in parentIds) {
      if (positionInLayer.containsKey(parentId)) {
        sum += positionInLayer[parentId]!;
        count++;
      }
    }

    return count > 0 ? sum / count : 0;
  }
}

const _probNoParents = 0.2;
const _probOneParent = 0.85;
const _recentParentWindow = 5;

/// Generates a batch of tags with proper hierarchical layout using the
/// Sugiyama algorithm for DAG visualization.
List<Tag> generateTagBatch(int count) {
  if (count <= 0) return [];

  final rawTags = _generateRawTags(count);
  final layerMap = rawTags._calculateLayers();

  final maxLayer = layerMap.values.fold(0, max);
  final layers = List.generate(
    maxLayer + 1,
    (i) => rawTags.where((t) => layerMap[t.tagId] == i).toList(),
  );
  final orderedLayers = layers._orderedForMinimalCrossing();

  return orderedLayers._assignCoordinates();
}

List<Tag> _generateRawTags(int count) {
  final tags = <Tag>[];

  for (int i = 0; i < count; i++) {
    final parentIds = <skir.ResourceId>[];

    if (i > 0 && tags.isNotEmpty) {
      final prob = faker.randomGenerator.decimal();
      final parentCount = prob < _probNoParents
          ? 0
          : prob < _probOneParent
          ? 1
          : 2;

      final available = tags.toList();
      for (int p = 0; p < parentCount && available.isNotEmpty; p++) {
        final recentWindow = min(_recentParentWindow, available.length);
        final offset = faker.randomGenerator.integer(recentWindow, min: 0);
        final parentIndex = available.length - 1 - offset;
        final parent = available.removeAt(parentIndex);
        parentIds.add(parent.tagId);
      }
    }

    tags.add(
      Tag(
        tagId: skir.ResourceId(value: "tag:${faker.guid.guid()}"),
        name: faker.lorem
            .words(faker.randomGenerator.integer(3, min: 1))
            .join(" ")
            .snakeCase(),
        color: safeColors.randomElement(),
        parentIds: parentIds,
        placement: GraphPlacement(x: 0, y: 0, width: 0, height: 0),
      ),
    );
  }

  return tags;
}

/// Generates a random standalone tag with no parent relationships.
Tag generateRandomTag() {
  return Tag(
    tagId: skir.ResourceId(value: "tag:${faker.guid.guid()}"),
    name: faker.lorem
        .words(faker.randomGenerator.integer(4, min: 1))
        .join(" ")
        .snakeCase(),
    color: safeColors.randomElement(),
    parentIds: const [],
    placement: GraphPlacement(
      x: faker.randomGenerator.integer(20),
      y: faker.randomGenerator.integer(10),
      width: faker.randomGenerator.integer(6, min: 2),
      height: faker.randomGenerator.integer(3, min: 1),
    ),
  );
}
