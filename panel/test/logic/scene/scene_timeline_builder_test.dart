import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_builder.dart";
import "package:typewriter_panel/logic/scene/scene_timeline_item.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";

void main() {
  group("buildSceneTimelineData", () {
    test("resolves nested absolute frames from relative cue data", () {
      final timeline = buildSceneTimelineData(_sceneElements());

      final root = _segmentItem(timeline, "root");
      final child = _segmentItem(timeline, "child");
      final grandchild = _keyframeItem(timeline, "grandchild");
      final rootKeyframe = _keyframeItem(timeline, "root_keyframe");

      expect(root.localStartFrame, 10);
      expect(root.localEndFrame, 30);
      expect(root.absoluteStartFrame, 10);
      expect(root.absoluteEndFrame, 30);
      expect(root.requiredDuration, 15);

      expect(child.localStartFrame, 5);
      expect(child.localEndFrame, 15);
      expect(child.absoluteStartFrame, 15);
      expect(child.absoluteEndFrame, 25);
      expect(child.requiredDuration, 4);

      expect(grandchild.localFrame, 4);
      expect(grandchild.absoluteFrame, 19);
      expect(rootKeyframe.localFrame, 7);
      expect(rootKeyframe.absoluteFrame, 17);
    });

    test("moves nested segments within parent local bounds", () {
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "child",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 25,
          endFrame: 35,
        ),
      );

      final child = _segmentItem(timeline, "child");
      final grandchild = _keyframeItem(timeline, "grandchild");

      expect(child.localStartFrame, 10);
      expect(child.localEndFrame, 20);
      expect(child.absoluteStartFrame, 20);
      expect(child.absoluteEndFrame, 30);
      expect(grandchild.localFrame, 4);
      expect(grandchild.absoluteFrame, 24);
    });

    test("keeps parent resize within descendant requirements", () {
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root",
          mode: SceneTimelineOverrideMode.resizeEnd,
          startFrame: 10,
          endFrame: 22,
        ),
      );

      final root = _segmentItem(timeline, "root");
      expect(root.localEndFrame, 25);

      final constrained = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root",
          mode: SceneTimelineOverrideMode.resizeEnd,
          startFrame: 10,
          endFrame: 12,
        ),
      );

      final constrainedRoot = _segmentItem(constrained, "root");
      expect(constrainedRoot.localEndFrame, 25);
      expect(constrainedRoot.absoluteEndFrame, 25);
    });

    test("clamps resizeStart by descendant required duration", () {
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root",
          mode: SceneTimelineOverrideMode.resizeStart,
          startFrame: 29,
          endFrame: 30,
        ),
      );

      final root = _segmentItem(timeline, "root");
      final child = _segmentItem(timeline, "child");
      final grandchild = _keyframeItem(timeline, "grandchild");

      expect(root.localStartFrame, 15);
      expect(root.localEndFrame, 30);
      expect(root.absoluteStartFrame, 15);
      expect(child.absoluteStartFrame, 20);
      expect(grandchild.absoluteFrame, 24);
    });

    test("clamps nested resizeEnd by parent duration", () {
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "child",
          mode: SceneTimelineOverrideMode.resizeEnd,
          startFrame: 15,
          endFrame: 60,
        ),
      );

      final child = _segmentItem(timeline, "child");

      expect(child.localStartFrame, 5);
      expect(child.localEndFrame, 20);
      expect(child.absoluteStartFrame, 15);
      expect(child.absoluteEndFrame, 30);
    });

    test("clamps nested keyframes to parent duration", () {
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root_keyframe",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 50,
          endFrame: 50,
        ),
      );

      final keyframe = _keyframeItem(timeline, "root_keyframe");
      expect(keyframe.localFrame, 20);
      expect(keyframe.absoluteFrame, 30);
    });

    test("clamps nested keyframe moves at lower and upper bounds", () {
      final lower = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "grandchild",
          mode: SceneTimelineOverrideMode.move,
          startFrame: -10,
          endFrame: -10,
        ),
      );
      final lowerGrandchild = _keyframeItem(lower, "grandchild");

      expect(lowerGrandchild.localFrame, 0);
      expect(lowerGrandchild.absoluteFrame, 15);

      final upper = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "grandchild",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 80,
          endFrame: 80,
        ),
      );
      final upperGrandchild = _keyframeItem(upper, "grandchild");

      expect(upperGrandchild.localFrame, 10);
      expect(upperGrandchild.absoluteFrame, 25);
    });

    test("clamps root keyframe moves at lower bound and keeps upper frame", () {
      final lower = buildSceneTimelineData(
        _rootKeyframeSceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root_keyframe",
          mode: SceneTimelineOverrideMode.move,
          startFrame: -5,
          endFrame: -5,
        ),
      );
      final lowerKeyframe = _keyframeItem(lower, "root_keyframe");

      expect(lowerKeyframe.localFrame, 0);
      expect(lowerKeyframe.absoluteFrame, 0);

      final upper = buildSceneTimelineData(
        _rootKeyframeSceneElements(),
        override: const SceneTimelineOverride(
          cueId: "root_keyframe",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 42,
          endFrame: 42,
        ),
      );
      final upperKeyframe = _keyframeItem(upper, "root_keyframe");

      expect(upperKeyframe.localFrame, 42);
      expect(upperKeyframe.absoluteFrame, 42);
    });

    test("ignores stale or missing override targets", () {
      final baseline = buildSceneTimelineData(_sceneElements());
      final timeline = buildSceneTimelineData(
        _sceneElements(),
        override: const SceneTimelineOverride(
          cueId: "missing_cue",
          mode: SceneTimelineOverrideMode.move,
          startFrame: 999,
          endFrame: 999,
        ),
      );

      final baselineRoot = _segmentItem(baseline, "root");
      final baselineChild = _segmentItem(baseline, "child");
      final baselineGrandchild = _keyframeItem(baseline, "grandchild");
      final baselineRootKeyframe = _keyframeItem(baseline, "root_keyframe");

      final root = _segmentItem(timeline, "root");
      final child = _segmentItem(timeline, "child");
      final grandchild = _keyframeItem(timeline, "grandchild");
      final rootKeyframe = _keyframeItem(timeline, "root_keyframe");

      expect(root.localStartFrame, baselineRoot.localStartFrame);
      expect(root.localEndFrame, baselineRoot.localEndFrame);
      expect(root.absoluteStartFrame, baselineRoot.absoluteStartFrame);
      expect(root.absoluteEndFrame, baselineRoot.absoluteEndFrame);
      expect(child.localStartFrame, baselineChild.localStartFrame);
      expect(child.localEndFrame, baselineChild.localEndFrame);
      expect(child.absoluteStartFrame, baselineChild.absoluteStartFrame);
      expect(child.absoluteEndFrame, baselineChild.absoluteEndFrame);
      expect(grandchild.localFrame, baselineGrandchild.localFrame);
      expect(grandchild.absoluteFrame, baselineGrandchild.absoluteFrame);
      expect(rootKeyframe.localFrame, baselineRootKeyframe.localFrame);
      expect(rootKeyframe.absoluteFrame, baselineRootKeyframe.absoluteFrame);
    });

    test("sorts siblings by frame, span, and cue type", () {
      final timeline = buildSceneTimelineData(_sortingSceneElements());
      final track = timeline.tracks.single;

      expect(track.rootItems.map((item) => item.cueId).toList(), [
        "wide_segment",
        "narrow_segment",
        "tie_keyframe",
        "late_segment",
      ]);
    });

    test("asserts on cyclic cue hierarchies", () {
      expect(
        () => buildSceneTimelineData(_cyclicSceneElements()),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

List<PageElement> _sceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Scene Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 10,
        endFrame: 30,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_child",
            otherId: "child",
            path: "children",
          ),
          const ElementLink(
            linkId: "root_keyframe_link",
            otherId: "root_keyframe",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "child",
        startFrame: 5,
        endFrame: 15,
        blueprint: _blueprint("child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "child_grandchild",
            otherId: "grandchild",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "grandchild",
        frame: 4,
        blueprint: _blueprint("grandchild_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "child_grandchild",
            otherId: "child",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_keyframe",
        frame: 7,
        blueprint: _blueprint("root_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_keyframe_link",
            otherId: "root",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _sortingSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Sorting Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_wide_segment",
              otherId: "wide_segment",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_narrow_segment",
              otherId: "narrow_segment",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_tie_keyframe",
              otherId: "tie_keyframe",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_late_segment",
              otherId: "late_segment",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "wide_segment",
        startFrame: 5,
        endFrame: 12,
        blueprint: _blueprint("wide_segment_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_wide_segment",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "narrow_segment",
        startFrame: 5,
        endFrame: 8,
        blueprint: _blueprint("narrow_segment_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_narrow_segment",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "tie_keyframe",
        frame: 5,
        blueprint: _blueprint("tie_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_tie_keyframe",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "late_segment",
        startFrame: 9,
        endFrame: 14,
        blueprint: _blueprint("late_segment_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_late_segment",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _rootKeyframeSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Root Keyframe Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_keyframe",
              otherId: "root_keyframe",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "root_keyframe",
        frame: 7,
        blueprint: _blueprint("root_keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_keyframe",
            otherId: "entry",
            path: "parent",
          ),
        ],
      ),
    ),
  ];
}

List<PageElement> _cyclicSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Cycle Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 10,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root",
            otherId: "entry",
            path: "parent",
          ),
          const ElementLink(
            linkId: "child_root",
            otherId: "child",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "root_child",
            otherId: "child",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "child",
        startFrame: 2,
        endFrame: 6,
        blueprint: _blueprint("child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: [
          const ElementLink(
            linkId: "child_root",
            otherId: "root",
            path: "children",
          ),
        ],
      ),
    ),
  ];
}

ElementBlueprint _blueprint(String id) {
  return ElementBlueprint(
    id: id,
    name: id,
    description: id,
    extension: "test",
    dataBlueprint: ObjectBlueprint(fields: {}),
    color: Colors.blue,
  );
}

SceneSegmentItem _segmentItem(dynamic timeline, String cueId) {
  final item = timeline.itemByCueId(cueId);
  expect(item, isA<SceneSegmentItem>());
  return item! as SceneSegmentItem;
}

SceneKeyframeItem _keyframeItem(dynamic timeline, String cueId) {
  final item = timeline.itemByCueId(cueId);
  expect(item, isA<SceneKeyframeItem>());
  return item! as SceneKeyframeItem;
}
