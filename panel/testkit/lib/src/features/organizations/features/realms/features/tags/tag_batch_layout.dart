part of "tags.dart";

const _tagWidth = 4;
const _tagHeight = 1;
const _horizontalSpacing = 2;
const _verticalSpacing = 2;

extension on List<Tag> {
  Map<skir.RecordId, int> _calculateLayers() {
    final tagById = {for (final tag in this) tag.tagId: tag};
    final depthCache = <skir.RecordId, int>{};

    int calculateDepth(skir.RecordId tagId, [Set<skir.RecordId>? visiting]) {
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
          maxParentDepth = math.max(
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

    final positionInLayer = <skir.RecordId, int>{};

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
            placement: Placement(
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
  double _calculateBarycenter(Map<skir.RecordId, int> positionInLayer) {
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
