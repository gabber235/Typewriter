import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

void main() {
  group("ResizableElement", () {
    const testElementId = GraphIdentifier("test-element");
    late GraphElement testElement;

    const handleSize = 30.0;
    const cellSize = 40.0;
    late Size childSize;

    setUp(() {
      testElement = GraphElement(
        id: testElementId,
        x: 0,
        y: 0,
        width: 2,
        height: 3,
        builder: (context) => SizedBox(),
      );

      childSize = Size(
        testElement.width * cellSize,
        testElement.height * cellSize,
      );
    });

    testWidgets("renders child and adopts its size", (tester) async {
      await tester.pumpTestApp(
        child: ResizableElement(
          element: testElement,
          onResizeStart: null,
          onResizeUpdate: null,
          onResizeEnd: null,
          cellSize: cellSize,
          child: Container(
            width: childSize.width,
            height: childSize.height,
            color: Colors.blue,
          ),
        ),
      );

      final resizableFinder = find.byType(ResizableElement);
      expect(resizableFinder, findsOneWidget);

      final gestureDetectorFinder = find.byType(GestureDetector);
      expect(gestureDetectorFinder, findsOneWidget);

      final resizableRenderBox =
          tester.renderObject(resizableFinder) as RenderBox;
      expect(resizableRenderBox.size, equals(childSize));
    });

    testWidgets("positions gesture detector handle in bottom-right corner", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: ResizableElement(
          element: testElement,
          onResizeStart: null,
          onResizeUpdate: null,
          onResizeEnd: null,
          cellSize: cellSize,
          handleSize: handleSize,
          child: Container(
            width: childSize.width,
            height: childSize.height,
            color: Colors.blue,
          ),
        ),
      );

      final resizableFinder = find.byType(ResizableElement);
      expect(resizableFinder, findsOneWidget);

      final resizableRenderBox =
          tester.renderObject(resizableFinder) as RenderBox;
      expect(resizableRenderBox.size, equals(childSize));

      final handleFinder = find.byType(GestureDetector);
      expect(handleFinder, findsOneWidget);

      final handleRenderObject = tester.renderObject(handleFinder) as RenderBox;

      expect(handleRenderObject.size, equals(Size(handleSize, handleSize)));

      final resizableOffset = resizableRenderBox.localToGlobal(Offset.zero);

      expect(
        handleRenderObject.localToGlobal(Offset.zero),
        equals(
          resizableOffset +
              Offset(childSize.width, childSize.height) -
              Offset(handleSize / 2, handleSize / 2),
        ),
      );
    });

    testWidgets("invokes callbacks when gesture detector is used", (
      tester,
    ) async {
      final resizeStartCalls = <(GraphIdentifier, int, int)>[];
      final resizeUpdateCalls = <(GraphIdentifier, int, int)>{};
      final resizeEndCalls = <(GraphIdentifier, int, int)>[];

      await tester.pumpTestApp(
        child: ResizableElement(
          element: testElement,
          onResizeStart: (id, deltaX, deltaY) =>
              resizeStartCalls.add((id, deltaX, deltaY)),
          onResizeUpdate: (id, deltaX, deltaY) =>
              resizeUpdateCalls.add((id, deltaX, deltaY)),
          onResizeEnd: (id, deltaX, deltaY) =>
              resizeEndCalls.add((id, deltaX, deltaY)),
          cellSize: cellSize,
          handleSize: handleSize,
          child: Container(
            width: childSize.width,
            height: childSize.height,
            color: Colors.blue,
          ),
        ),
      );

      final handleFinder = find.byType(GestureDetector);
      expect(handleFinder, findsOneWidget);

      await tester.drag(handleFinder, const Offset(cellSize * 4, cellSize * 2));

      expect(resizeStartCalls, hasLength(1));
      expect(
        resizeStartCalls.first,
        equals((testElementId, testElement.width, testElement.height)),
      );

      expect(resizeUpdateCalls, isNotEmpty);
      var lastWidth = testElement.width;
      var lastHeight = testElement.height;
      for (final (id, width, height) in resizeUpdateCalls) {
        expect(id, equals(testElementId));
        expect(width, greaterThanOrEqualTo(lastWidth));
        expect(height, greaterThanOrEqualTo(lastHeight));
        lastWidth = width;
        lastHeight = height;
      }

      expect(resizeEndCalls, hasLength(1));
      expect(
        resizeEndCalls.first,
        equals((testElementId, testElement.width + 4, testElement.height + 2)),
      );
    });

    testWidgets("element size never gets below 1", (tester) async {
      final resizeStartCalls = <(GraphIdentifier, int, int)>[];
      final resizeUpdateCalls = <(GraphIdentifier, int, int)>{};
      final resizeEndCalls = <(GraphIdentifier, int, int)>[];

      await tester.pumpTestApp(
        child: ResizableElement(
          element: testElement,
          onResizeStart: (id, deltaX, deltaY) =>
              resizeStartCalls.add((id, deltaX, deltaY)),
          onResizeUpdate: (id, deltaX, deltaY) =>
              resizeUpdateCalls.add((id, deltaX, deltaY)),
          onResizeEnd: (id, deltaX, deltaY) =>
              resizeEndCalls.add((id, deltaX, deltaY)),
          cellSize: cellSize,
          handleSize: handleSize,
          child: Container(
            width: childSize.width,
            height: childSize.height,
            color: Colors.blue,
          ),
        ),
      );

      final handleFinder = find.byType(GestureDetector);
      expect(handleFinder, findsOneWidget);

      await tester.drag(
        handleFinder,
        const Offset(-cellSize * 1000, -cellSize * 1000),
      );

      expect(resizeStartCalls, hasLength(1));
      expect(
        resizeStartCalls.first,
        equals((testElementId, testElement.width, testElement.height)),
      );

      for (final (id, deltaX, deltaY) in resizeUpdateCalls) {
        expect(id, testElementId);
        expect(deltaX, greaterThanOrEqualTo(1));
        expect(deltaY, greaterThanOrEqualTo(1));
      }

      expect(resizeEndCalls, hasLength(1));
      expect(resizeEndCalls.first, equals((testElementId, 1, 1)));
    });

    testWidgets("uses custom handle size when provided", (tester) async {
      const customHandleSize = 50.0;

      await tester.pumpTestApp(
        child: ResizableElement(
          element: testElement,
          onResizeStart: null,
          onResizeUpdate: null,
          onResizeEnd: null,
          cellSize: cellSize,
          handleSize: customHandleSize,
          child: Container(
            width: childSize.width,
            height: childSize.height,
            color: Colors.blue,
          ),
        ),
      );

      final handleFinder = find.byType(GestureDetector);
      expect(handleFinder, findsOneWidget);

      final handleRenderObject = tester.renderObject(handleFinder) as RenderBox;

      expect(
        handleRenderObject.size,
        equals(Size(customHandleSize, customHandleSize)),
      );
    });
  });
}
