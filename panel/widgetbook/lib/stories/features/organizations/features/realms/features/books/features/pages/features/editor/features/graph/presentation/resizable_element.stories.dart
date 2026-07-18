import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_element.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/domain/graph_identifier.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/graph/presentation/resizable_element.dart";
import "package:typewriter_panel/shared/utilities/color.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

@widgetbook.UseCase(
  name: "Default",
  type: ResizableElement,
)
Widget resizableElementDefault(BuildContext context) {
  const cellSize = 40.0;

  return LayoutBuilder(
    builder: (context, constraints) {
      final x = (constraints.maxWidth ~/ cellSize) ~/ 3;
      final y = (constraints.maxHeight ~/ cellSize) ~/ 3;

      return HookBuilder(
        builder: (context) {
          final childWidth = useState(4);
          final childHeight = useState(2);
          final element = GraphElement(
            id: const GraphIdentifier("demo-element"),
            x: x,
            y: y,
            width: childWidth.value,
            height: childHeight.value,
            builder: (context) => DecoratedBox(
              decoration: BoxDecoration(
                color: safeColors[0],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  "Drag the handle\nin the bottom-right corner",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),
          );

          return FakeApp(
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CustomDotPainter(cellSize: cellSize),
                  ),
                ),
                Positioned(
                  top: element.x * cellSize,
                  left: element.y * cellSize,
                  child: ResizableElement(
                    element: element,
                    onResizeStart: (id, width, height) {
                      childWidth.value = width;
                      childHeight.value = height;
                    },
                    onResizeUpdate: (id, width, height) {
                      childWidth.value = width;
                      childHeight.value = height;
                    },
                    onResizeEnd: (id, width, height) {
                      childWidth.value = width;
                      childHeight.value = height;
                    },
                    cellSize: cellSize,
                    child: Container(
                      width: childWidth.value * cellSize,
                      height: childHeight.value * cellSize,
                      decoration: BoxDecoration(
                        color: safeColors[0],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Drag the handle\nin the bottom-right corner",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class CustomDotPainter extends CustomPainter {
  const CustomDotPainter({required this.cellSize});

  final double cellSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    for (var x = 0.0; x < size.width; x += cellSize) {
      for (var y = 0.0; y < size.height; y += cellSize) {
        canvas.drawCircle(
          Offset(x, y),
          2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomDotPainter oldDelegate) =>
      cellSize != oldDelegate.cellSize;
}
