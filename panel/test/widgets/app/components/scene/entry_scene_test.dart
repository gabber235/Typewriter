import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/iconoir.dart";
import "package:typewriter_panel/logic/pages/element_blueprint.dart";
import "package:typewriter_panel/logic/pages/entries.dart";
import "package:typewriter_panel/logic/pages/page_elements.dart";
import "package:typewriter_panel/logic/pages/scene.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/dynamic_data.dart";
import "package:typewriter_panel/widgets/app/components/scene/scene.dart";
import "package:typewriter_panel/widgets/app/components/timeline/timeline.dart";

import "../../../../test_utils.dart";

void main() {
  group("EntryScene", () {
    testWidgets("commits nested move using resolved local frames", (
      tester,
    ) async {
      final notifier = _TestPageElements(_sceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final surfaceFinder = find.ancestor(
        of: find.text("Child Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls, [
        const [("child", 8, 18)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("commits nested resize using local segment bounds", (
      tester,
    ) async {
      final notifier = _TestPageElements(_sceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final surfaceFinder = find.ancestor(
        of: find.text("Child Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );
      final rect = tester.getRect(surfaceFinder);

      await tester.dragFrom(
        rect.centerRight - const Offset(2, 0),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.resizeCalls, [
        const [("child", 5, 18)],
      ]);
      expect(notifier.moveCalls, isEmpty);
    });

    testWidgets("commits nested start-handle resize using local bounds", (
      tester,
    ) async {
      final notifier = _TestPageElements(_sceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final surfaceFinder = find.ancestor(
        of: find.text("Child Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );
      final rect = tester.getRect(surfaceFinder);

      await tester.dragFrom(
        rect.centerLeft + const Offset(2, 0),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.resizeCalls, [
        const [("child", 8, 15)],
      ]);
      expect(notifier.moveCalls, isEmpty);
    });

    testWidgets("commits root move in root timeline frame", (tester) async {
      final notifier = _TestPageElements(_sceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final surfaceFinder = find.ancestor(
        of: find.text("Root Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(40, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls, [
        const [("root", 12, 32)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("does not commit unaffected cues on nested move", (
      tester,
    ) async {
      final notifier = _TestPageElements(_sceneElementsWithSibling());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final surfaceFinder = find.ancestor(
        of: find.text("Child Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls.length, 1);
      expect(notifier.moveCalls.single, const [("child", 8, 18)]);
      expect(
        notifier.moveCalls.single.any((change) => change.$1 == "sibling"),
        isFalse,
      );
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("moves selected roots together when dragged cue is selected", (
      tester,
    ) async {
      final notifier = _TestPageElements(_multiRootSceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(EntryScene)),
      );
      container.read(selectionProvider.notifier).selectAll([
        const CueIdentifier(pageId: "page", id: "root_a"),
        const CueIdentifier(pageId: "page", id: "root_b"),
      ]);
      await tester.pumpAndSettle();

      final surfaceFinder = find.ancestor(
        of: find.text("Root A"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls, [
        const [("root_a", 13, 33), ("root_b", 43, 53)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("moves only dragged cue when dragged cue is not selected", (
      tester,
    ) async {
      final notifier = _TestPageElements(_multiRootSceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(EntryScene)),
      );
      container.read(selectionProvider.notifier).selectAll([
        const CueIdentifier(pageId: "page", id: "root_b"),
      ]);
      await tester.pumpAndSettle();

      final surfaceFinder = find.ancestor(
        of: find.text("Root A"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls, [
        const [("root_a", 13, 33)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("normalizes selected set to roots before move commit", (
      tester,
    ) async {
      final notifier = _TestPageElements(_sceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(EntryScene)),
      );
      container.read(selectionProvider.notifier).selectAll([
        const CueIdentifier(pageId: "page", id: "root"),
        const CueIdentifier(pageId: "page", id: "child"),
      ]);
      await tester.pumpAndSettle();

      final surfaceFinder = find.ancestor(
        of: find.text("Root Segment"),
        matching: find.byType(TimelineSegmentSurface),
      );

      await tester.dragFrom(
        tester.getRect(surfaceFinder).center,
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();

      expect(notifier.moveCalls, [
        const [("root", 13, 33)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });
  });
}

class _TestPageElements extends PageElements {
  _TestPageElements(this.initialElements);

  final List<PageElement> initialElements;
  final List<List<(String, int, int)>> moveCalls = [];
  final List<List<(String, int, int)>> resizeCalls = [];

  @override
  Future<List<PageElement>> build(String pageId) async => initialElements;

  @override
  Future<void> moveCues(List<(String, int, int)> changed) async {
    moveCalls.add(changed);
    optimisticMoveCues(changed);
  }

  @override
  Future<void> resizeCues(List<(String, int, int)> changed) async {
    resizeCalls.add(changed);
    optimisticResizeCues(changed);
  }
}

List<PageElement> _sceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Scene Entry",
          blueprint: _blueprint("entry_blueprint", "Scene Entry"),
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
        blueprint: _blueprint("root_blueprint", "Root Segment"),
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
        ],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "child",
        startFrame: 5,
        endFrame: 15,
        blueprint: _blueprint("child_blueprint", "Child Segment"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "root_child",
            otherId: "root",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _sceneElementsWithSibling() {
  return [
    ..._sceneElements(),
    PageElement.cue(
      cue: Cue.segment(
        id: "sibling",
        startFrame: 40,
        endFrame: 50,
        blueprint: _blueprint("sibling_blueprint", "Sibling Segment"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_sibling",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

List<PageElement> _multiRootSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Scene Entry",
          blueprint: _blueprint("entry_blueprint", "Scene Entry"),
          placement: const EntryPlacement(x: 0, y: 0, width: 100, height: 60),
          data: const DynamicData({}),
          inwardEdges: const [],
          outwardEdges: [
            const ElementLink(
              linkId: "entry_root_a",
              otherId: "root_a",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_b",
              otherId: "root_b",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_a",
        startFrame: 10,
        endFrame: 30,
        blueprint: _blueprint("root_a_blueprint", "Root A"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_a",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_b",
        startFrame: 40,
        endFrame: 50,
        blueprint: _blueprint("root_b_blueprint", "Root B"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_b",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
  ];
}

ElementBlueprint _blueprint(String id, String name) {
  return ElementBlueprint(
    id: id,
    name: name,
    description: name,
    extension: "test",
    dataBlueprint: ObjectBlueprint(fields: {}),
    color: Colors.blue,
    icon: Iconoir.add_frame,
  );
}
