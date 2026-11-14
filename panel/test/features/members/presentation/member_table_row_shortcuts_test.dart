import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _member = member("Grace", joinedAt: DateTime.utc(2024));

void main() {
  for (final (key, shifted, invoked) in [
    (LogicalKeyboardKey.space, false, "toggle"),
    (LogicalKeyboardKey.space, true, "select all"),
    (LogicalKeyboardKey.escape, false, "clear"),
  ]) {
    testWidgets("${keyName(key, shifted: shifted)} on a selected "
        "member row invokes $invoked", (tester) async {
      final row = await tester.pumpMemberRow(_member, selected: true);

      await row.press(key, shifted: shifted);

      expect(row.invoked, [invoked]);
    });
  }

  for (final selected in [true, false]) {
    testWidgets(
      "a brief Delete on ${selected ? "a selected" : "an "
                "unselected"} member row neither removes nor asks",
      (tester) async {
        final row = await tester.pumpMemberRow(_member, selected: selected);

        await row.press(LogicalKeyboardKey.delete);

        expect(row.invoked, isEmpty);
        expect(row.panel.commandRuns.session.value, isNull);
        expect(row.panel.dialog.showing("Remove Grace?"), isFalse);
      },
    );
  }

  for (final (selected, targets) in [
    (true, ["Grace", "Linus"]),
    (false, ["Grace"]),
  ]) {
    testWidgets(
      "holding Delete on ${selected ? "a selected" : "an "
                "unselected"} member row holds over ${targets.join(" and ")}",
      (tester) async {
        final row = await tester.pumpMemberRow(_member, selected: selected);

        await row.panel.keyDown(LogicalKeyboardKey.delete);
        await row.panel.holdFor(0.3);

        expect(
          row.panel.commandRuns.session.value?.attempt.outcome,
          targets.length == 1
              ? startsWith("Remove Grace?")
              : startsWith("Remove 2 members?"),
        );
        await row.panel.keyUp(LogicalKeyboardKey.delete);
      },
    );
  }
}
