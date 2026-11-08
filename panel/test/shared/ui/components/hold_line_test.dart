import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");

  testWidgets("the outcome line is heard whole on the first frame, keeps the "
      "row's height, and types its verb before the rest arrives", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(members: [grace, member("Linus")]),
    ], at: membersPage());
    final row = find.ancestor(
      of: find.text("Grace"),
      matching: find.byType(HoldRow),
    );
    final height = tester.getSize(row.first).height;

    await panel.keyDown(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(panel.holdLine, "Remove Grace? They lose access straight away.");
    expect(tester.getSize(row.first).height, height);
    final verbs = <String>[];
    var elapsed = 0.0;
    while (elapsed < 1 / 3) {
      verbs.add(panel.holdLineTyped);
      await panel.holdFor(0.02);
      elapsed += 0.02;
    }
    expect(panel.holdLineTyped, "Remove");
    expect(panel.holdLineRestShown, isTrue);
    expect(
      verbs.where((typed) => typed.isNotEmpty && typed != "Remove"),
      isNotEmpty,
      reason: "the verb appears letter by letter",
    );
    await panel.keyUp(LogicalKeyboardKey.delete);
  });
}
