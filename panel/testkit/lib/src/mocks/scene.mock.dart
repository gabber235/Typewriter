import "dart:math" as math;

import "package:faker/faker.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/utils/color.dart";

List<PageElement> generateRandomScenePageElements(int count) {
  return _SceneMockBuilder().generate(count);
}

class _SceneMockBuilder {
  final math.Random _random = math.Random();

  List<PageElement> generate(int count) {
    if (count <= 0) return const [];

    final elements = <PageElement>[];
    for (var entryIndex = 0; elements.length < count; entryIndex++) {
      final remaining = count - elements.length;
      final blockBudget = remaining <= 10
          ? remaining
          : _nextInt(10, math.min(16, remaining));
      elements.addAll(_generateEntryBlock(entryIndex, blockBudget));
    }

    return elements;
  }

  List<PageElement> _generateEntryBlock(int entryIndex, int budget) {
    if (budget <= 0) return const [];

    final entryId = "scene_entry_$entryIndex";
    final rootElements = <PageElement>[];
    final rootLinks = <ElementLink>[];
    final remainingCueBudget = budget - 1;

    if (remainingCueBudget > 0) {
      final rootCount = _nextInt(
        remainingCueBudget >= 4 ? 2 : 1,
        math.min(3, remainingCueBudget),
      );
      final rootBudgets = _splitBudget(
        remainingCueBudget,
        rootCount,
        minEach: 1,
      );

      for (var rootIndex = 0; rootIndex < rootBudgets.length; rootIndex++) {
        final linkId = faker.guid.guid();
        final range = _generateRootSegmentRange();
        final tree = _generateSegmentTree(
          entryIndex: entryIndex,
          nodePath: "$rootIndex",
          depth: 0,
          budget: rootBudgets[rootIndex],
          parentId: entryId,
          linkId: linkId,
          startFrame: range.$1,
          endFrame: range.$2,
        );
        rootElements.addAll(tree.elements);
        rootLinks.add(
          ElementLink(linkId: linkId, otherId: tree.cueId, path: "children"),
        );
      }
    }

    final entry = EntryDefinition(
      id: entryId,
      name: "Scene Entry ${entryIndex + 1}",
      blueprint: _generateSceneBlueprint(
        id: "scene_entry_${entryIndex}_blueprint",
        name: "Scene Entry Blueprint ${entryIndex + 1}",
        icon: "solar:video-frame-bold",
      ),
      placement: EntryPlacement(
        x: 40 + ((entryIndex % 4) * 220),
        y: 32 + ((entryIndex ~/ 4) * 120),
        width: 180,
        height: 72,
      ),
      data: DynamicData({
        "entryType": rootLinks.length.isEven ? "entity" : "title",
        "label": "Scene Entry ${entryIndex + 1}",
      }),
      inwardEdges: const [],
      outwardEdges: rootLinks,
    );

    return [
      PageElement.entry(entry: PageEntry.definition(definition: entry)),
      ...rootElements,
    ];
  }

