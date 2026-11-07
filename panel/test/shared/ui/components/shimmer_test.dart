import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("skeleton placeholders sweep while content loads", (
    tester,
  ) async {
    final skeleton = await tester.showSkeleton();
    await tester.pump();
    final first = skeleton.sweep;
    await tester.pump(tester.settleTimeOf(MotionToken.skeleton) ~/ 4);
    expect(skeleton.sweep, isNot(first));
  });

  testWidgets("with reduced motion the placeholders stay still", (
    tester,
  ) async {
    final skeleton = await tester.showSkeleton(reducedMotion: true);
    await tester.pump();
    final first = skeleton.sweep;
    await tester.pump(tester.settleTimeOf(MotionToken.skeleton));
    expect(skeleton.sweep, first);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
