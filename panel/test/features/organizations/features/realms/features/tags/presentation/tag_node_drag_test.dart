import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

final _testTagId = skir.ResourceId(value: "test_tag");
final _testScope = AuthoringScope(
  organizationId: skir.recordId("organization:fixture"),
  realmId: skir.recordId("realm:fixture"),
);
Tag _testTag({int x = 0, int y = 0}) => Tag(
  tagId: _testTagId,
  name: "Test Tag",
  color: Colors.blue,
  parentIds: const [],
  placement: GraphPlacement(x: x, y: y, width: 2, height: 1),
);

void main() {
  group("TagNode drag and drop", () {
    testWidgets("retains selector and focus while tag refreshes", (
      tester,
    ) async {
      final tag = _testTag();
      final transport = ScriptedAuthoringTransport(
        AsyncData(fixtureAuthoringDocument(tags: [tag])),
      );
      addTearDown(transport.dispose);

      await tester.pumpTestApp(
        settle: false,
        overrides: [...authoringFixtureOverrides(transport: transport)],
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
      );
      await tester.pumpAndSettle();

      final focusNode = tester.widget<Selector>(find.byType(Selector)).focusNode
        ..requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(focusNode));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(TagNode)),
      );
      transport.publish(const AsyncLoading());
      await tester.pump();
      expect(
        container.read(workingTagProvider(_testTagId)).requireValue!.name,
        tag.name,
      );

      expect(find.byType(Selector), findsOneWidget);
      expect(FocusManager.instance.primaryFocus, same(focusNode));

      transport.publish(
        AsyncData(
          fixtureAuthoringDocument(tags: [tag.copyWith(name: "Refreshed")]),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets("scoped authored identity implements GraphDragData", (
      tester,
    ) async {
      final tagId = AuthoringResourceIdentifier.inScope(_testScope, _testTagId);

      expect(tagId, isA<GraphDragData>());
      expect(tagId.graphId, equals(const GraphIdentifier("test_tag")));
    });

    testWidgets("TagNode is wrapped in Draggable", (tester) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          ...authoringFixtureOverrides(tags: [tag]),
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

      final draggableFinder = find.byType(
        Draggable<AuthoringResourceIdentifier>,
      );
      expect(draggableFinder, findsOneWidget);
    });

    testWidgets("dragging TagNode updates tag position via Graph callback", (
      tester,
    ) async {
      const cell = tagGraphCellSize;

      final tag = _testTag(x: 2, y: 3);

      final updates = <List<GraphMoveCommitPayload>>[];
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
          ...authoringFixtureOverrides(tags: [tag]),
        ],
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: data, onElementsMoved: updates.add),
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
      expect(last.first.id, const GraphIdentifier("test_tag"));
      expect(last.first.x, 2 + 1);
      expect(last.first.y, 3 + 2);
    });

    testWidgets("dragging TagNode inside graph hides feedback widget", (
      tester,
    ) async {
      final tag = _testTag(x: 0, y: 0);

      await tester.pumpTestApp(
        overrides: [
          ...authoringFixtureOverrides(tags: [tag]),
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
          ...authoringFixtureOverrides(tags: [tag]),
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
          ...authoringFixtureOverrides(tags: [tag]),
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
          ...authoringFixtureOverrides(tags: [tag]),
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
          ...authoringFixtureOverrides(tags: [tag]),
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

      final dragTargetFinder = find.byType(
        DragTarget<AuthoringResourceIdentifier>,
      );
      expect(dragTargetFinder, findsOneWidget);
    });
  });
}
