import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  final grace = member("Grace");
  final linus = member("Linus");
  final traits = [
    signedIn(ada, organization: acme),
    membershipService(members: [grace, linus]),
  ];

  testWidgets("Delete held to completion on Grace's row removes Grace once "
      "and keeps Linus", (tester) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());
    expect(panel.focusedRow, grace);

    await panel.holdKey(LogicalKeyboardKey.delete);

    await panel.eventually(() => expect(panel.shows("Grace"), isFalse));
    expect(panel.shows("Linus"), isTrue);
  });

  testWidgets("Delete released early removes nothing and the fill drains", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.holdKey(LogicalKeyboardKey.delete, share: 1 / 3);

    expect(panel.shows("Grace"), isTrue);
    expect(panel.holdLine, isNull, reason: "the hold ended once drained");
  });

  testWidgets("Delete pressed again while the fill drains continues from the "
      "fill and completes sooner than a fresh hold", (tester) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.keyDown(LogicalKeyboardKey.delete);
    await panel.holdFor(0.6);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
    await panel.holdFor(0.1);
    await panel.keyDown(LogicalKeyboardKey.delete);
    await panel.holdFor(0.6);
    await panel.keyUp(LogicalKeyboardKey.delete);

    await panel.eventually(() => expect(panel.shows("Grace"), isFalse));
    expect(panel.shows("Linus"), isTrue);
  });

  testWidgets("Delete held past success does not start a hold on the row "
      "that took focus", (tester) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.keyDown(LogicalKeyboardKey.delete);
    await panel.holdFor(1);
    await panel.eventually(() => expect(panel.focusedRow, linus));
    for (var repeat = 0; repeat < 60; repeat++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.delete);
      await tester.pump(const Duration(milliseconds: 33));
    }
    await panel.keyUp(LogicalKeyboardKey.delete);

    expect(panel.shows("Grace"), isFalse);
    expect(panel.shows("Linus"), isTrue);
  });

  testWidgets("moving focus away mid hold removes nothing", (tester) async {
    final panel = await tester.pumpPanel(traits, at: membersPage());

    await panel.keyDown(LogicalKeyboardKey.delete);
    await panel.holdFor(0.5);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyJ);
    await panel.holdFor(1);
    await panel.keyUp(LogicalKeyboardKey.delete);

    expect(panel.shows("Grace"), isTrue);
    expect(panel.shows("Linus"), isTrue);
  });
}
