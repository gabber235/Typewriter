import "dart:math" as math;

import "package:faker/faker.dart" hide Color;
// ignore: depend_on_referenced_packages, implementation_imports
import "package:riverpod/src/framework.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/generated/models/common.pb.dart";
import "package:typewriter_panel/logic/pages/graph_direction.dart";
import "package:typewriter_panel/logic/proto/extensions.dart";
import "package:typewriter_panel/logic/tags/tags.dart";
import "package:typewriter_panel/utils/collection.dart";
import "package:typewriter_panel/utils/color.dart";
import "package:typewriter_panel/utils/number.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_testkit/src/mocks/graph_layout.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

// ============ TAG GENERATION ============

const _targetTagsPerSubgraph = 10;
const _minSubgraphCount = 3;
const _maxSubgraphCount = 8;
const _probNoParents = 0.2;
const _probOneParent = 0.85;
const _recentParentWindow = 5;

/// Generates a list of tags distributed across multiple separate subgraphs.
/// Each subgraph is completely independent with no edges connecting them.
List<Tag> generateTagBatch(int count) {
  if (count <= 0) return [];

  if (count <= 3) return _generateSubgraph(count);

  final subgraphCount = (count / _targetTagsPerSubgraph).ceil().clamp(
    _minSubgraphCount,
    _maxSubgraphCount,
  );
  final tagsPerSubgraph = count ~/ subgraphCount;
  final remainder = count % subgraphCount;

  final allTags = <Tag>[];

  for (var g = 0; g < subgraphCount; g++) {
    final subgraphSize = tagsPerSubgraph + (g < remainder ? 1 : 0);
    final subgraphTags = _generateSubgraph(subgraphSize);
    allTags.addAll(subgraphTags);
  }

  return allTags;
}

/// Generates a single subgraph with the specified number of tags.
/// Parent selection is limited to tags within this subgraph only.
/// Parent distribution: 20% roots, 65% single parent, 15% dual parents.
/// Max 2 parents keeps graph structure manageable for visualization.
List<Tag> _generateSubgraph(int count) {
  if (count <= 0) return [];
  final tags = <Tag>[];

  for (int i = 0; i < count; i++) {
    final parentRefs = <Tag>[];

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
        parentRefs.add(Tag(id: parent.id));
      }
    }

    tags.add(
      Tag(
        id: faker.guid.guid(),
        name: faker.lorem
            .words(random.integer(3, min: 1))
            .join(" ")
            .snakeCase(),
        color: safeColors.randomElement().toProtoColor(),
        parents: parentRefs,
      ),
    );
  }

  return tags;
}

// ============ TAG LAYOUT ============

/// Groups tags by connected components (parent-child relationships).
/// Tags that are connected via parent-child edges stay in the same group.
List<List<Tag>> groupTagsByConnectedComponents(List<Tag> tags) {
  if (tags.isEmpty) return [];

  final tagMap = {for (final t in tags) t.id: t};
  final adjacency = <String, Set<String>>{};

  for (final tag in tags) {
    adjacency.putIfAbsent(tag.id, () => {});
    for (final parent in tag.parents) {
      if (tagMap.containsKey(parent.id)) {
        adjacency[tag.id]!.add(parent.id);
        adjacency.putIfAbsent(parent.id, () => {}).add(tag.id);
      }
    }
  }

  final visited = <String>{};
  final components = <List<Tag>>[];

  for (final tag in tags) {
    if (visited.contains(tag.id)) continue;

    final component = <Tag>[];
    final queue = [tag.id];

    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (visited.contains(id)) continue;
      visited.add(id);

      if (tagMap.containsKey(id)) component.add(tagMap[id]!);
      queue.addAll(adjacency[id]?.where((x) => !visited.contains(x)) ?? []);
    }

    if (component.isNotEmpty) components.add(component);
  }

  return components;
}

