import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("Publish to Publishing keeps Publish and types only ing", (
    tester,
  ) async {
    final panel = await tester.showComponent(const MotionLabel("Publish"));

    await tester.showComponent(const MotionLabel("Publishing"), settle: false);
    await tester.pump(const Duration(milliseconds: 40));

    expect(tester.visibleText, startsWith("Publish"));
    expect(tester.visibleText.length, lessThan("Publishing".length));
    expect(panel.reads("Publishing"), isTrue);

    await panel.settle();
    expect(tester.visibleText, "Publishing");
  });

  testWidgets("Publishing to Published never hides the shared letters", (
    tester,
  ) async {
    await tester.showComponent(const MotionLabel("Publishing"));
    await tester.showComponent(const MotionLabel("Published"), settle: false);

    for (var frame = 0; frame < 6; frame++) {
      expect(tester.visibleText, startsWith("Publish"));
      await tester.pump(const Duration(milliseconds: 16));
    }
  });

  testWidgets("a rippling word stops moving once it stops rippling", (
    tester,
  ) async {
    await tester.mountComponent(
      const MotionLabel("Publishing", rippling: true),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isTrue);

    final panel = await tester.showComponent(const MotionLabel("Published"));
    await panel.settle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
