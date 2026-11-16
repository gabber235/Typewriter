import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";

/// The desktop member table: rows that select, with checks in select mode,
/// each member's roles to edit inline, and the remove icon. The second member has a very long name
/// and many roles.
@widgetbook.UseCase(name: "Default", type: MembersTable)
Widget membersTableUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Members",
    make: storyMembers,
    identity: (member) => member.userId,
    selectable: (member) => MemberIdentifier(member.userId),
    traits: (members) => [membership(roles: storyRoles, members: members)],
    builder: (rows) => MembersTable(rows: rows),
  );
}

/// The member cards of touch layouts: a tap selects a member and the
/// inspector shows their roles and Remove; in select mode every card shows
/// its check.
@widgetbook.UseCase(name: "Default", type: MembersCardList)
Widget membersCardListUseCase(BuildContext context) {
  return selectableRowsStory(
    context,
    label: "Members",
    make: storyMembers,
    identity: (member) => member.userId,
    selectable: (member) => MemberIdentifier(member.userId),
    traits: (members) => [membership(roles: storyRoles, members: members)],
    windows: listWindows,
    builder: (rows) => MembersCardList(rows: rows),
  );
}
