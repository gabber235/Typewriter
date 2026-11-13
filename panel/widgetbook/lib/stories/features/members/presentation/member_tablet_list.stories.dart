import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The member cards smaller windows show instead of the table, under a
/// Select all row. Each card opens to edit its member's roles and remove
/// them.
@widgetbook.UseCase(name: "Default", type: MembersTabletList)
Widget membersTabletListUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Members",
    make: storyMembers,
    identity: (member) => member.userId,
    traits: (members) => [membership(roles: storyRoles, members: members)],
    windows: listWindows,
    builder: (selection) => MembersTabletList(selection: selection),
  );
}