/// Organizes tags into layers by depth level
/// Layer 0 = root tags (no parents), Layer 1 = their children, etc.
List<List<Tag>> organizeTagsByDepth(List<Tag> tags) {
  if (tags.isEmpty) return [];

  final tagById = {for (final t in tags) t.id: t};
  final depthCache = <String, int>{};

  int calculateDepth(String tagId, [Set<String>? visiting]) {
    visiting ??= {};

    if (visiting.contains(tagId)) {
      return 0;
    }

    if (depthCache.containsKey(tagId)) return depthCache[tagId]!;

    visiting.add(tagId);

    final tag = tagById[tagId];
    if (tag == null || tag.parents.isEmpty) {
      depthCache[tagId] = 0;
      visiting.remove(tagId);
      return 0;
    }

    var maxParentDepth = -1;
    for (final parent in tag.parents) {
      if (tagById.containsKey(parent.id)) {
        maxParentDepth = math.max(
          maxParentDepth,
          calculateDepth(parent.id, visiting),
        );
      }
    }

    depthCache[tagId] = maxParentDepth == -1 ? 0 : maxParentDepth + 1;
    visiting.remove(tagId);
    return depthCache[tagId]!;
  }

  for (final tag in tags) {
    calculateDepth(tag.id);
  }

  final maxDepth = depthCache.values.fold(0, math.max);
  return List.generate(
    maxDepth + 1,
    (level) => tags.where((t) => depthCache[t.id] == level).toList(),
  ).where((layer) => layer.isNotEmpty).toList();
}

/// Apply layout using generic graph layout functions
List<Tag> applyTagLayout(List<Tag> tags) {
  if (tags.isEmpty) return tags;

  final placements = generateDynamicLayout(
    items: tags,
    getId: (t) => t.id,
    organizeIntoLayers: organizeTagsByDepth,
    groupBy: groupTagsByConnectedComponents,
    direction: GraphDirection.topToBottom,
    itemWidth: 3,
    itemHeight: 1,
    mainAxisSpacing: 2,
    crossAxisSpacing: 2,
  );

  return tags.map((tag) {
    final p = placements[tag.id];
    if (p == null) return tag;
    return Tag(
      id: tag.id,
      name: tag.name,
      color: tag.color,
      parents: tag.parents,
      placement: Placement(x: p.x, y: p.y, width: p.width, height: p.height),
    );
  }).toList();
}

// ============ LEGACY HELPERS (for backwards compatibility) ============

Tag? generateRandomTag([double change = 1, double decrease = 0.6]) {
  if (change <= epsilon) return null;
  final r = random.decimal();
  if (r > change) return null;
  final parents = <Tag>[];
  while (true) {
    final parent = generateRandomTag(change * decrease, decrease);
    if (parent == null) break;
    parents.add(parent);
  }
  return Tag(
    id: faker.guid.guid(),
    name: faker.lorem.words(random.integer(4, min: 1)).join(" ").snakeCase(),
    color: safeColors.randomElement().toProtoColor(),
    parents: parents,
    placement: Placement(
      x: random.integer(20),
      y: random.integer(10),
      width: random.integer(6, min: 2),
      height: random.integer(3, min: 1),
    ),
  );
}

Tag ensureRandomTag([double change = 1, double decrease = 0.6]) {
  var tag = generateRandomTag(change, decrease);
  while (tag == null) {
    tag = generateRandomTag(change, decrease);
  }
  return tag;
}

Tag createTagWithId(String id, {String? name, int? colorValue}) {
  return Tag(
    id: id,
    name:
        name ??
        faker.lorem.words(random.integer(3, min: 1)).join(" ").snakeCase(),
    color: colorValue != null
        ? (Color()..value = colorValue)
        : safeColors.randomElement().toProtoColor(),
    placement: Placement(
      x: random.integer(10),
      y: random.integer(5),
      width: random.integer(4, min: 2),
      height: 1,
    ),
  );
}

// ============ MOCK CLASS ============

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
    yield applyTagLayout(tags);
  }

  @override
  Future<Tag?> createTag({
    required String name,
    Color? color,
    List<String> parentIds = const [],
    int x = 0,
    int y = 0,
    int width = 4,
    int height = 1,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    final newTag = ensureRandomTag();
    state = AsyncData([...tags, newTag]);
    return newTag;
  }

  @override
  Future<void> updateTag(Tag tag) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    state = AsyncData(tags.map((t) => t.id == tag.id ? tag : t).toList());
  }

  @override
  Future<void> deleteTag(String tagId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final tags = await future;
    state = AsyncData(tags.where((t) => t.id != tagId).toList());
  }

  @override
  Future<void> moveTag(String tagId, int x, int y) async {}

  @override
  Future<void> resizeTag(String tagId, int width, int height) async {}
}

// ============ PROVIDER OVERRIDES ============

List<Override> tagsProviderOverrides({
  DisplayState state = DisplayState.loading,
  List<Tag>? tags,
}) => [
  tagsProvider.overrideWith(
    () => TagsMock(displayState: state, specificTags: tags),
  ),
];
