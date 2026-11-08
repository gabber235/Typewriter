import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");
  final linus = member("Linus");
  const refusal = "Organization founder cannot be removed";

  for (final (name, window) in [
    ("member table", <Trait>[]),
    ("tablet card list", [compact]),
  ]) {
    testWidgets("holding Grace's row in the $name shows one outcome line "
        "and, once refused, one message under her", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membershipService(members: [grace, linus], founders: {grace.userId}),
        ...window,
      ], at: membersPage());

      await panel.keyDown(LogicalKeyboardKey.delete);
      await panel.holdFor(0.5);
      expect(find.byType(HoldLine), findsOneWidget);
      expect(panel.holdLine, "Remove Grace? They lose access straight away.");
      await panel.holdFor(1);
      await panel.keyUp(LogicalKeyboardKey.delete);

      await panel.eventually(
        () => expect(panel.messageUnder("Grace"), refusal),
      );
      expect(find.text(refusal), findsOneWidget);
      expect(panel.messageUnder("Linus"), isNull);
    });
  }
}
