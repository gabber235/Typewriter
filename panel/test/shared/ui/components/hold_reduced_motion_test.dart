import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");
  final linus = member("Linus");
  final traits = [
    signedIn(ada, organization: acme),
    membershipService(members: [grace, linus]),
    reducedMotion,
  ];

  testWidgets("with reduced motion a full hold removes Grace and focus lands "
      "on Linus", (tester) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.holdKey(LogicalKeyboardKey.delete);

    await panel.eventually(() => expect(panel.shows("Grace"), isFalse));
    await panel.eventually(() => expect(panel.focusedRow, linus));
  });

  testWidgets("with reduced motion an early release removes nothing", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.holdKey(LogicalKeyboardKey.delete, share: 1 / 3);

    expect(panel.shows("Grace"), isTrue);
  });
}
