import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/generated/models/book.pb.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/logic/tags/tag_selectable.dart";
import "package:typewriter_panel/logic/tags/tags.dart" as tags_lib;
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/graph/tag_graph.dart";
import "package:typewriter_panel/widgets/app/components/tags/tag_node.dart";

import "../../../../test_utils.dart";

void main() {
  group("TagNode - drag and drop", () {
    testWidgets("TagIdentifier implements GraphDragData", (tester) async {
      const tagId = TagIdentifier("test-tag");

      expect(tagId, isA<GraphDragData>());
      expect(tagId.graphId, equals(const GraphIdentifier("test-tag")));
    });

    testWidgets("TagNode is wrapped in Draggable", (tester) async {
      final tag = Tag()
        ..id = "test-tag"
        ..name = "Test Tag"
        ..placement = (Placement()
          ..x = 0
          ..y = 0
          ..width = 2
          ..height = 1);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider("test-tag").overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: "test-tag"),
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

      final tag = Tag()
        ..id = "test-tag"
        ..name = "Test Tag"
        ..placement = (Placement()
          ..x = 2
          ..y = 3
          ..width = 2
          ..height = 1);

      final updates = <List<(GraphIdentifier, int, int)>>[];
      final data = GraphData(
        cellSize: cell,
        elements: [
          GraphElement(
            id: const GraphIdentifier("test-tag"),
            x: 2,
            y: 3,
            width: 2,
            height: 1,
            builder: (_) => SizedBox.expand(child: TagNode(tagId: "test-tag")),
          ),
        ],
        edges: const [],
      );

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider("test-tag").overrideWith((ref) => tag),
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
      expect(last.first.$1, const GraphIdentifier("test-tag"));
      expect(last.first.$2, 2 + 1);
      expect(last.first.$3, 3 + 2);
    });

    testWidgets("dragging TagNode shows feedback widget", (tester) async {
      final tag = Tag()
        ..id = "test-tag"
        ..name = "Test Tag"
        ..placement = (Placement()
          ..x = 0
          ..y = 0
          ..width = 2
          ..height = 1);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider("test-tag").overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: "test-tag"),
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

      expect(find.byType(FeedbackTagNode), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("TagNode shows placeholder when dragging inside graph", (
      tester,
    ) async {
      final tag = Tag()
        ..id = "test-tag"
        ..name = "Test Tag"
        ..placement = (Placement()
          ..x = 0
          ..y = 0
          ..width = 2
          ..height = 1);

      final draggingInsideGraph = ValueNotifier(false);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider("test-tag").overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: GraphDrag(
              draggingInsideGraph: draggingInsideGraph,
              child: TagNode(tagId: "test-tag"),
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
      expect(find.byType(PlaceholderTagNode), findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets("TagNode has DragTarget for drop-on-tag functionality", (
      tester,
    ) async {
      final tag = Tag()
        ..id = "test-tag"
        ..name = "Test Tag"
        ..placement = (Placement()
          ..x = 0
          ..y = 0
          ..width = 2
          ..height = 1);

      await tester.pumpTestApp(
        overrides: [
          tags_lib.tagProvider("test-tag").overrideWith((ref) => tag),
        ],
        child: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: GraphDrag(
              draggingInsideGraph: ValueNotifier(false),
              child: TagNode(tagId: "test-tag"),
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
