import "dart:math" as math;

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

SceneElementsDsl sceneElements() => SceneElementsDsl();

List<PageElement> generateRandomScenePageElements(int count) {
  return _SceneMockBuilder().generateWithDsl(count);
}

class SceneElementsDsl {
  final List<_SceneEntryDsl> _entries = [];

  SceneElementsDsl entry({
    required String id,
    String? name,
    Color? color,
    String? icon,
    EntryPlacement? placement,
    DynamicData? data,
    List<SceneCueDsl> children = const [],
  }) {
    _entries.add(
      _SceneEntryDsl(
        id: id,
        name: name,
        color: color,
        icon: icon,
        placement: placement,
        data: data,
        children: children,
      ),
    );
    return this;
  }

  List<PageElement> build() {
    if (_entries.isEmpty) return const [];

    final elements = <PageElement>[];
    final usedIds = <String>{};

    for (var entryIndex = 0; entryIndex < _entries.length; entryIndex++) {
      final entryDsl = _entries[entryIndex];
      assert(usedIds.add(entryDsl.id), "Duplicate scene id ${entryDsl.id}");

      final entryName = entryDsl.name ?? "Scene Entry ${entryIndex + 1}";
      final entryBlueprint = _buildBlueprint(
        id: "${entryDsl.id}_blueprint",
        name: entryName,
        icon: entryDsl.icon ?? "solar:video-frame-bold",
        color: entryDsl.color,
      );

      final outwardEdges = <ElementLink>[];
      final cueElements = <PageElement>[];

      for (
        var childIndex = 0;
        childIndex < entryDsl.children.length;
        childIndex++
      ) {
        final child = entryDsl.children[childIndex];
        final linkId = _linkId(entryDsl.id, child.id, childIndex);
        outwardEdges.add(
          ElementLink(linkId: linkId, otherId: child.id, path: "children"),
        );
        cueElements.addAll(
          _buildCueElements(
            cueDsl: child,
            parentId: entryDsl.id,
            parentLinkId: linkId,
            usedIds: usedIds,
          ),
        );
      }

      final entryData = _mergeData({
        "entryType": outwardEdges.length.isEven ? "entity" : "title",
        "label": entryName,
      }, entryDsl.data);

      final entry = EntryDefinition(
        id: entryDsl.id,
        name: entryName,
        blueprint: entryBlueprint,
        placement:
            entryDsl.placement ??
            EntryPlacement(
              x: 40 + ((entryIndex % 4) * 220),
              y: 32 + ((entryIndex ~/ 4) * 120),
              width: 180,
              height: 72,
            ),
        data: entryData,
        inwardEdges: const [],
        outwardEdges: outwardEdges,
      );

      elements
        ..add(PageElement.entry(entry: PageEntry.definition(definition: entry)))
        ..addAll(cueElements);
    }

    return elements;
  }
}

abstract class SceneCueDsl {
  const SceneCueDsl._();

  factory SceneCueDsl.segment(
    String id, {
    required int start,
    required int end,
    String? name,
    Color? color,
    String? icon,
    DynamicData? data,
    List<SceneCueDsl> children,
  }) = SceneSegmentDsl;

  factory SceneCueDsl.keyframe(
    String id, {
    required int frame,
    String? name,
    Color? color,
    String? icon,
    DynamicData? data,
  }) = SceneKeyframeDsl;

  String get id;
}

class SceneSegmentDsl extends SceneCueDsl {
  SceneSegmentDsl(
    this.id, {
    required this.start,
    required this.end,
    this.name,
    this.color,
    this.icon,
    this.data,
    this.children = const [],
  }) : super._() {
    assert(start <= end, "Segment $id has start > end");
  }

  @override
  final String id;
  final int start;
  final int end;
  final String? name;
  final Color? color;
  final String? icon;
  final DynamicData? data;
  final List<SceneCueDsl> children;
}

class SceneKeyframeDsl extends SceneCueDsl {
  SceneKeyframeDsl(
    this.id, {
    required this.frame,
    this.name,
    this.color,
    this.icon,
    this.data,
  }) : super._();

  @override
  final String id;
  final int frame;
  final String? name;
  final Color? color;
  final String? icon;
  final DynamicData? data;
}

class _SceneEntryDsl {
  const _SceneEntryDsl({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    required this.placement,
    required this.data,
    required this.children,
  });

  final String id;
  final String? name;
  final Color? color;
  final String? icon;
  final EntryPlacement? placement;
  final DynamicData? data;
  final List<SceneCueDsl> children;
}