  _CueTree _generateSegmentTree({
    required int entryIndex,
    required String nodePath,
    required int depth,
    required int budget,
    required String parentId,
    required String linkId,
    required int startFrame,
    required int endFrame,
  }) {
    assert(budget > 0);

    final cueId = "scene_entry_${entryIndex}_segment_$nodePath";
    final kind = _pickSegmentKind(depth);
    final remainingBudget = budget - 1;
    final childElements = <PageElement>[];
    final outwardLinks = <ElementLink>[];

    if (remainingBudget > 0) {
      final childSegmentCount = _pickChildSegmentCount(depth, remainingBudget);
      final keyframeCount = _pickKeyframeCount(
        remainingBudget: remainingBudget,
        childSegmentCount: childSegmentCount,
      );
      final childSegmentBudget = remainingBudget - keyframeCount;

      if (childSegmentCount > 0) {
        final childBudgets = _splitBudget(
          childSegmentBudget,
          childSegmentCount,
          minEach: 1,
        );

        for (
          var childIndex = 0;
          childIndex < childBudgets.length;
          childIndex++
        ) {
          final childLinkId = faker.guid.guid();
          final range = _generateRelativeSegmentRange(endFrame - startFrame);
          final childTree = _generateSegmentTree(
            entryIndex: entryIndex,
            nodePath: "${nodePath}_$childIndex",
            depth: depth + 1,
            budget: childBudgets[childIndex],
            parentId: cueId,
            linkId: childLinkId,
            startFrame: range.$1,
            endFrame: range.$2,
          );
          childElements.addAll(childTree.elements);
          outwardLinks.add(
            ElementLink(
              linkId: childLinkId,
              otherId: childTree.cueId,
              path: "children",
            ),
          );
        }
      }

      for (
        var keyframeIndex = 0;
        keyframeIndex < keyframeCount;
        keyframeIndex++
      ) {
        final keyframeId =
            "scene_entry_${entryIndex}_keyframe_${nodePath}_$keyframeIndex";
        final keyframeLinkId = faker.guid.guid();
        childElements.add(
          PageElement.cue(
            cue: Cue.keyframe(
              id: keyframeId,
              blueprint: _generateSceneBlueprint(
                id: "scene_entry_${entryIndex}_keyframe_blueprint_${nodePath}_$keyframeIndex",
                name: "${kind.name} Keyframe",
                icon: _pickKeyframeIcon(),
              ),
              frame: _generateRelativeKeyframe(endFrame - startFrame),
              data: DynamicData({
                "channel": kind.channel,
                "event": _pickKeyframeEvent(depth),
                "label": "${kind.name} Keyframe ${keyframeIndex + 1}",
              }),
              inwardLinks: [
                ElementLink(
                  linkId: keyframeLinkId,
                  otherId: cueId,
                  path: "parent",
                ),
              ],
            ),
          ),
        );
        outwardLinks.add(
          ElementLink(
            linkId: keyframeLinkId,
            otherId: keyframeId,
            path: "children",
          ),
        );
      }
    }

    final segment = PageElement.cue(
      cue: Cue.segment(
        id: cueId,
        blueprint: _generateSceneBlueprint(
          id: "scene_entry_${entryIndex}_segment_blueprint_$nodePath",
          name: kind.name,
          icon: kind.icon,
        ),
        startFrame: startFrame,
        endFrame: endFrame,
        data: DynamicData({
          "channel": kind.channel,
          "label": "${kind.name} ${entryIndex + 1}.$nodePath",
          "mode": _pickSegmentMode(depth),
        }),
        inwardLinks: [
          ElementLink(linkId: linkId, otherId: parentId, path: "parent"),
        ],
        outwardLinks: outwardLinks,
      ),
    );

    return _CueTree(cueId: cueId, elements: [segment, ...childElements]);
  }

  (int, int) _generateRootSegmentRange() {
    final startFrame = _nextInt(0, 72);
    final duration = _nextInt(24, 120);
    return (startFrame, startFrame + duration);
  }

  (int, int) _generateRelativeSegmentRange(int parentDuration) {
    if (parentDuration <= 0) return (0, 0);

    final startFrame = _nextInt(0, parentDuration);
    final availableDuration = parentDuration - startFrame;
    if (availableDuration <= 0) return (startFrame, startFrame);

    final minimumSpan = math.min(12, availableDuration);
    final endFrame = startFrame + _nextInt(minimumSpan, availableDuration);
    return (startFrame, endFrame);
  }

  int _generateRelativeKeyframe(int parentDuration) {
    if (parentDuration <= 0) return 0;
    return _nextInt(0, parentDuration);
  }

  int _pickChildSegmentCount(int depth, int remainingBudget) {
    if (depth >= 2 || remainingBudget <= 0) return 0;

    final maxChildSegments = math.min(3, remainingBudget);
    if (maxChildSegments == 0) return 0;

    final minChildSegments = switch (depth) {
      0 when remainingBudget >= 4 => 1,
      1 when remainingBudget >= 3 && _random.nextBool() => 1,
      _ => 0,
    };

    return _nextInt(minChildSegments, maxChildSegments);
  }

