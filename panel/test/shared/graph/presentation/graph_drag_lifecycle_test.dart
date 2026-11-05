import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("stationary pointer follows viewport resize and layout shift", (
    tester,
  ) async {
    final width = ValueNotifier(500.0);
    final left = ValueNotifier(0.0);
    addTearDown(width.dispose);
    addTearDown(left.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        HookBuilder(
          builder: (context) {
            useListenable(width);
            useListenable(left);
            return Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.only(left: left.value),
                child: SizedBox(
                  width: width.value,
                  height: 300,
                  child: Graph(
                    data: GraphData(
                      cellSize: 50,
                      elements: [
                        graphNode(
                          "same",
                          body: const DraggableGraphNode("Source", id: "same"),
                        ),
                      ],
                      edges: const [],
                    ),
                    onElementsMoved: (_) {},
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final gesture = await panel.graph.grab("Source");
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    final controller = tester
        .widget<GraphDrag>(find.byType(GraphDrag))
        .controller;
    final position = controller.value!.globalPosition;
    expect(controller.value?.inside, isTrue);
    expect(panel.labeled("Dragging Source"), findsNothing);

    width.value = 100;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.globalPosition, position);
    expect(controller.value?.inside, isFalse);
    expect(panel.labeled("Dragging Source"), findsOneWidget);

    width.value = 500;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.inside, isTrue);
    left.value = position.dx + 20;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.inside, isFalse);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final cancelOld in [false, true]) {
    testWidgets(
      "same ID avatar cannot change replacement movement with old cancel $cancelOld",
      (tester) async {
        final generation = ValueNotifier(0);
        addTearDown(generation.dispose);
        final moves = <List<GraphMoveCommitPayload>>[];
        final panel = await tester.pumpPanel(
          const [],
          at: PanelLocation.component(
            SizedBox(
              width: 600,
              height: 400,
              child: Graph(
                data: GraphData(
                  cellSize: 50,
                  elements: [
                    graphNode(
                      "same",
                      body: ValueListenableBuilder<int>(
                        valueListenable: generation,
                        builder: (_, value, _) => DraggableGraphNode(
                          "Source",
                          id: "same",
                          key: ValueKey(value),
                        ),
                      ),
                    ),
                  ],
                  edges: const [],
                ),
                onElementsMoved: moves.add,
              ),
            ),
          ),
        );
        final oldGesture = await panel.graph.grab("Source", pointer: 1);
        await oldGesture.moveBy(const Offset(25, 0));
        await tester.pump();
        final controller = tester
            .widget<GraphDrag>(find.byType(GraphDrag))
            .controller;
        final old = controller.value!.payload;
        generation.value++;
        await tester.pump();
        await tester.pump();
        expect(old.phase, GraphDragPhase.retired);

        final newGesture = await panel.graph.grab("Source", pointer: 2);
        await newGesture.moveBy(const Offset(25, 0));
        await tester.pump();
        await newGesture.moveBy(const Offset(50, 0));
        await tester.pump();
        final replacement = controller.value!.payload;
        expect(replacement.value.graphId, old.value.graphId);
        expect(replacement, isNot(same(old)));
        final position = controller.value!.globalPosition;
        final preview = controller.preview(50);

        await oldGesture.moveTo(const Offset(790, 590));
        await tester.pump();
        await oldGesture.moveTo(position);
        await tester.pump();
        if (cancelOld) {
          await oldGesture.cancel();
        } else {
          await oldGesture.up();
        }
        await tester.pump();
        expect(moves, isEmpty);
        expect(controller.value!.payload, same(replacement));
        expect(controller.value!.globalPosition, position);
        expect(controller.preview(50), preview);
        await newGesture.up();
        await tester.pumpAndSettle();
        expect(moves, hasLength(1));
        expect(moves.single.single.id, const GraphIdentifier("same"));
        expect(controller.value, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    "source rebuild preserves the avatar snapshot until its next gesture",
    (tester) async {
      final revision = ValueNotifier(0);
      addTearDown(revision.dispose);
      final payloads = <GraphDragPayload<TestGraphDragData>>[];
      final panel = await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          SizedBox(
            width: 150,
            height: 100,
            child: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, value, _) => DraggableGraphNode(
                "Source",
                id: "same",
                revision: value,
                onOffered: payloads.add,
              ),
            ),
          ),
        ),
      );
      final first = await panel.graph.grab("Source");
      await first.moveBy(const Offset(25, 0));
      await tester.pump();
      final active = payloads.last;
      revision.value = 1;
      await tester.pump();
      expect(payloads.last, same(active));
      expect(active.value.revision, 0);
      await first.up();
      await tester.pumpAndSettle();
      expect(payloads.last, isNot(same(active)));
      expect(payloads.last.value.revision, 1);
      expect(active.phase, GraphDragPhase.retired);
    },
  );
}
