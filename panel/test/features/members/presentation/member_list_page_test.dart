import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The main tasks of the members page, each done once with the keyboard
/// alone and once with the mouse alone: giving several members a role
/// together, selecting and clearing, and removing. Rows only select; every
/// change goes through the inspector, the context menu or its key.
void main() {
  final writer = role("writer", name: "Writer");
  final editor = role("editor", name: "Editor");
  final reader = role("reader", name: "Reader");
  final grace = member("Grace");
  final linus = member("Linus");
  final page = [
    signedIn(ada, organization: acme),
    membershipService(roles: [editor, writer], members: [grace, linus]),
  ];
  // Bram and Dara hold different roles, so giving both Writer gives each
  // their own roles plus Writer.
  final bram = member("Bram", roles: [editor]);
  final dara = member("Dara", roles: [reader]);
  final pair = [
    signedIn(ada, organization: acme),
    membershipService(roles: [writer, editor, reader], members: [bram, dara]),
  ];
  // Ann and Ken are selected while Bea, between them, is not.
  final trio = [
    signedIn(ada, organization: acme),
    membershipService(
      roles: [editor],
      members: [member("Ann"), member("Bea"), member("Ken")],
    ),
  ];

  group("with the keyboard alone", () {
    testWidgets("holding Delete on a member outside the selection removes "
        "only that member", (tester) async {
      final panel = await tester.pumpPanel(trio, at: membersPage());
      expect(panel.focused, contains("Ann"));

      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.keyJ);
      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.keyK);
      expect(panel.focused, contains("Bea"));
      await panel.keyDown(LogicalKeyboardKey.delete);
      await panel.holdFor(0.5);
      expect(panel.holdLine, startsWith("Remove Bea?"));
      await panel.holdFor(1);
      await panel.keyUp(LogicalKeyboardKey.delete);

      await panel.eventually(() => expect(panel.onPage("Bea"), findsNothing));
      expect(panel.onPage("Ann"), findsOneWidget);
      expect(panel.onPage("Ken"), findsOneWidget);
    });

    testWidgets("Bram and Dara both get the Writer role from the inspector, "
        "each keeping their own roles", (tester) async {
      final panel = await tester.pumpPanel(pair, at: membersPage());
      expect(panel.focused, contains("Bram"));

      await panel.press(LogicalKeyboardKey.space);
      await panel.press(LogicalKeyboardKey.arrowDown);
      await panel.press(LogicalKeyboardKey.space);
      expect(panel.inspector.heading("2 members"), findsOneWidget);
      await panel.pressControl(LogicalKeyboardKey.keyL);
      expect(
        panel.focusShows(find.text("Writer")),
        isTrue,
        reason: "${panel.focused}",
      );
      await panel.press(LogicalKeyboardKey.space);

      await panel.eventually(() {
        expect(panel.onPage("Writer"), findsNWidgets(2));
        expect(panel.onPage("Editor"), findsOneWidget);
        expect(panel.onPage("Reader"), findsOneWidget);
      });
    });

    testWidgets("Control+A selects every member and Escape clears the "
        "selection", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.pressControl(LogicalKeyboardKey.keyA);
      expect(panel.inspector.heading("2 members"), findsOneWidget);
      expect(panel.item("Grace").isChecked, isTrue);

      await panel.press(LogicalKeyboardKey.escape);
      expect(panel.inspector.heading("2 members"), findsNothing);
      expect(panel.item("Grace").showsCheck, isFalse);
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
        expect(panel.onPage("Grace"), findsNothing);
        expect(panel.onPage("Linus"), findsNothing);
      });
      expect(panel.onPage("Margaret"), findsOneWidget);
    });
  });

  group("with the mouse alone", () {
    testWidgets("a click shows one member in the inspector", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.item("Grace").select();

      expect(panel.item("Grace").isMarkedSelected, isTrue);
      expect(panel.item("Grace").showsCheck, isFalse);
      expect(panel.item("Grace").visibleCheckMarks, 0);
      expect(find.byType(MemberInspection), findsOneWidget);
    });

    testWidgets("a member row's context menu offers to remove that member", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      final menu = await panel.item("Linus").contextMenu();

      await panel.eventually(
        () => expect(menu.entries, contains(startsWith("Remove Linus?"))),
      );
    });

    testWidgets("holding Remove in the context menu of a member outside the "
        "selection removes only that member", (tester) async {
      final panel = await tester.pumpPanel(trio, at: membersPage());

      await panel.item("Ann").toggle();
      await panel.item("Ken").toggle();
      final menu = await panel.item("Bea").contextMenu();
      await panel.eventually(
        () => expect(menu.entries, contains(startsWith("Remove Bea?"))),
      );
      await panel.holdButton("Remove Bea?");

      await panel.eventually(() => expect(panel.onPage("Bea"), findsNothing));
      expect(panel.onPage("Ann"), findsOneWidget);
      expect(panel.onPage("Ken"), findsOneWidget);
    });

    testWidgets("a toggle click shows exactly one check on the member", (
      tester,
    ) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.item("Grace").toggle();

      expect(panel.item("Grace").visibleCheckMarks, 1);
      expect(panel.item("Linus").visibleCheckMarks, 0);
    });

    testWidgets("Bram and Dara both get the Writer role from the inspector, "
        "each keeping their own roles", (tester) async {
      final panel = await tester.pumpPanel(pair, at: membersPage());

      await panel.item("Bram").toggle();
      await panel.item("Dara").toggle();
      expect(panel.inspector.heading("2 members"), findsOneWidget);
      await panel.tapOn(
        find.descendant(
          of: find.byType(MemberInspection),
          matching: find.text("Writer"),
        ),
      );

      await panel.eventually(() {
        expect(panel.onPage("Writer"), findsNWidgets(2));
        expect(panel.onPage("Editor"), findsOneWidget);
        expect(panel.onPage("Reader"), findsOneWidget);
      });
    });

    testWidgets("holding Remove in the inspector removes both selected "
        "members", (tester) async {
      final panel = await tester.pumpPanel(page, at: membersPage());

      await panel.item("Grace").toggle();
      await panel.item("Linus").toggle();
      await panel.holdButton("Remove 2 members?");

      await panel.eventually(() {
        expect(panel.onPage("Grace"), findsNothing);
        expect(panel.onPage("Linus"), findsNothing);
      });
    });
  });
}
