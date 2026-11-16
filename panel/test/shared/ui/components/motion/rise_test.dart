import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("hover lifts the control and leaving lowers it", (tester) async {
    final rise = (await resolveMotionIn(
      tester,
      MotionToken.hoverIn,
    )).landing.rise;
    final panel = await tester.mountComponent(const RiseStage());
    final place = panel.boundsOf("Publish").center;
    await tester.showComponent(const RiseStage(raised: true));
    expect(panel.boundsOf("Publish").center.dy, closeTo(place.dy - rise, 0.01));
    expect(rise, greaterThanOrEqualTo(2));
    await tester.showComponent(const RiseStage());
    expect(panel.boundsOf("Publish").center, place);
  });

  testWidgets("reduced motion: a control brightens instead of rising", (
    tester,
  ) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(child: RiseStage(filled: true)),
    );
    final place = panel.boundsOf("Publish");
    await tester.showComponent(
      const ReducedMotion(child: RiseStage(raised: true, filled: true)),
      settle: false,
    );
    expect(panel.boundsOf("Publish"), place);
    expect(panel.fillBehind("Publish"), RiseStage.fill);
    await tester.showComponent(
      const ReducedMotion(child: RiseStage(filled: true)),
    );
    expect(panel.fillBehind("Publish"), isNot(RiseStage.fill));
  });

  testWidgets("reduced motion: a row shows no hover sign", (tester) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(child: RiseStage()),
    );
    final place = panel.boundsOf("Publish");
    await tester.showComponent(
      const ReducedMotion(child: RiseStage(raised: true)),
      settle: false,
    );
    expect(panel.boundsOf("Publish"), place);
    expect(panel.fillBehind("Publish"), isNot(RiseStage.fill));
  });

  testWidgets("a driven rise follows its progress", (tester) async {
    final rise = (await resolveMotionIn(
      tester,
      MotionToken.hoverIn,
    )).landing.rise;
    final panel = await tester.mountComponent(const RiseStage());
    final place = panel.boundsOf("Publish").center;
    await tester.showComponent(const RiseStage(progress: 0.5));
    expect(
      panel.boundsOf("Publish").center.dy,
      closeTo(place.dy - rise / 2, 0.01),
    );
  });
}
