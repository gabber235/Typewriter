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
    (true, LogicalKeyboardKey.delete, false, ["revoke selection"]),
  ]) {
    testWidgets("${keyName(key, shifted: shifted)} on "
        "${selected ? "a selected" : "an unselected"} join code row invokes "
        "${invoked.isEmpty ? "nothing" : invoked.single}", (tester) async {
      final row = await tester.pumpFocusedRow(
        [
          signedIn(ada, organization: acme),
          membership(joinCodes: [_code]),
        ],
        (content, record) => JoinCodeTableRowShortcuts(
          code: _code,
          onToggleSelection: record("toggle"),
          onSelectAll: record("select all"),
          onClearSelection: record("clear"),
          onCopy: record("copy"),
          isSelected: selected,
          hasSelection: selected,
          onRevokeSelection: () async => record("revoke selection")(),
          onFocusChange: (_) {},
          child: content,
        ),
      );

      await row.press(key, shifted: shifted);

      expect(row.invoked, invoked);
      expect(row.panel.dialog.showing("Revoke this join code?"), isFalse);
    });
  }

  testWidgets("Delete on an unselected join code row asks before revoking", (
    tester,
  ) async {
    final row = await tester.pumpFocusedRow(
      [
        signedIn(ada, organization: acme),
        membership(joinCodes: [_code]),
      ],
      (content, record) => JoinCodeTableRowShortcuts(
        code: _code,
        onToggleSelection: record("toggle"),
        onSelectAll: record("select all"),
        onClearSelection: record("clear"),
        onCopy: record("copy"),
        isSelected: false,
        hasSelection: false,
        onRevokeSelection: () async => record("revoke selection")(),
        onFocusChange: (_) {},
        child: content,
      ),
    );

    await row.press(LogicalKeyboardKey.delete);

    expect(row.panel.dialog.showing("Revoke this join code?"), isTrue);
    expect(row.invoked, isEmpty);
  });
}
