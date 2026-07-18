import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/iconoir.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/element_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/entries.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/application/page_elements.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/dynamic_data.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/selection.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/application/scene.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/scene/presentation/scene.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/timeline/presentation/timeline.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

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

      expect(notifier.updateCalls, [
        const [("child", 6, 16)],
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
        const [("child", 5, 16)],
      ]);
      expect(notifier.updateCalls, isEmpty);
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
        const [("child", 6, 15)],
      ]);
      expect(notifier.updateCalls, isEmpty);
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

      expect(notifier.updateCalls, [
        const [("root", 11, 31)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets(
      "commits root start-handle resize with nested descendants without containment assertion",
      (tester) async {
        final notifier = _TestPageElements(_nestedRootResizeSceneElements());

        await tester.pumpTestApp(
          overrides: [
            pageElementsProvider("page").overrideWith(() => notifier),
          ],
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
        final rect = tester.getRect(surfaceFinder);

        await tester.dragFrom(
          rect.centerLeft + const Offset(2, 0),
          const Offset(400, 0),
        );
        await tester.pumpAndSettle();

        expect(notifier.resizeCalls, [
          const [("root", 15, 30)],
        ]);
        expect(notifier.updateCalls, isEmpty);
      },
    );

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

      expect(notifier.updateCalls.length, 1);
      expect(notifier.updateCalls.single, const [("child", 6, 16)]);
      expect(
        notifier.updateCalls.single.any((change) => change.$1 == "sibling"),
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

      expect(notifier.updateCalls, [
        const [("root_a", 12, 32), ("root_b", 42, 52)],
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

      expect(notifier.updateCalls, [
        const [("root_a", 12, 32)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });

    testWidgets("resizes both adjacent roots when dragging shared boundary", (
      tester,
    ) async {
      final notifier = _TestPageElements(_adjacentRootSceneElements());

      await tester.pumpTestApp(
        overrides: [pageElementsProvider("page").overrideWith(() => notifier)],
        child: const SizedBox(
          width: 1600,
          height: 900,
          child: Material(child: EntryScene(pageId: "page")),
        ),
      );

      final leftSurfaceFinder = find.ancestor(
        of: find.text("Root Left"),
        matching: find.byType(TimelineSegmentSurface),
      );
      final rightSurfaceFinder = find.ancestor(
        of: find.text("Root Right"),
        matching: find.byType(TimelineSegmentSurface),
      );

      final leftRect = tester.getRect(leftSurfaceFinder);
      final rightRect = tester.getRect(rightSurfaceFinder);
      final boundaryPoint = Offset(
        (leftRect.right + rightRect.left) / 2,
        leftRect.center.dy,
      );

      await tester.dragFrom(boundaryPoint, const Offset(60, 0));
      await tester.pumpAndSettle();

      expect(notifier.resizeCalls, isEmpty);
      expect(notifier.updateCalls, hasLength(1));
      final changed = notifier.updateCalls.single;
      expect(changed, hasLength(2));
      expect(changed, contains(const ("root_left", 10, 32)));
      expect(changed, contains(const ("root_right", 33, 50)));
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

      expect(notifier.updateCalls, [
        const [("root", 11, 31), ("child", 6, 16)],
      ]);
      expect(notifier.resizeCalls, isEmpty);
    });
  });
}

class _TestPageElements extends PageElements {
  _TestPageElements(this.initialElements);

  final List<PageElement> initialElements;
  final List<List<(String, int, int)>> updateCalls = [];
  final List<List<(String, int, int)>> resizeCalls = [];

  @override
  Future<List<PageElement>> build(String pageId) async => initialElements;

  @override
  Future<void> updateCues(List<(String, int, int)> changed) async {
    final hasResize = _hasResizeChanges(state.requireValue, changed);
    if (hasResize) {
      resizeCalls.add(changed);
    } else {
      updateCalls.add(changed);
    }
    optimisticCuesUpdate(changed);
  }

  bool _hasResizeChanges(
    List<PageElement> elements,
    List<(String, int, int)> changed,
  ) {
    if (changed.length != 1) return false;
    final change = changed.first;
    final currentElement = elements.where((element) => element.id == change.$1);
    if (currentElement.isEmpty) return false;
    final current = currentElement.first;

    if (current case PageElementCue(cue: final cue)) {
      if (cue is! Segment) return false;
      final startDelta = change.$2 - cue.startFrame;
      final endDelta = change.$3 - cue.endFrame;
      return startDelta != endDelta;
    }

    return false;
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

List<PageElement> _nestedRootResizeSceneElements() {
  return [
    PageElement.entry(
      entry: PageEntry.definition(
        definition: EntryDefinition(
          id: "entry",
          name: "Nested Scene Entry",
          blueprint: _blueprint("entry_blueprint", "Nested Scene Entry"),
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

List<PageElement> _adjacentRootSceneElements() {
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
              linkId: "entry_root_left",
              otherId: "root_left",
              path: "children",
            ),
            const ElementLink(
              linkId: "entry_root_right",
              otherId: "root_right",
              path: "children",
            ),
          ],
        ),
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_left",
        startFrame: 10,
        endFrame: 30,
        blueprint: _blueprint("root_left_blueprint", "Root Left"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_left",
            otherId: "entry",
            path: "parent",
          ),
        ],
        outwardLinks: const [],
      ),
    ),
    PageElement.cue(
      cue: Cue.segment(
        id: "root_right",
        startFrame: 31,
        endFrame: 50,
        blueprint: _blueprint("root_right_blueprint", "Root Right"),
        data: const DynamicData({}),
        inwardLinks: [
          const ElementLink(
            linkId: "entry_root_right",
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
