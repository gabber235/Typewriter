import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _code = joinCode("code", createdAt: DateTime.utc(2024));

void main() {
  for (final (selected, key, shifted, invoked) in [
    (false, LogicalKeyboardKey.space, false, ["toggle"]),
    (false, LogicalKeyboardKey.space, true, ["select all"]),
    (false, LogicalKeyboardKey.keyC, false, ["copy"]),
    (true, LogicalKeyboardKey.escape, false, ["clear"]),
    (true, LogicalKeyboardKey.keyC, false, <String>[]),
    (true, LogicalKeyboardKey.delete, false, <String>[]),
    (false, LogicalKeyboardKey.delete, false, <String>[]),
  ]) {
    testWidgets("${keyName(key, shifted: shifted)} on "
        "${selected ? "a selected" : "an unselected"} join code row invokes "
        "${invoked.isEmpty ? "nothing" : invoked.single}", (tester) async {
      final row = await tester.pumpJoinCodeRow(_code, selected: selected);

      await row.press(key, shifted: shifted);

      expect(row.invoked, invoked);
      expect(row.panel.dialog.showing("Revoke this join code?"), isFalse);
    });
  }

  for (final (selected, outcome) in [
    (true, "Revoke 2 join codes? Nobody new can join with them."),
    (false, "Revoke this join code? Nobody new can join with it."),
  ]) {
    testWidgets(
      "holding Delete on ${selected ? "a selected" : "an "
                "unselected"} join code row holds: $outcome",
      (tester) async {
        final row = await tester.pumpJoinCodeRow(_code, selected: selected);

        await row.panel.keyDown(LogicalKeyboardKey.delete);
        await row.panel.holdFor(0.3);

        expect(row.panel.commandRuns.session.value?.attempt.outcome, outcome);
        await row.panel.keyUp(LogicalKeyboardKey.delete);
      },
    );
  }
}
