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

    expect(panel.shows("TEST DISPLAY"), isFalse);
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

    expect(panel.shows("TEST DISPLAY"), isTrue);
  });

  testWidgets("leaving a mode with a display removes its indicator", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(DisplayTestMode());
    expect(panel.shows("TEST DISPLAY"), isTrue);

    await panel.enterMode(PlainTestMode());

    expect(panel.shows("TEST DISPLAY"), isFalse);
  });

  testWidgets("an active mode's chip adds its icon and a bolder fill than the "
      "resting chip", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(SoftDisplayTestMode());
    await panel.settle();
    final resting = tester.modeChipFill;
    expect(
      find.descendant(of: find.byType(ModeChip), matching: find.byType(Icon)),
      findsNothing,
    );

    await panel.enterMode(DisplayTestMode());
    await panel.settle();

    expect(
      find.descendant(
        of: find.byType(ModeChip),
        matching: find.byIcon(Icons.open_with_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.modeChipFill.a, greaterThan(resting.a));
  });

  testWidgets("the chip keeps its height while its label changes", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(SoftDisplayTestMode());
    await panel.settle();
    final height = tester.getSize(find.byType(ModeChip)).height;

    panel.container
        .read(currentInteractionModeProvider.notifier)
        .setMode(DisplayTestMode());
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.getSize(find.byType(ModeChip)).height, height);
    }
  });

  testWidgets("the fill starts changing in the first frame of a switch and "
      "lands on the new mode's fill", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(ModeDisplayWidget()),
    );
    await panel.enterMode(SoftDisplayTestMode());
    await panel.settle();
    final resting = tester.modeChipFill;

    panel.container
        .read(currentInteractionModeProvider.notifier)
        .setMode(DisplayTestMode());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final early = tester.modeChipFill;
    expect(early, isNot(resting));
    await panel.settle();
    expect(tester.modeChipFill, isNot(early));
    expect(
      tester.modeChipFill.toARGB32(),
      DisplayTestMode()
          .look(tester.element(find.byType(ModeChip)))
          .tone
          .toARGB32(),
    );
  });
}
