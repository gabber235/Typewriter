import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

GraphElement _element(
  String id, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  return GraphElement(
    id: GraphIdentifier(id),
    x: x,
    y: y,
    width: width,
    height: height,
    builder: (_) => const SizedBox(),
  );
}

void main() {
  group("GraphInteractionController", () {
    test("disposal during notification defers final cleanup until listeners return", () async {
      final payload = GraphDragPayload(
        value: const _TestDragData(GraphIdentifier("same")),
      );
      final retired = Completer<void>();
      final phases = <GraphDragPhase>[];
      void observe() {
        phases.add(payload.phase);
        if (payload.isDragging) {
          payload.dispose();
        } else if (payload.phase == GraphDragPhase.retired) {
          retired.complete();
        }
      }

      payload
        ..addListener(observe)
        ..start();
      await retired.future;
      expect(phases, [GraphDragPhase.dragging, GraphDragPhase.retired]);
      expect(payload.canHover, isFalse);
      expect(payload.value.graphId, const GraphIdentifier("same"));
      payload
        ..removeListener(observe)
        ..addListener(() => fail("A retired avatar cannot subscribe again"))
        ..retire()
        ..dispose();
      expect(payload.start(), isFalse);
      expect(payload.claim(), isFalse);
    });

    test("same ID replacement ignores old movement and completion", () {
      final controller = GraphInteractionController();
      addTearDown(controller.dispose);
      GraphDragPayload<GraphDragData> offer() =>
          GraphDragPayload(value: const _TestDragData(GraphIdentifier("same")))
            ..start();
      final old = offer();
      final replacement = offer();
      controller
        ..beginDrag(old, Offset.zero, inside: true)
        ..beginDrag(replacement, const Offset(40, 50), inside: true);
      final data = GraphData(
        cellSize: 50,
        elements: [_element("same", x: 1, y: 1, width: 2, height: 2)],
        edges: const [],
      );
      controller
        ..beginMove(
          data: data,
          origin: replacement.value.graphId,
          selectedIds: const {},
        )
        ..updateMove(const Offset(50, 0));
      expect(old.claim(), isFalse);
      controller
        ..updateDrag(old, Offset.zero, inside: false)
        ..endDrag(old);
      expect(controller.value?.payload, same(replacement));
      expect(controller.value?.globalPosition, const Offset(40, 50));
      expect(controller.preview(50).moveDelta, (1, 0));
      expect(controller.ownsDrag(replacement), isTrue);
    });

    test("movement cancellation preserves physical containment", () {
      final controller = GraphInteractionController();
      addTearDown(controller.dispose);
      final payload = GraphDragPayload(
        value: const _TestDragData(GraphIdentifier("same")),
      )..start();
      controller
        ..beginDrag(payload, const Offset(20, 30), inside: true)
        ..cancelMove();
      expect(controller.value?.inside, isTrue);
      controller.refreshDragContainment((position) => position.dx < 10);
      expect(controller.value?.globalPosition, const Offset(20, 30));
      expect(controller.value?.inside, isFalse);
    });

    test("closure retires authority and blocks late writes", () {
      final controller = GraphInteractionController();
      final payload = GraphDragPayload(
        value: const _TestDragData(GraphIdentifier("same")),
      )..start();
      controller
        ..beginDrag(payload, Offset.zero, inside: true)
        ..close();
      final replacement = GraphDragPayload(value: payload.value)..start();
      addTearDown(replacement.retire);
      expect(payload.canHover, isFalse);
      expect(controller.value, isNull);
      expect(
        controller.beginDrag(replacement, Offset.zero, inside: true),
        isFalse,
      );
      controller
        ..dispose()
        ..updateDrag(payload, const Offset(4, 5), inside: false)
        ..endDrag(payload)
        ..beginResize(const GraphIdentifier("same"), 4, 5);
      expect(controller.resize, isNull);
    });

    test(
      "retirement notifies surviving targets after synchronous disposal",
      () async {
        final payload = GraphDragPayload(
          value: const _TestDragData(GraphIdentifier("same")),
        );
        final observations = <GraphDragPhase>[];
        payload.addListener(() => observations.add(payload.phase));
        expect(payload.canHover, isTrue);
        expect(payload.claim(), isFalse);
        expect(payload.start(), isTrue);
        expect(payload.claim(), isTrue);
        expect(payload.claim(), isFalse);
        final accepted = payload.value;
        payload.retire();
        expect(payload.canHover, isFalse);
        expect(observations, isEmpty);
        await Future<void>.value();
        expect(observations, [GraphDragPhase.retired]);
        expect(accepted.graphId, const GraphIdentifier("same"));
        payload
          ..addListener(() => fail("A retired payload cannot notify again"))
          ..dispose();
        expect(payload.start(), isFalse);
      },
    );

    test("moves a group and its contained elements with grid snapping", () {
      final controller = GraphInteractionController();
      final data = GraphData(
        cellSize: 50,
        elements: [
          _element("group", x: 1, y: 1, width: 4, height: 4),
          _element("child", x: 2, y: 2, width: 1, height: 1),
          _element("outside", x: 8, y: 8, width: 1, height: 1),
        ],
        edges: const [],
      );

      controller
        ..beginMove(
          data: data,
          origin: const GraphIdentifier("group"),
          selectedIds: const {},
        )
        ..updateMove(const Offset(75, 24));

      expect(controller.preview(data.cellSize).moveDelta, (2, 0));
      expect(controller.finishMove(data), const [
        GraphMoveCommitPayload(id: GraphIdentifier("group"), x: 3, y: 1),
        GraphMoveCommitPayload(id: GraphIdentifier("child"), x: 4, y: 2),
      ]);
      expect(controller.movingIds, isEmpty);
      controller.dispose();
    });

    test("cancels move and resize sessions without payloads", () {
      final controller = GraphInteractionController();
      final data = GraphData(
        cellSize: 50,
        elements: [_element("a", x: 0, y: 0, width: 2, height: 2)],
        edges: const [],
      );

      controller
        ..beginMove(
          data: data,
          origin: const GraphIdentifier("a"),
          selectedIds: const {},
        )
        ..updateMove(const Offset(100, 100))
        ..cancelMove();

      expect(controller.finishMove(data), isEmpty);

      controller
        ..beginResize(const GraphIdentifier("a"), 2, 2)
        ..updateResize(const GraphIdentifier("a"), 4, 3)
        ..cancelResize();

      expect(controller.finishResize(), isNull);
      controller.dispose();
    });

    test("returns typed resize payloads and enforces keyboard minimums", () {
      final controller = GraphInteractionController();
      final data = GraphData(
        cellSize: 50,
        elements: [_element("a", x: 0, y: 0, width: 1, height: 1)],
        edges: const [],
      );

      controller
        ..beginResize(const GraphIdentifier("a"), 1, 1)
        ..updateResize(const GraphIdentifier("a"), 3, 2);

      expect(
        controller.finishResize(),
        const GraphResizeCommitPayload(
          id: GraphIdentifier("a"),
          width: 3,
          height: 2,
        ),
      );
      expect(
        controller.resizeSelection(
          data: data,
          ids: {const GraphIdentifier("a")},
          dw: -1,
          dh: -1,
        ),
        const [
          GraphResizeCommitPayload(
            id: GraphIdentifier("a"),
            width: 1,
            height: 1,
          ),
        ],
      );
      controller.dispose();
    });
  });
}

class _TestDragData extends GraphDragData {
  const _TestDragData(this.graphId);
  @override
  final GraphIdentifier graphId;
}
