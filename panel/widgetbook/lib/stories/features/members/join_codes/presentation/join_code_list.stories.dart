import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The join code cards smaller windows show instead of the table, under a
/// Select all row. Each card opens to copy or revoke its code.
@widgetbook.UseCase(name: "Default", type: JoinCodesCardList)
Widget joinCodesCardListUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Join codes",
    make: storyJoinCodes,
    identity: (code) => code.code,
    traits: (codes) => [membership(roles: storyRoles, joinCodes: codes)],
    windows: listWindows,
    builder: (selection) => JoinCodesCardList(selection: selection),
  );
}
