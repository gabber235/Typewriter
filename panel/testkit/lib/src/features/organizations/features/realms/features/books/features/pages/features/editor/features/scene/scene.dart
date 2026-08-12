import "dart:math" as math;

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "scene_element_definition.dart";
part "scene_building.dart";
part "scene_random.dart";

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
    RecordValue? data,
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
    RecordValue? data,
    List<SceneCueDsl> children,
  }) = SceneSegmentDsl;

  factory SceneCueDsl.keyframe(
    String id, {
    required int frame,
    String? name,
    Color? color,
    String? icon,
    RecordValue? data,
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
  final RecordValue? data;
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
  final RecordValue? data;
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
  final RecordValue? data;
  final List<SceneCueDsl> children;
}
