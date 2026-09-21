import "dart:math" as math;

import "package:faker/faker.dart" hide Color;
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart" hide random;
import "package:typewriter_testkit/src/shared/testing/testing.dart";

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
    final parentIds = <skir.ResourceId>[];

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
        tagId: skir.ResourceId(value: "tag:${faker.guid.guid()}"),
        name: faker.lorem
            .words(random.integer(3, min: 1))
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
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomElement(),
    parentIds: const [],
    placement: GraphPlacement(
      x: random.integer(20),
      y: random.integer(10),
      width: random.integer(6, min: 2),
      height: random.integer(3, min: 1),
    ),
  );
}

class TagsMock extends CanonicalTags {
  TagsMock({required this.displayState, this.specificTags});

  final DisplayState displayState;
  final List<Tag>? specificTags;

  @override
  Future<List<Tag>> build() async {
    if (specificTags != null) {
      return specificTags!;
    }

    return displayState.generateBatch(generateTagBatch);
  }

  @override
  Future<TypedMutationResult> updateTag(Tag tag, {Tag? expected}) async {
    final tags = await future;
    final canonical = tag;
    state = AsyncData(
      tags
          .map((value) => value.tagId == tag.tagId ? canonical : value)
          .toList(),
    );
    return TypedMutationResult.success(
      revision: 1,
      value: canonical.inspectorValue,
    );
  }

  @override
  Future<void> deleteTag(skir.ResourceId tagId) async {
    final tags = await future;
    state = AsyncData(tags.where((t) => t.tagId != tagId).toList());
  }
}

List<Override> tagsProviderOverrides({
  DisplayState state = DisplayState.loading,
  List<Tag>? tags,
}) => [
  canonicalTagsProvider.overrideWith(
    () => TagsMock(displayState: state, specificTags: tags),
  ),
];
