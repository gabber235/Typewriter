import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The desktop member table: avatars that select, each member's roles to
/// edit inline, and the remove icon. The second member has a very long name
/// and many roles.
@widgetbook.UseCase(name: "Default", type: MembersTable)
Widget membersTableUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Members",
    make: storyMembers,
    identity: (member) => member.userId,
    traits: (members) => [membership(roles: storyRoles, members: members)],
    builder: (selection) => MembersTable(selection: selection),
  );
}
