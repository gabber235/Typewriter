import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The desktop join code table: each code's link with Copy, its type, when
/// it expires, and the revoke icon. The first code expires within the hour,
/// the second never does.
@widgetbook.UseCase(name: "Default", type: JoinCodesTable)
Widget joinCodesTableUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Join codes",
    make: storyJoinCodes,
    identity: (code) => code.code,
    selectable: (code) => JoinCodeIdentifier(code.code),
    traits: (codes) => [membership(roles: storyRoles, joinCodes: codes)],
    builder: (rows) => JoinCodesTable(rows: rows),
  );
}

/// The join code cards of touch layouts: a tap selects a code and the
/// inspector shows Copy and Revoke; in select mode every card shows its
/// check.
@widgetbook.UseCase(name: "Default", type: JoinCodesCardList)
Widget joinCodesCardListUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Join codes",
    make: storyJoinCodes,
    identity: (code) => code.code,
    selectable: (code) => JoinCodeIdentifier(code.code),
    traits: (codes) => [membership(roles: storyRoles, joinCodes: codes)],
    windows: listWindows,
    builder: (rows) => JoinCodesCardList(rows: rows),
  );
}
