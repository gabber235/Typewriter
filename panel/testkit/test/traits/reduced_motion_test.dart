import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

final _probe = PanelLocation.component(
  Builder(
    builder: (context) => Text(
      MediaQuery.disableAnimationsOf(context)
          ? "Reduced motion"
          : "Full motion",
    ),
  ),
);

void main() {
  testWidgets("a panel for a user who asked for reduced motion reduces it", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([reducedMotion], at: _probe);

    expect(panel.shows("Reduced motion"), isTrue);
  });

  testWidgets("a panel without the trait keeps full motion", (tester) async {
    final panel = await tester.pumpPanel(const [], at: _probe);

    expect(panel.shows("Full motion"), isTrue);
  });

  test("reduced motion combines with a window and the dark theme", () {
    expect(() => World.build([reducedMotion, compact, dark]), returnsNormally);
  });
}
