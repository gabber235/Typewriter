import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The main tasks of the members page, each done once with the keyboard
/// alone and once with the mouse alone: giving one member a role, selecting
/// and clearing, and removing.
void main() {
  final writer = role("writer", name: "Writer");
  final editor = role("editor", name: "Editor");
  final grace = member("Grace");
  final linus = member("Linus");
  final page = [
    signedIn(ada, organization: acme),
    membershipService(roles: [editor, writer], members: [grace, linus]),
  ];

  group("with the keyboard alone", () {
    testWidgets("Grace gets the Writer role from her row", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());
      expect(panel.focused, contains("Grace"));

      await panel.press(LogicalKeyboardKey.keyL);
      expect(panel.focusShows(find.text("Select roles")), isTrue);
      await panel.press(LogicalKeyboardKey.enter);
      await panel.press(LogicalKeyboardKey.arrowDown);
      await panel.press(LogicalKeyboardKey.arrowDown);
      await panel.press(LogicalKeyboardKey.enter);
      await panel.press(LogicalKeyboardKey.escape);

      await panel.eventually(() => expect(find.text("Writer"), findsOneWidget));
    });

    testWidgets("Shift+Space selects every member and Escape clears the "
        "selection", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.pressShifted(LogicalKeyboardKey.space);
      expect(panel.shows("2 selected"), isTrue);

      await panel.press(LogicalKeyboardKey.escape);
      expect(panel.shows("2 selected"), isFalse);
    });

    testWidgets("holding Delete over a selection removes every selected "
        "member", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membershipService(
          roles: [editor, writer],
          members: [member("Margaret"), grace, linus],
        ),
      ], at: membersPage());

      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      await panel.holdKey(LogicalKeyboardKey.delete);

      await panel.eventually(() {
        expect(find.text("Grace"), findsNothing);
        expect(find.text("Linus"), findsNothing);
      });
      expect(find.text("Margaret"), findsOneWidget);
    });
  });

  group("with the mouse alone", () {
    testWidgets("Grace gets the Writer role from her row", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.tapOn(find.text("Select roles").first);
      await panel.tapOn(find.text("Writer"));
      await panel.tapOn(find.text("Current Members"));

      await panel.eventually(() => expect(find.text("Writer"), findsOneWidget));
    });

    testWidgets("Unselect all clears a selection made by clicking avatars", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.tapOn(panel.labeled("Select Grace"));
      await panel.tapOn(panel.labeled("Select Linus"));
      expect(panel.shows("2 selected"), isTrue);

      await panel.tapOn(find.byTooltip("Unselect all"));
      expect(panel.shows("2 selected"), isFalse);
    });

    testWidgets("Grace and Linus both get the Writer role from the "
        "selection bar", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.tapOn(panel.labeled("Select Grace"));
      await panel.tapOn(panel.labeled("Select Linus"));
      await panel.tapOn(find.text("Assign roles"));
      await panel.tapOn(find.text("Writer").last);
      await panel.tapOn(find.text("Current Members"));
      await panel.tapOn(find.text("Apply roles"));

      await panel.eventually(
        () => expect(find.text("Writer"), findsNWidgets(2)),
      );
      expect(panel.shows("2 selected"), isFalse);
    });

    testWidgets("holding a member's remove icon removes that member", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.holdButton("Remove Linus?");

      await panel.eventually(() => expect(find.text("Linus"), findsNothing));
      expect(find.text("Grace"), findsOneWidget);
    });
  });
}
