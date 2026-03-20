import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/scene/scene_cue_index.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";

void main() {
  group("SceneCueIndex.fromPageElements", () {
    test("dedupes roots, parents, and children while ignoring other paths", () {
      final index = SceneCueIndex.fromPageElements(_dedupedSceneElements());

      expect(index.entries.single.id, "entry");
      expect(index.rootCueIdsByEntryId["entry"], ["root"]);
      expect(index.parentByCueId["root"], "entry");
      expect(index.parentByCueId["child"], "root");
      expect(index.childrenByCueId["root"], ["child", "keyframe"]);
      expect(index.childrenByCueId.containsKey("keyframe"), isFalse);
    });

    test("asserts when a cue has multiple distinct parents", () {
      expect(
        () => SceneCueIndex.fromPageElements(_multipleParentSceneElements()),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

List<PageElement> _dedupedSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: const [
            ElementLink(
              linkId: "entry_root_1",
              otherId: "root",
              path: "children",
            ),
            ElementLink(
              linkId: "entry_root_2",
              otherId: "root",
              path: "children",
            ),
            ElementLink(
              linkId: "entry_note",
              otherId: "ignored",
              path: "notes",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root",
        startFrame: 0,
        endFrame: 20,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "entry_root_1", otherId: "entry", path: "parent"),
          ElementLink(linkId: "entry_root_2", otherId: "entry", path: "parent"),
        ],
        outwardLinks: const [
          ElementLink(
            linkId: "root_child_1",
            otherId: "child",
            path: "children",
          ),
          ElementLink(
            linkId: "root_child_2",
            otherId: "child",
            path: "children",
          ),
          ElementLink(
            linkId: "root_keyframe",
            otherId: "keyframe",
            path: "children",
          ),
          ElementLink(
            linkId: "root_skip",
            otherId: "ignored",
            path: "metadata",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "child",
        startFrame: 2,
        endFrame: 8,
        blueprint: _blueprint("child_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "root_child_1", otherId: "root", path: "parent"),
          ElementLink(linkId: "root_child_2", otherId: "root", path: "parent"),
          ElementLink(linkId: "child_skip", otherId: "ignored", path: "peer"),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "keyframe",
        frame: 4,
        blueprint: _blueprint("keyframe_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "root_keyframe", otherId: "root", path: "parent"),
        ],
      ),
    ),
  ];
}

List<PageElement> _multipleParentSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Entry",
          blueprint: _blueprint("entry_blueprint"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: const [
            ElementLink(
              linkId: "entry_root",
              otherId: "root",
              path: "children",
            ),
            ElementLink(
              linkId: "entry_other",
              otherId: "other",
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
        endFrame: 20,
        blueprint: _blueprint("root_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "entry_root", otherId: "entry", path: "parent"),
        ],
        outwardLinks: const [
          ElementLink(
            linkId: "root_shared",
            otherId: "shared",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "other",
        startFrame: 1,
        endFrame: 12,
        blueprint: _blueprint("other_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "entry_other", otherId: "entry", path: "parent"),
        ],
        outwardLinks: const [
          ElementLink(
            linkId: "other_shared",
            otherId: "shared",
            path: "children",
          ),
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.keyframe(
        id: "shared",
        frame: 4,
        blueprint: _blueprint("shared_blueprint"),
        data: const DynamicData({}),
        inwardLinks: const [
          ElementLink(linkId: "root_shared", otherId: "root", path: "parent"),
          ElementLink(linkId: "other_shared", otherId: "other", path: "parent"),
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
