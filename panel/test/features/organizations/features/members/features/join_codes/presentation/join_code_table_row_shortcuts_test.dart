import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  testWidgets("join code row shortcuts manage selection and actions", (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var toggles = 0;
    var selectAll = 0;
    var clears = 0;
    var copies = 0;
    final code = OrganizationJoinCode(
      code: recordId("join_code:code"),
      createdAt: DateTime.utc(2024),
    );

    await tester.pumpWidget(
      FakeApp(
        child: JoinCodeTableRowShortcuts(
          code: code,
          onToggleSelection: () => toggles++,
          onSelectAll: () => selectAll++,
          onClearSelection: () => clears++,
          onCopy: () => copies++,
          isSelected: false,
          hasSelection: false,
          onRevokeSelection: () async {},
          onFocusChange: (_) {},
          child: Focus(
            focusNode: focusNode,
            child: const SizedBox(width: 20, height: 20),
          ),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(toggles, 1);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(selectAll, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(clears, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    expect(copies, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text("Revoke this join code?"), findsOneWidget);
  });

  testWidgets("selected join code row routes keys to bulk callbacks", (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var clears = 0;
    var copies = 0;
    var revokes = 0;
    final code = OrganizationJoinCode(
      code: recordId("join_code:selected"),
      createdAt: DateTime.utc(2024),
    );

    await tester.pumpWidget(
      FakeApp(
        child: JoinCodeTableRowShortcuts(
          code: code,
          onToggleSelection: () {},
          onSelectAll: () {},
          onClearSelection: () => clears++,
          onCopy: () => copies++,
          isSelected: true,
          hasSelection: true,
          onRevokeSelection: () async => revokes++,
          onFocusChange: (_) {},
          child: Focus(focusNode: focusNode, child: const SizedBox()),
        ),
      ),
    );
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);

    expect(clears, 1);
    expect(copies, 0);
    expect(revokes, 1);
    expect(find.text("Revoke this join code?"), findsNothing);
  });
}
