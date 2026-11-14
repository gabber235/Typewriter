import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final (key, shifted) in [
    (LogicalKeyboardKey.keyD, true),
    (LogicalKeyboardKey.delete, true),
    (LogicalKeyboardKey.backspace, true),
    (LogicalKeyboardKey.keyX, false),
    (LogicalKeyboardKey.keyX, true),
  ]) {
    testWidgets("${keyName(key, shifted: shifted)} on a focused member row "
        "neither removes nor starts a hold", (tester) async {
      final panel = await tester.pumpPanel([
        signedIn(ada, organization: acme),
        membershipService(members: [member("Grace"), member("Linus")]),
      ], at: membersPage());

      if (shifted) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await panel.keyDown(key);
      await panel.holdFor(0.5);
      expect(panel.holdLine, isNull);
      await panel.holdFor(1);
      await panel.keyUp(key);
      if (shifted) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      expect(panel.shows("Grace"), isTrue);
    });
  }
}
