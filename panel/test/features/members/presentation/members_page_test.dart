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
  const firstSidebarLink = "Services";
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
      await panel.pressControl(LogicalKeyboardKey.arrowLeft);
      await panel.tabTo(link);
      await panel.press(LogicalKeyboardKey.enter);

      await panel.eventually(() => expect(panel.path, pages[link]));
      expect(panel.headings, contains(link));
    }
  });

  for (final key in [LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyH]) {
    testWidgets("Control+${key.keyLabel} moves from a member row to the "
        "sidebar's first link", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());
      expect(panel.focused, contains("Grace"));

      await panel.pressControl(key);

      expect(panel.focused, firstSidebarLink);
    });
  }

  group("an empty page opened from the sidebar with Enter keeps the "
      "keyboard working:", () {
    final empty = [signedIn(ada, organization: acme), membershipService()];

    // Each page opens from a sibling, as a keyboard user reaches it. Tab
    // reaches the first control after the page: the Search command of the
    // pages with no control of their own, and on Join Codes the Advanced
    // options toggle of the join code card.
    for (final (link, sibling, control) in [
      ("Join Requests", membersPage(), "Search"),
      ("Join Codes", membersPage(), "Advanced options"),
      ("Members", membersPage(const JoinCodesRoute()), "Search"),
    ]) {
      testWidgets("Control+Left on $link returns to its link", (tester) async {
        final panel = await tester.pumpPanel(empty, at: sibling);
        await panel.openFromSidebar(link);
        await panel.eventually(() => expect(panel.path, pages[link]));

        await panel.pressControl(LogicalKeyboardKey.arrowLeft);

        expect(panel.focused, link);
      });

      testWidgets("Tab on $link reaches $control", (tester) async {
        final panel = await tester.pumpPanel(empty, at: sibling);
        await panel.openFromSidebar(link);
        await panel.eventually(() => expect(panel.path, pages[link]));

        await panel.press(LogicalKeyboardKey.tab);

        expect(panel.focusShows(find.text(control)), isTrue);
      });
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
