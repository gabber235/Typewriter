import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");
  final linus = member("Linus");
  final ken = member("Ken");
  const refusal = "Organization founder cannot be removed";

  testWidgets("a bulk remove the backend refuses for Grace and Linus keeps "
      "them listed with their messages, jams Grace and focuses her", (
    tester,
  ) async {
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      membershipService(
        members: [grace, linus, ken],
        founders: {grace.userId, linus.userId},
      ),
      latency(const Duration(milliseconds: 500)),
    ], at: membersPage());
    for (final step in [
      null,
      LogicalKeyboardKey.keyJ,
      LogicalKeyboardKey.keyJ,
    ]) {
      if (step != null) await panel.press(step);
      await panel.press(LogicalKeyboardKey.space);
    }
    expect(panel.focusedRow, ken);

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.bySemanticsLabel(RegExp("^Remove 3 members")).first,
      ),
    );
    await panel.holdFor(1);
    await gesture.up();
    await tester.pump();
    for (final name in ["Grace", "Linus", "Ken"]) {
      expect(
        tester.textDecorationOf(find.text(name).first),
        TextDecoration.lineThrough,
        reason: "$name is struck through while the removes send",
      );
    }

    await panel.eventually(() => expect(panel.shows("Ken"), isFalse));
    await panel.settle();
    for (final name in ["Grace", "Linus"]) {
      expect(panel.shows(name), isTrue);
      expect(
        tester.textDecorationOf(find.text(name).first),
        isNot(TextDecoration.lineThrough),
      );
      expect(panel.messageUnder(name), refusal);
    }
    expect(panel.focusedRow, grace);

    await panel.keyDown(LogicalKeyboardKey.keyD);
    await panel.holdFor(1);
    await tester.pump();
    expect(panel.messageUnder("Grace"), isNull);
    expect(panel.messageUnder("Linus"), isNull);
    await panel.keyUp(LogicalKeyboardKey.keyD);
    await panel.eventually(() => expect(panel.messageUnder("Grace"), refusal));
  });
}
