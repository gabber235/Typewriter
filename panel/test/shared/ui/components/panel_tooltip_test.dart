import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("reduced motion: a tooltip appears at once", (tester) async {
    await tester.pumpPanel(const [
      reducedMotion,
    ], at: const PanelLocation.component(Center(child: deletePageTooltip)));
    final first = await tester.firstFrameOfTooltip(
      "Delete the page",
      find.byIcon(Icons.delete),
    );
    await tester.pumpAndSettle();

    expect(first, tester.getRect(find.text("Delete the page")));
  });

  testWidgets("a tooltip grows in from smaller", (tester) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(Center(child: deletePageTooltip)),
    );
    final first = await tester.firstFrameOfTooltip(
      "Delete the page",
      find.byIcon(Icons.delete),
    );
    await tester.pumpAndSettle();

    expect(
      first.width,
      lessThan(tester.getRect(find.text("Delete the page")).width),
    );
  });
}
