import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the last row of a loaded pane starts within 150 ms", (
    tester,
  ) async {
    final panel = await tester.mountComponent(const EnterStage(rows: 12));
    expect(panel.opacityOf("row 12"), 0);
    await tester.runFrames(const Duration(milliseconds: 140));
    expect(panel.opacityOf("row 12"), 0);
    await tester.runFrames(const Duration(milliseconds: 60));
    expect(panel.opacityOf("row 12"), greaterThan(0));
  });

  testWidgets("rows load in visual order", (tester) async {
    final panel = await tester.mountComponent(const EnterOrderStage());
    await tester.runFrames(const Duration(milliseconds: 100));
    expect(panel.opacityOf("high"), greaterThan(0));
    expect(panel.opacityOf("low"), 0);
  });

  testWidgets("one group takes one slot", (tester) async {
    final panel = await tester.mountComponent(const EnterGroupStage());
    await tester.runFrames(const Duration(milliseconds: 140));
    for (final cell in ["row 1 name", "row 1 role"]) {
      expect(panel.opacityOf(cell), greaterThan(0), reason: cell);
    }
    for (final cell in ["row 2 name", "row 2 role"]) {
      expect(panel.opacityOf(cell), 0, reason: cell);
    }
    await panel.settle();
    expect(panel.opacityOf("row 2 role"), 1);
  });

  testWidgets("an Enter that joins later shows at once", (tester) async {
    final panel = await tester.mountComponent(const EnterStage(rows: 1));
    await tester.runFrames(const Duration(milliseconds: 32));
    await tester.showComponent(const EnterStage(rows: 2), settle: false);
    expect(panel.opacityOf("row 2"), 1);
    final shown = panel.boundsOf("row 2");
    await panel.settle();
    expect(panel.boundsOf("row 2"), shown);
  });

  testWidgets("a new row slides in from the left", (tester) async {
    final panel = await tester.mountComponent(
      const EnterStage(token: MotionToken.rowIn),
    );
    final arriving = tester.getRect(panel.box("row 1")).left;
    await panel.settle();
    expect(arriving, lessThan(tester.getRect(panel.box("row 1")).left));
    expect(panel.opacityOf("row 1"), 1);
  });

  testWidgets("reduced motion: rows appear in place", (tester) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(child: EnterStage(rows: 3)),
    );
    expect(panel.opacityOf("row 3"), 1);
    final shown = panel.boundsOf("row 3");
    await panel.settle();
    expect(panel.boundsOf("row 3"), shown);
  });

  testWidgets("without a run a loadIn row shows at once", (tester) async {
    final panel = await tester.mountComponent(const EnterStage(run: false));
    expect(panel.opacityOf("row 1"), 1);
    final shown = panel.boundsOf("row 1");
    await panel.settle();
    expect(panel.boundsOf("row 1"), shown);
  });

  testWidgets("a driven Enter paints its progress", (tester) async {
    final from = (await resolveMotionIn(
      tester,
      MotionToken.rowIn,
    )).landing.from;
    final panel = await tester.mountComponent(const EnterStage(run: false));
    final place = panel.boundsOf("row 1").topLeft;
    await tester.showComponent(
      const EnterStage(
        token: MotionToken.rowIn,
        progress: 0.5,
        key: ValueKey("driven"),
      ),
    );
    expect(panel.boundsOf("row 1").topLeft, place + from * 0.5);
    expect(panel.opacityOf("row 1"), 0.5);
  });
}
