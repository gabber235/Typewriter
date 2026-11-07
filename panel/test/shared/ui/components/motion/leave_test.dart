import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a leaving row squashes shut and its neighbour closes the gap", (
    tester,
  ) async {
    final leave = (await resolveMotionIn(
      tester,
      MotionToken.listOut,
    )).motion.duration;
    final panel = await tester.mountComponent(const LeaveStage(leaving: false));
    final ada = panel.boundsOf("Ada").top;
    final ben = panel.boundsOf("Ben").top;
    await tester.showComponent(const LeaveStage(leaving: true), settle: false);
    await tester.runFrames(leave ~/ 5);
    expect(panel.boundsOf("Ben").top, allOf(greaterThan(ada), lessThan(ben)));
    expect(panel.opacityOf("Ada"), allOf(greaterThan(0), lessThan(1)));
    await panel.settle();
    expect(panel.boundsOf("Ben").top, ada);
  });

  testWidgets("a return before it is shut reopens from where it is", (
    tester,
  ) async {
    final panel = await tester.mountComponent(const LeaveStage(leaving: false));
    final height = panel.boundsOf("Ada").height;
    await tester.showComponent(const LeaveStage(leaving: true), settle: false);
    await tester.runFrames(const Duration(milliseconds: 50));
    await tester.showComponent(const LeaveStage(leaving: false));
    expect(panel.boundsOf("Ada").height, height);
    expect(panel.opacityOf("Ada"), 1);
  });

  testWidgets("reduced motion: the row closes at once", (tester) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(child: LeaveStage(leaving: false)),
    );
    final ada = panel.boundsOf("Ada").top;
    await tester.showComponent(
      const ReducedMotion(child: LeaveStage(leaving: true)),
      settle: false,
    );
    await tester.pump();
    expect(panel.boundsOf("Ben").top, ada);
  });
}
