import "dart:math" as math;

import "package:faker/faker.dart" hide Color;
import "package:flutter/material.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/mock_utils.dart";

part "tag_batch_layout.dart";

const _probNoParents = 0.2;
const _probOneParent = 0.85;
const _recentParentWindow = 5;

/// Generates a batch of tags with proper hierarchical layout using the
/// Sugiyama algorithm for DAG visualization.
List<Tag> generateTagBatch(int count) {
  if (count <= 0) return [];

  final rawTags = _generateRawTags(count);
  final layerMap = rawTags._calculateLayers();

  final maxLayer = layerMap.values.fold(0, math.max);
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
    final parentIds = <skir.RecordId>[];

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
        tagId: recordId("tag:${faker.guid.guid()}"),
        name: faker.lorem
            .words(random.integer(3, min: 1))
            .join(" ")
            .snakeCase(),
        color: safeColors.randomElement(),
        parentIds: parentIds,
        placement: const Placement(x: 0, y: 0, width: 0, height: 0),
      ),
    );
  }

  return tags;
}

/// Generates a random standalone tag with no parent relationships.
Tag generateRandomTag() {
  return Tag(
    tagId: recordId("tag:${faker.guid.guid()}"),
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomElement(),
    parentIds: const [],
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
    List<skir.RecordId> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    final tags = await future;

    final newTag = Tag(
      tagId: recordId("tag:${faker.guid.guid()}"),
      name: name,
      color: color ?? safeColors.randomElement(),
      parentIds: parentIds,
      placement: Placement(x: x, y: y, width: width, height: height),
    );

    state = AsyncData([...tags, newTag]);
    return newTag;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    final tags = await future;
    state = AsyncData(tags.map((t) => t.tagId == tag.tagId ? tag : t).toList());
  }

  @override
  Future<void> deleteTag(skir.RecordId tagId) async {
    final tags = await future;
    state = AsyncData(tags.where((t) => t.tagId != tagId).toList());
  }

  @override
  Future<void> moveTags(List<TagMovePayload> changes) async {
    final tags = await future;
    final changesById = {for (final change in changes) change.id: change};
    state = AsyncData(
      tags.map((tag) {
        final change = changesById[tag.tagId];
        if (change == null) return tag;
        return tag.copyWith(
          placement: tag.placement.copyWith(x: change.x, y: change.y),
        );
      }).toList(),
    );
  }

  @override
  Future<void> resizeTag(skir.RecordId tagId, int width, int height) async {
    final tags = await future;
    state = AsyncData(
      tags
          .map(
            (tag) => tag.tagId == tagId
                ? tag.copyWith(
                    placement: tag.placement.copyWith(
                      width: width,
                      height: height,
                    ),
                  )
                : tag,
          )
          .toList(),
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
