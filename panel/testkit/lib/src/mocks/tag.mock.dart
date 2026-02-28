import "dart:math" as math;

import "package:faker/faker.dart" hide Color;
import "package:flutter_animate/flutter_animate.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _tagWidth = 4;
const _tagHeight = 1;
const _horizontalSpacing = 2;
const _verticalSpacing = 2;

const _probNoParents = 0.2;
const _probOneParent = 0.85;
const _recentParentWindow = 5;

/// Generates a batch of tags with proper hierarchical layout using the
/// Sugiyama algorithm for DAG visualization.
List<Tag> generateTagBatch(int count) {
  if (count <= 0) return [];

  final rawTags = _generateRawTags(count);
  final layerMap = _calculateLayers(rawTags);

  final maxLayer = layerMap.values.fold(0, math.max);
  final layers = List.generate(
    maxLayer + 1,
    (i) => rawTags.where((t) => layerMap[t.tagId] == i).toList(),
  );
  final orderedLayers = _orderLayersForMinimalCrossing(layers);

  return _assignCoordinates(orderedLayers);
}

List<Tag> _generateRawTags(int count) {
  final tags = <Tag>[];

  for (int i = 0; i < count; i++) {
    final parentIds = <String>[];

    if (i > 0 && tags.isNotEmpty) {
      final prob = random.decimal();
      final parentCount = prob < _probNoParents
          ? 0
          : prob < _probOneParent
          ? 1
          : 2;

      final available = tags.toList();
      for (int p = 0; p < parentCount && available.isNotEmpty; p++) {
        final recentWindow = math.min(_recentParentWindow, available.length);
        final offset = random.integer(recentWindow, min: 0);
        final parentIndex = available.length - 1 - offset;
        final parent = available.removeAt(parentIndex);
        parentIds.add(parent.tagId);
      }
    }

    tags.add(
      Tag(
        tagId: faker.guid.guid(),
        name: faker.lorem
            .words(random.integer(3, min: 1))
            .join(" ")
            .snakeCase(),
        color: safeColors.randomElement().toProtoColor(),
        parentIds: parentIds,
      ),
    );
  }

  return tags;
}

Map<String, int> _calculateLayers(List<Tag> tags) {
  final tagById = {for (final t in tags) t.tagId: t};
  final depthCache = <String, int>{};

  int calculateDepth(String tagId, [Set<String>? visiting]) {
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

  for (final tag in tags) {
    calculateDepth(tag.tagId);
  }

  return depthCache;
}

List<List<Tag>> _orderLayersForMinimalCrossing(List<List<Tag>> layers) {
  if (layers.isEmpty) return layers;

  final positionInLayer = <String, int>{};

  for (int i = 0; i < layers.first.length; i++) {
    positionInLayer[layers.first[i].tagId] = i;
  }

  final result = <List<Tag>>[layers.first];

  for (int layerIdx = 1; layerIdx < layers.length; layerIdx++) {
    final layer = layers[layerIdx].toList();

    layer.sort((a, b) {
      final aBarycenter = _calculateBarycenter(a, positionInLayer);
      final bBarycenter = _calculateBarycenter(b, positionInLayer);
      return aBarycenter.compareTo(bBarycenter);
    });

    for (int i = 0; i < layer.length; i++) {
      positionInLayer[layer[i].tagId] = i;
    }

    result.add(layer);
  }

  return result;
}

double _calculateBarycenter(Tag tag, Map<String, int> positionInLayer) {
  if (tag.parentIds.isEmpty) return 0;

  var sum = 0;
  var count = 0;
  for (final parentId in tag.parentIds) {
    if (positionInLayer.containsKey(parentId)) {
      sum += positionInLayer[parentId]!;
      count++;
    }
  }

  return count > 0 ? sum / count : 0;
}

List<Tag> _assignCoordinates(List<List<Tag>> orderedLayers) {
  final result = <Tag>[];

  for (int layerIdx = 0; layerIdx < orderedLayers.length; layerIdx++) {
    final layer = orderedLayers[layerIdx];
    final y = layerIdx * (_tagHeight + _verticalSpacing);

    for (int posIdx = 0; posIdx < layer.length; posIdx++) {
      final tag = layer[posIdx];
      final x = posIdx * (_tagWidth + _horizontalSpacing);

      result.add(
        tag.deepCopy()
          ..placement = Placement(
            x: x,
            y: y,
            width: _tagWidth,
            height: _tagHeight,
          ),
      );
    }
  }

  return result;
}

/// Generates a random standalone tag with no parent relationships.
Tag generateRandomTag() {
  return Tag(
    tagId: faker.guid.guid(),
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomElement().toProtoColor(),
    placement: Placement(
      x: random.integer(20),
      y: random.integer(10),
      width: random.integer(6, min: 2),
      height: random.integer(3, min: 1),
    ),
  );
}

class TagsMock extends Tags {
  TagsMock({required this.displayState, this.specificTags});

  final DisplayState displayState;
  final List<Tag>? specificTags;

  @override
  Stream<List<Tag>> build() async* {
    if (specificTags != null) {
      yield specificTags!;
      return;
    }

    final tags = await displayState.generateBatch(generateTagBatch);
    yield tags;
  }

  @override
  Future<Tag> createTag({
    required String name,
    Color? color,
    List<String> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    await Future.delayed(500.ms);
    final tags = await future;

    final newTag = Tag(
      tagId: faker.guid.guid(),
      name: name,
      color: color ?? safeColors.randomElement().toProtoColor(),
      parentIds: parentIds,
      placement: Placement(x: x, y: y, width: width, height: height),
    );

    state = AsyncData([...tags, newTag]);
    return newTag;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await Future.delayed(500.ms);
    final tags = await future;
    state = AsyncData(tags.map((t) => t.tagId == tag.tagId ? tag : t).toList());
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await Future.delayed(500.ms);
    final tags = await future;
    state = AsyncData(tags.where((t) => t.tagId != tagId).toList());
  }

  @override
  Future<void> moveTag(String tagId, int x, int y) async {
    final tags = await future;
    state = AsyncData(
      tags.map((t) {
        if (t.tagId != tagId) return t;
        return t.deepCopy()
          ..placement = Placement(
            x: x,
            y: y,
            width: t.placement.width,
            height: t.placement.height,
          );
      }).toList(),
    );
  }

  @override
  Future<void> resizeTag(String tagId, int width, int height) async {
    final tags = await future;
    state = AsyncData(
      tags.map((t) {
        if (t.tagId != tagId) return t;
        return t.deepCopy()
          ..placement = Placement(
            x: t.placement.x,
            y: t.placement.y,
            width: width,
            height: height,
          );
      }).toList(),
    );
  }
}

List<Override> tagsProviderOverrides({
  DisplayState state = DisplayState.loading,
  List<Tag>? tags,
}) => [
  tagsProvider.overrideWith(
    () => TagsMock(displayState: state, specificTags: tags),
  ),
];
