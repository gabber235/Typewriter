import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

final _member = member("Grace", joinedAt: DateTime.utc(2024));

void main() {
  for (final (key, shifted, invoked) in [
    (LogicalKeyboardKey.space, false, "toggle"),
    (LogicalKeyboardKey.space, true, "select all"),
    (LogicalKeyboardKey.escape, false, "clear"),
    (LogicalKeyboardKey.delete, false, "remove selection"),
  ]) {
    testWidgets("${keyName(key, shifted: shifted)} on a selected "
        "member row invokes $invoked", (tester) async {
      final row = await tester.pumpMemberRow(_member, selected: true);

      await row.press(key, shifted: shifted);

      expect(row.invoked, [invoked]);
      expect(row.panel.dialog.showing("Remove Grace?"), isFalse);
    });
  }

  testWidgets("Delete on an unselected member row asks before removing it", (
    tester,
  ) async {
    final row = await tester.pumpMemberRow(_member, selected: false);

    await row.press(LogicalKeyboardKey.delete);

    expect(row.panel.dialog.showing("Remove Grace?"), isTrue);
    expect(row.invoked, isEmpty);
  });
}