  int _pickKeyframeCount({
    required int remainingBudget,
    required int childSegmentCount,
  }) {
    final maxKeyframes = math.min(3, remainingBudget - childSegmentCount);
    if (maxKeyframes <= 0) return 0;
    return _nextInt(1, maxKeyframes);
  }

  List<int> _splitBudget(int total, int parts, {required int minEach}) {
    assert(parts > 0);
    assert(total >= parts * minEach);

    final budgets = List.filled(parts, minEach);
    var remaining = total - (parts * minEach);

    while (remaining > 0) {
      final index = _random.nextInt(parts);
      budgets[index]++;
      remaining--;
    }

    budgets.shuffle(_random);
    return budgets;
  }

  _SceneCueKind _pickSegmentKind(int depth) {
    final kinds = switch (depth) {
      0 => _rootCueKinds,
      1 => _childCueKinds,
      _ => _grandchildCueKinds,
    };
    return kinds[_random.nextInt(kinds.length)];
  }

  String _pickSegmentMode(int depth) {
    final modes = switch (depth) {
      0 => ["cinematic", "staged", "hero"],
      1 => ["follow", "accent", "reaction"],
      _ => ["detail", "flare", "micro"],
    };
    return modes[_random.nextInt(modes.length)];
  }

  String _pickKeyframeEvent(int depth) {
    final events = switch (depth) {
      0 => ["intro", "focus", "resolve"],
      1 => ["step", "emote", "swing"],
      _ => ["blink", "spark", "pulse"],
    };
    return events[_random.nextInt(events.length)];
  }

  String _pickKeyframeIcon() {
    const icons = [
      "fa7-solid:person-rays",
      "fa7-solid:wand-magic-sparkles",
      "fa7-solid:star",
    ];
    return icons[_random.nextInt(icons.length)];
  }

  int _nextInt(int min, int max) {
    assert(min <= max);
    return min + _random.nextInt((max - min) + 1);
  }
}

class _CueTree {
  const _CueTree({required this.cueId, required this.elements});

  final String cueId;
  final List<PageElement> elements;
}

class _SceneCueKind {
  const _SceneCueKind({
    required this.name,
    required this.icon,
    required this.channel,
  });

  final String name;
  final String icon;
  final String channel;
}

ElementBlueprint _generateSceneBlueprint({
  required String id,
  required String name,
  required String icon,
}) {
  return ElementBlueprint(
    id: id,
    name: name,
    description: "$name for scene stories",
    extension: "scene",
    dataBlueprint: _generateSceneDataBlueprint(),
    color: safeColors[id.hashCode.abs() % safeColors.length],
    icon: icon,
    tags: const ["scene"],
  );
}

ObjectBlueprint _generateSceneDataBlueprint() {
  return DataBlueprint.object(
        fields: {
          "channel": DataBlueprint.string(),
          "label": DataBlueprint.string(),
          "mode": DataBlueprint.string(),
          "event": DataBlueprint.string(),
        },
      )
      as ObjectBlueprint;
}

const _rootCueKinds = [
  _SceneCueKind(
    name: "Entity Segment",
    icon: "fa7-solid:user",
    channel: "entity",
  ),
  _SceneCueKind(name: "Title Segment", icon: "fa-solid:font", channel: "title"),
  _SceneCueKind(
    name: "Camera Segment",
    icon: "fa-solid:video",
    channel: "camera",
  ),
];

const _childCueKinds = [
  _SceneCueKind(
    name: "Motion Segment",
    icon: "fa7-solid:person-running",
    channel: "motion",
  ),
  _SceneCueKind(
    name: "Effect Segment",
    icon: "fa7-solid:burst",
    channel: "effect",
  ),
  _SceneCueKind(
    name: "Dialogue Segment",
    icon: "fa7-solid:comment",
    channel: "dialogue",
  ),
];

const _grandchildCueKinds = [
  _SceneCueKind(
    name: "Detail Segment",
    icon: "fa7-solid:wand-magic",
    channel: "detail",
  ),
  _SceneCueKind(
    name: "Signal Segment",
    icon: "fa7-solid:wave-square",
    channel: "signal",
  ),
  _SceneCueKind(
    name: "Accent Segment",
    icon: "fa7-solid:bolt",
    channel: "accent",
  ),
];
