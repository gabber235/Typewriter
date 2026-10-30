import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a mode without a display shows no indicator", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );

    await panel.enterMode(PlainTestMode());

    expect(panel.shows("Test Display"), isFalse);
  });

  testWidgets("entering a mode with a display shows its indicator", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(PlainTestMode());

    await panel.enterMode(DisplayTestMode());

    expect(panel.shows("Test Display"), isTrue);
  });

  testWidgets("leaving a mode with a display removes its indicator", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(DisplayTestMode());
    expect(panel.shows("Test Display"), isTrue);

    await panel.enterMode(PlainTestMode());

    expect(panel.shows("Test Display"), isFalse);
  });
}
