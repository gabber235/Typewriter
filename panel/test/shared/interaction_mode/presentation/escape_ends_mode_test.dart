import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("Escape on a focused page item ends the mode", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [const ModeDisplayWidget(), const FocusableTarget()],
        ),
      ),
    );
    await panel.item("Target").select();
    await panel.enterMode(EditingTestMode());
    expect(panel.shows("Editing"), isTrue);

    await panel.press(LogicalKeyboardKey.escape);

    expect(panel.shows("Editing"), isFalse);
  });

  testWidgets("Escape first dismisses what the focused item can dismiss", (
    tester,
  ) async {
    var dismissed = 0;
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModeDisplayWidget(),
            Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) => dismissed++,
                ),
              },
              child: const FocusableTarget(),
            ),
          ],
        ),
      ),
    );
    await panel.item("Target").select();
    await panel.enterMode(EditingTestMode());
    expect(panel.shows("Editing"), isTrue);

    await panel.press(LogicalKeyboardKey.escape);

    expect(dismissed, 1);
    expect(panel.shows("Editing"), isTrue);
  });
}
