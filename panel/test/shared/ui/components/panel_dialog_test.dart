import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a dialog opened by keys is heard by its title, shows its "
      "words and actions, and Escape closes it", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(DialogBackdropPage()),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    expect(find.bySemanticsLabel("Dialog title"), findsWidgets);
    expect(panel.shows("Dialog words"), isTrue);
    expect(panel.shows("Close"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.settle();
    expect(find.text("Dialog title"), findsNothing);
  });

  testWidgets("a dialog opened by keys takes the focus, and its focused "
      "action runs from the keyboard", (tester) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(DialogBackdropPage()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    expect(panel.focused, "Close");

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();
    expect(find.text("Dialog title"), findsNothing);
  });

  testWidgets("a dialog's words read in the panel's text colour", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(DialogBackdropPage()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    final words = tester.element(find.text("Dialog words"));
    expect(
      DefaultTextStyle.of(words).style.color?.toARGB32(),
      words.colors.contentPrimary.toARGB32(),
    );
  });
}
