import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/shared/focused_row_driver.dart";
import "package:typewriter_testkit/src/traits/members/membership.dart";
import "package:typewriter_testkit/src/traits/session.dart";

/// Focused member and join code rows of Ada's organization, whose every
/// shortcut records what it invoked.
extension PumpMembershipRowShortcuts on WidgetTester {
  /// Focuses the row of [member], [selected] or not, in a selection that is
  /// as non empty as the row is selected.
  Future<FocusedRowDriver> pumpMemberRow(
    skir.OrganizationMember member, {
    required bool selected,
  }) => pumpFocusedRow(
    [
      signedIn(ada, organization: acme),
      membership(members: [member]),
    ],
    (content, record) => MemberTableRowShortcuts(
      member: member,
      onToggleSelection: record("toggle"),
      onSelectAll: record("select all"),
      onClearSelection: record("clear"),
      isSelected: selected,
      hasSelection: selected,
      onRemoveSelection: () async => record("remove selection")(),
      onRemoveFromSelection: record("remove from selection"),
      onFocusChange: (_) {},
      child: content,
    ),
  );

  /// Focuses the row of [code], [selected] or not, in a selection that is
  /// as non empty as the row is selected.
  Future<FocusedRowDriver> pumpJoinCodeRow(
    skir.JoinCode code, {
    required bool selected,
  }) => pumpFocusedRow(
    [
      signedIn(ada, organization: acme),
      membership(joinCodes: [code]),
    ],
    (content, record) => JoinCodeTableRowShortcuts(
      code: code,
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
}
