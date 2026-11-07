import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a jump token samples to no time under reduced motion", (
    tester,
  ) async {
    final timeline = await readInMotionTheme(
      tester,
      (context) => motionTimeline(context, MotionToken.surfaceIn),
      reduced: true,
    );
    expect(timeline.duration, Duration.zero);
  });

  testWidgets("leaving is faster than arriving", (tester) async {
    final arrive = await readInMotionTheme(
      tester,
      (context) => motionTimeline(context, MotionToken.panelIn),
    );
    final leave = await readInMotionTheme(
      tester,
      (context) => motionTimeline(context, MotionToken.panelOut),
    );
    expect(leave.duration, lessThan(arrive.duration));
  });

  testWidgets("a strike timeline overshoots and lands on its target", (
    tester,
  ) async {
    final timeline = await readInMotionTheme(
      tester,
      (context) => motionTimeline(context, MotionToken.panelIn),
    );
    expect(curveSamples(timeline.curve.transform).reduce(max), greaterThan(1));
    expect(timeline.curve.transform(1), 1);
  });
}
