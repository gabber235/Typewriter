import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/shared/focused_row_driver.dart";
import "package:typewriter_testkit/src/traits/members/membership.dart";
import "package:typewriter_testkit/src/traits/members/membership_data.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// The other selected member of a selected member row.
final _otherMember = member("Linus", joinedAt: DateTime.utc(2024));

/// The other selected code of a selected join code row.
final _otherCode = joinCode("other", createdAt: DateTime.utc(2024));

/// Focused member and join code rows of Ada's organization, whose every
/// press shortcut records what it invoked. A selected row is selected with
/// one other row, so a hold over the selection targets both.
extension PumpMembershipRowShortcuts on WidgetTester {
  /// Focuses the row of [member], [selected] with Linus or not selected at
  /// all.
  Future<FocusedRowDriver> pumpMemberRow(
    skir.OrganizationMember member, {
    required bool selected,
  }) => pumpFocusedRow(
    [
      signedIn(ada, organization: acme),
      membership(members: [member]),
    ],
    (content, record) => HookBuilder(
      builder: (context) {
        final rows = useAnimatedRows(
          items: [member, _otherMember],
          identity: (member) => member.userId,
        );
        return MemberTableRowShortcuts(
          member: member,
          onToggleSelection: record("toggle"),
          onSelectAll: record("select all"),
          onClearSelection: record("clear"),
          isSelected: selected,
          hasSelection: selected,
          rows: rows,
          selectedIds: selected
              ? {member.userId, _otherMember.userId}
              : const {},
          nameOf: (id) => rows[id]?.item.name,
          child: content,
        );
      },
    ),
  );

  /// Focuses the row of [code], [selected] with one other code or not
  /// selected at all.
  Future<FocusedRowDriver> pumpJoinCodeRow(
    skir.JoinCode code, {
    required bool selected,
  }) => pumpFocusedRow(
    [
      signedIn(ada, organization: acme),
      membership(joinCodes: [code]),
    ],
    (content, record) => HookBuilder(
      builder: (context) {
        final rows = useAnimatedRows(
          items: [code, _otherCode],
          identity: (code) => code.code,
        );
        return JoinCodeTableRowShortcuts(
          code: code,
          onToggleSelection: record("toggle"),
          onSelectAll: record("select all"),
          onClearSelection: record("clear"),
          onCopy: record("copy"),
          isSelected: selected,
          hasSelection: selected,
          rows: rows,
          selectedIds: selected ? {code.code, _otherCode.code} : const {},
          child: content,
        );
      },
    ),
  );
}
