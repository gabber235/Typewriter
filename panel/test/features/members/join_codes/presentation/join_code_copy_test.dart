import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// Copying join code links, the shared Copy operation on the focused code or
/// the selection, once with the keyboard alone and once with the mouse
/// alone. Rows only select; Copy lives in the context menu, the inspector
/// and on C.
void main() {
  final first = joinCode("first");
  final second = joinCode("second");
  final third = joinCode("third");
  final page = [
    signedIn(ada, organization: acme),
    membershipService(joinCodes: [first, second, third]),
  ];
  final firstLink = joinCodeUrl(first.code);
  final secondLink = joinCodeUrl(second.code);
  final thirdLink = joinCodeUrl(third.code);

  group("with the keyboard alone", () {
    testWidgets("C copies the focused code's link and says so", (tester) async {
      final clipboard = tester.recordClipboard();
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );
      expect(panel.focused, contains(firstLink));
      final reported = panel.recordReported();

      await panel.press(LogicalKeyboardKey.keyC);

      expect(clipboard, [firstLink]);
      expect(reported, ["Copied to the clipboard"]);
    });

    testWidgets("C copies every selected link, one per line", (tester) async {
      final clipboard = tester.recordClipboard();
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyC);

      expect(clipboard, ["$firstLink\n$thirdLink"]);
    });

    testWidgets("C on a code outside the selection copies only that code", (
      tester,
    ) async {
      final clipboard = tester.recordClipboard();
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyK);
      await panel.press(LogicalKeyboardKey.keyC);

      expect(clipboard, [secondLink]);
    });
  });

  group("with the mouse alone", () {
    testWidgets("the inspector's Copy copies the selected links and types "
        "Copied", (tester) async {
      final clipboard = tester.recordClipboard();
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      await panel.item(firstLink).toggle();
      await panel.item(secondLink).toggle();
      await panel.inspector.click("Copy 2");

      expect(clipboard, ["$firstLink\n$secondLink"]);
      expect(panel.inspector.operations, contains("Copied"));
    });

    testWidgets("a code's context menu copies its link", (tester) async {
      final clipboard = tester.recordClipboard();
      final panel = await tester.pumpPanel(
        page,
        at: membersPage(const JoinCodesRoute()),
      );

      final reported = panel.recordReported();
      final menu = await panel.item(thirdLink).contextMenu();
      await menu.choose("Copy");

      expect(clipboard, [thirdLink]);
      expect(reported, ["Copied to the clipboard"]);
    });

    testWidgets("a join code row has no Copy button of its own", (
      tester,
    ) async {
      await tester.pumpPanel(page, at: membersPage(const JoinCodesRoute()));

      expect(
        find.descendant(
          of: find.byType(JoinCodesTable),
          matching: find.byType(CommandButton),
        ),
        findsNothing,
      );
    });
  });
}
