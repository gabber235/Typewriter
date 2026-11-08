import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");
  final linus = member("Linus");

  for (final (name, size) in [
    ("narrow", const Size(400, 900)),
    ("wide", desktopWindow),
  ]) {
    testWidgets("in a $name window the members page opens on the first "
        "member", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membershipService(members: [grace, linus]),
        window(size),
      ], at: membersPage());
      expect(panel.focused, contains("Grace"));
    });
  }

  testWidgets("removing Grace by keys focuses Linus", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(members: [grace, linus]),
    ], at: membersPage());
    await panel.holdKey(LogicalKeyboardKey.delete);
    await panel.eventually(() => expect(panel.focusedRow, linus));
  });

  testWidgets("a member someone else removes while Grace is focused leaves "
      "focus on Grace", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipBackend(members: [grace, linus]),
    ], at: membersPage());
    await panel.eventually(() => expect(panel.focused, contains("Grace")));
    panel.world.nats.announceMembers(
      acme.organizationId,
      skir.OrganizationMembersChanged(
        sequence: 2,
        changes: [skir.OrganizationMembersChange.wrapRemove(linus.userId)],
      ),
    );
    await panel.settle();
    expect(find.text("Linus"), findsNothing);
    expect(panel.focused, contains("Grace"));
  });

  testWidgets("J, K, Home and End move between member rows and Tab leaves "
      "the table", (tester) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(members: [member("Ada"), grace, linus]),
    ], at: membersPage());
    await panel.press(LogicalKeyboardKey.keyJ);
    expect(panel.focused, contains("Grace"));
    await panel.press(LogicalKeyboardKey.end);
    expect(panel.focused, contains("Linus"));
    await panel.press(LogicalKeyboardKey.home);
    expect(panel.focused, contains("Ada"));
    await panel.press(LogicalKeyboardKey.keyL);
    // The roles field reads no name when focused; its placeholder finds it.
    expect(panel.focusShows(find.text("Select roles")), isTrue);
    await panel.press(LogicalKeyboardKey.tab);
    expect(
      panel.focused,
      isNot(
        anyOf(contains("Grace"), contains("Linus"), contains("Select roles")),
      ),
    );
  });
}