List<PageElement> _buildCueElements({
  required SceneCueDsl cueDsl,
  required String parentId,
  required String parentLinkId,
  required Set<String> usedIds,
}) {
  assert(usedIds.add(cueDsl.id), "Duplicate scene id ${cueDsl.id}");

  if (cueDsl case SceneKeyframeDsl keyframeDsl) {
    final keyframeName = keyframeDsl.name ?? cueDsl.id;
    final keyframe = Cue.keyframe(
      id: keyframeDsl.id,
      blueprint: _buildBlueprint(
        id: "${keyframeDsl.id}_blueprint",
        name: keyframeName,
        icon: keyframeDsl.icon ?? "fa7-solid:star",
        color: keyframeDsl.color,
      ),
      frame: keyframeDsl.frame,
      data: _mergeData({
        "channel": "scene",
        "event": "trigger",
        "label": keyframeName,
      }, keyframeDsl.data),
      inwardLinks: [
        ElementLink(linkId: parentLinkId, otherId: parentId, path: "parent"),
      ],
    );

    return [PageElement.cue(cue: keyframe)];
  }

  final segmentDsl = cueDsl as SceneSegmentDsl;
  final segmentName = segmentDsl.name ?? cueDsl.id;
  final outwardLinks = <ElementLink>[];
  final children = <PageElement>[];

  for (
    var childIndex = 0;
    childIndex < segmentDsl.children.length;
    childIndex++
  ) {
    final child = segmentDsl.children[childIndex];
    final linkId = _linkId(segmentDsl.id, child.id, childIndex);
    outwardLinks.add(
      ElementLink(linkId: linkId, otherId: child.id, path: "children"),
    );
    children.addAll(
      _buildCueElements(
        cueDsl: child,
        parentId: segmentDsl.id,
        parentLinkId: linkId,
        usedIds: usedIds,
      ),
    );
  }

  final segment = Cue.segment(
    id: segmentDsl.id,
    blueprint: _buildBlueprint(
      id: "${segmentDsl.id}_blueprint",
      name: segmentName,
      icon: segmentDsl.icon ?? "fa-solid:video",
      color: segmentDsl.color,
    ),
    startFrame: segmentDsl.start,
    endFrame: segmentDsl.end,
    data: _mergeData({
      "channel": "scene",
      "label": segmentName,
      "mode": "cinematic",
    }, segmentDsl.data),
    inwardLinks: [
      ElementLink(linkId: parentLinkId, otherId: parentId, path: "parent"),
    ],
    outwardLinks: outwardLinks,
  );

  return [PageElement.cue(cue: segment), ...children];
}

ElementBlueprint _buildBlueprint({
  required String id,
  required String name,
  required String icon,
  required Color? color,
}) {
  final generated = _generateSceneBlueprint(id: id, name: name, icon: icon);
  if (color == null) {
    return generated;
  }
  return generated.copyWith(color: color);
}

DynamicData _mergeData(Map<String, dynamic> defaults, DynamicData? overrides) {
  if (overrides == null) {
    return DynamicData(defaults);
  }
  return DynamicData({...defaults, ...overrides.data});
}

String _linkId(String parentId, String childId, int index) {
  return "${parentId}_${childId}_$index";
}

class _SceneMockBuilder {
  final math.Random _random = math.Random();

  List<PageElement> generateWithDsl(int count) {
    if (count <= 0) return const [];

    final dsl = sceneElements();
    var consumed = 0;

    for (var entryIndex = 0; consumed < count; entryIndex++) {
      final remaining = count - consumed;
      final blockBudget = remaining <= 10
          ? remaining
          : _nextInt(10, math.min(16, remaining));
      final entry = _generateEntry(entryIndex, blockBudget);
      dsl.entry(
        id: entry.id,
        name: entry.name,
        icon: entry.icon,
        placement: entry.placement,
        data: entry.data,
        children: entry.children,
      );
      consumed += blockBudget;
    }

    return dsl.build();
  }

  _GeneratedEntry _generateEntry(int entryIndex, int budget) {
    assert(budget > 0);

    final entryId = "scene_entry_$entryIndex";
    final rootChildren = <SceneCueDsl>[];
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
        final range = _generateRootSegmentRange();
        final tree = _generateSegmentTree(
          entryIndex: entryIndex,
          nodePath: "$rootIndex",
          depth: 0,
          budget: rootBudgets[rootIndex],
          startFrame: range.$1,
          endFrame: range.$2,
        );
        rootChildren.add(tree);
      }
    }

    return _GeneratedEntry(
      id: entryId,
      name: "Scene Entry ${entryIndex + 1}",
      icon: "solar:video-frame-bold",
      placement: EntryPlacement(
        x: 40 + ((entryIndex % 4) * 220),
        y: 32 + ((entryIndex ~/ 4) * 120),
        width: 180,
        height: 72,
      ),
      data: DynamicData({
        "entryType": rootChildren.length.isEven ? "entity" : "title",
        "label": "Scene Entry ${entryIndex + 1}",
      }),
      children: rootChildren,
    );
  }

  SceneCueDsl _generateSegmentTree({
    required int entryIndex,
    required String nodePath,
    required int depth,
    required int budget,
    required int startFrame,
    required int endFrame,
  }) {
    assert(budget > 0);

    final cueId = "scene_entry_${entryIndex}_segment_$nodePath";
    final kind = _pickSegmentKind(depth);
    final remainingBudget = budget - 1;
    final children = <SceneCueDsl>[];

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
          final range = _generateRelativeSegmentRange(endFrame - startFrame);
          children.add(
            _generateSegmentTree(
              entryIndex: entryIndex,
              nodePath: "${nodePath}_$childIndex",
              depth: depth + 1,
              budget: childBudgets[childIndex],
              startFrame: range.$1,
              endFrame: range.$2,
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
        children.add(
          SceneCueDsl.keyframe(
            keyframeId,
            name: "${kind.name} Keyframe",
            icon: _pickKeyframeIcon(),
            frame: _generateRelativeKeyframe(endFrame - startFrame),
            data: DynamicData({
              "channel": kind.channel,
              "event": _pickKeyframeEvent(depth),
              "label": "${kind.name} Keyframe ${keyframeIndex + 1}",
            }),
          ),
        );
      }
    }

    return SceneCueDsl.segment(
      cueId,
      name: kind.name,
      icon: kind.icon,
      start: startFrame,
      end: endFrame,
      data: DynamicData({
        "channel": kind.channel,
        "label": "${kind.name} ${entryIndex + 1}.$nodePath",
        "mode": _pickSegmentMode(depth),
      }),
      children: children,
    );
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

class _GeneratedEntry {
  const _GeneratedEntry({
    required this.id,
    required this.name,
    required this.icon,
    required this.placement,
    required this.data,
    required this.children,
  });

  final String id;
  final String name;
  final String icon;
  final EntryPlacement placement;
  final DynamicData data;
  final List<SceneCueDsl> children;
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
