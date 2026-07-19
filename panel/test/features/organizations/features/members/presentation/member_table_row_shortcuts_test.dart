import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/features/organizations/features/members/application/members.dart";
import "package:typewriter_panel/features/organizations/features/members/presentation/member_table_row_shortcuts.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/converters.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  testWidgets("member row shortcuts manage selection and removal", (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var toggles = 0;
    var selectAll = 0;
    var clears = 0;
    var removedFromSelection = 0;
    var removedSelection = 0;
    final member = OrganizationMember(
      userId: recordId("user:member"),
      roles: const [],
      joinedAt: DateTime.utc(2024),
      name: "Member",
    );

    await tester.pumpWidget(
      FakeApp(
        child: MemberTableRowShortcuts(
          member: member,
          onToggleSelection: () => toggles++,
          onSelectAll: () => selectAll++,
          onClearSelection: () => clears++,
          isSelected: true,
          hasSelection: true,
          onRemoveSelection: () async => removedSelection++,
          onRemoveFromSelection: () => removedFromSelection++,
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

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    expect(removedSelection, 1);
    expect(find.text("Remove Member?"), findsNothing);
    expect(removedFromSelection, 0);
  });
}
