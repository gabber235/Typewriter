import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart" as tags_lib;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

final _testTagId = recordId("tag:test_tag");

Tag _testTag({int x = 0, int y = 0}) => Tag(
  tagId: _testTagId,
  name: "Test Tag",
  color: Colors.blue,
  parentIds: const [],
  placement: Placement(x: x, y: y, width: 2, height: 1),
);

void main() {
  group("TagNode - drag and drop", () {
    testWidgets("TagIdentifier implements GraphDragData", (tester) async {
      final tagId = TagIdentifier(_testTagId);

      expect(tagId, isA<GraphDragData>());
      expect(tagId.graphId, equals(const GraphIdentifier("test_tag")));
    });

    testWidgets("TagNode is wrapped in Draggable", (tester) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: _testTagId),
            ),
          ),
        ),
        settle: true,
      );

      final draggableFinder = find.byType(Draggable<TagIdentifier>);
      expect(draggableFinder, findsOneWidget);
    });

    testWidgets("dragging TagNode updates tag position via Graph callback", (
      tester,
    ) async {
      const cell = tagGraphCellSize;

      final tag = _testTag(x: 2, y: 3);

      final updates = <List<(GraphIdentifier, int, int)>>[];
      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("test_tag"),
            x: 2,
            y: 3,
            width: 2,
            height: 1,
            builder: (_) => SizedBox.expand(child: TagNode(tagId: _testTagId)),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: data, onElementsDragged: updates.add),
          ),
        ),
        settle: true,
      );

      final tagFinder = find.byType(TagNode);
      expect(tagFinder, findsOneWidget);

      final start = tester.getCenter(tagFinder);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(cell * 1, cell * 2));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      final last = updates.last;
      expect(last, hasLength(1));
      expect(last.first.$1, const GraphIdentifier("test_tag"));
      expect(last.first.$2, 2 + 1);
      expect(last.first.$3, 3 + 2);
    });

    testWidgets("dragging TagNode inside graph hides feedback widget", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: _testTagId),
            ),
          ),
        ),
        settle: true,
      );

      final tagFinder = find.byType(TagNode);
      final start = tester.getCenter(tagFinder);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(100, 100));
      await tester.pump();

      expect(find.byType(FeedbackTagNode), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("TagNode hides placeholder when dragging inside graph", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      final draggingInsideGraph = ValueNotifier(false);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: GraphDrag(
              draggingInsideGraph: draggingInsideGraph,
              child: TagNode(tagId: _testTagId),
            ),
          ),
        ),
        settle: true,
      );

      final tagFinder = find.byType(TagNode);
      final start = tester.getCenter(tagFinder);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(draggingInsideGraph.value, isTrue);
      expect(find.byType(PlaceholderTagNode), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("dragging TagNode outside graph shows feedback widget", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: TagNode(tagId: _testTagId),
          ),
        ),
        settle: true,
      );

      final tagFinder = find.byType(TagNode);
      final start = tester.getCenter(tagFinder);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(100, 100));
      await tester.pump();

      expect(find.byType(FeedbackTagNode), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("dragging TagNode outside graph shows placeholder widget", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: TagNode(tagId: _testTagId),
          ),
        ),
        settle: true,
      );

      final tagFinder = find.byType(TagNode);
      final start = tester.getCenter(tagFinder);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveBy(const Offset(50, 50));
      await tester.pump();

      expect(find.byType(PlaceholderTagNode), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("TagNode has DragTarget for drop-on-tag functionality", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider(_testTagId).overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: _testTagId),
            ),
          ),
        ),
        settle: true,
      );

      final dragTargetFinder = find.byType(DragTarget<TagIdentifier>);
      expect(dragTargetFinder, findsOneWidget);
    });
  });
}
