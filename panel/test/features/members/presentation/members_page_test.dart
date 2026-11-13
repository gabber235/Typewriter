import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The members section's main task: moving between its Members, Join
/// Requests and Join Codes pages, once with the keyboard alone and once with
/// the mouse alone.
void main() {
  final page = [
    signedIn(ada, organization: acme),
    membershipService(
      members: [member("Grace")],
      joinCodes: [joinCode("spring")],
    ),
  ];
  const pages = {
    "Join Requests": "/organization/acme/members/join-requests",
    "Join Codes": "/organization/acme/members/join-codes",
    "Members": "/organization/acme/members",
  };

  testWidgets("the keyboard alone moves from the members list to the join "
      "codes and back", (tester) async {
    final panel = await tester.pumpPanel(page, at: membersPage());
    expect(panel.focused, contains("Grace"));

    for (final link in ["Join Codes", "Members"]) {
      // Control+H moves to the sidebar pane on every platform. Control+Left
      // does not move while a member row has focus.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await panel.settle();
      await panel.tabTo(link);
      await panel.press(LogicalKeyboardKey.enter);

      await panel.eventually(() => expect(panel.path, pages[link]));
      expect(panel.headings, contains(link));
    }
  });

  testWidgets("the mouse alone moves from the members list to each sibling "
      "page and back", (tester) async {
    final panel = await tester.pumpPanel(page, at: membersPage());

    for (final MapEntry(key: link, value: path) in pages.entries) {
      await panel.tapOn(find.text(link).first);

      await panel.eventually(() => expect(panel.path, path));
      expect(panel.headings, contains(link));
    }
  });
}
