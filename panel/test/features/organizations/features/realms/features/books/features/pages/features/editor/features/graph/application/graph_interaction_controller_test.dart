import "package:flutter/material.dart";
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
