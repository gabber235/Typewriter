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
    traits: (codes) => [membership(roles: storyRoles, joinCodes: codes)],
    builder: (selection) => JoinCodesTable(selection: selection),
  );
}
