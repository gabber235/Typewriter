import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const handle = "Resize dimension";

void main() {
  testWidgets("dragging right grows the pane by the default resolver", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      ResizablePane(initialSize: 300, minSize: 150, maxSize: 700),
    );
    expect(panel.boundsOf("Pane").width, 300);

    await panel.dragBy(panel.labeled(handle), const Offset(80, 0));

    expect(panel.boundsOf("Pane").width, 380);
  });

  testWidgets("a custom resolver inverts the drag", (tester) async {
    final panel = await tester.showComponent(
      ResizablePane(
        initialSize: 300,
        minSize: 150,
        maxSize: 700,
        resolver: (size, delta) => size - delta,
      ),
    );

    await panel.dragBy(panel.labeled(handle), const Offset(80, 0));

    expect(panel.boundsOf("Pane").width, 220);
  });

  testWidgets("dragging stops at the minimum and maximum size", (tester) async {
    final panel = await tester.showComponent(
      ResizablePane(initialSize: 300, minSize: 200, maxSize: 400),
    );

    await panel.dragBy(panel.labeled(handle), const Offset(500, 0));
    expect(panel.boundsOf("Pane").width, 400);

    await panel.dragBy(panel.labeled(handle), const Offset(-1000, 0));
    expect(panel.boundsOf("Pane").width, 200);
  });

  testWidgets("dragging down grows a vertical pane", (tester) async {
    final panel = await tester.showComponent(
      ResizablePane(
        axis: Axis.vertical,
        initialSize: 200,
        minSize: 100,
        maxSize: 500,
      ),
    );
    expect(panel.boundsOf("Pane").height, 200);

    await panel.dragBy(panel.labeled(handle), const Offset(0, 60));

    expect(panel.boundsOf("Pane").height, 260);
  });

  testWidgets("keyboard and semantic resizing share the bounded operation", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      ResizablePane(initialSize: 300, minSize: 280, maxSize: 312),
    );

    await panel.tapOn(panel.labeled(handle));
    await panel.press(LogicalKeyboardKey.arrowRight);
    expect(panel.boundsOf("Pane").width, 308);
    await panel.press(LogicalKeyboardKey.arrowRight);
    expect(panel.boundsOf("Pane").width, 312);
    await panel.press(LogicalKeyboardKey.home);
    expect(panel.boundsOf("Pane").width, 280);

    tester.semantics.increase(find.semantics.byLabel(handle));
    await panel.settle();
    expect(panel.boundsOf("Pane").width, 288);
  });

  testWidgets("a disabled handle does not resize the pane", (tester) async {
    final panel = await tester.showComponent(
      ResizablePane(
        initialSize: 320,
        minSize: 200,
        maxSize: 600,
        enabled: false,
      ),
    );
    final edge = panel.boundsOf("Pane").centerLeft;

    await tester.dragFrom(edge - const Offset(2, 0), const Offset(80, 0));
    await panel.settle();

    expect(panel.boundsOf("Pane").width, 320);
  });
}
