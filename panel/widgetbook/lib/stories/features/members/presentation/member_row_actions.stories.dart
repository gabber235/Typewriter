import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The remove icon at the end of a member's table row. Holding it fills and
/// states who loses access; this story has no membership service, so the
/// remove is refused once the hold completes.
@widgetbook.UseCase(name: "Default", type: MemberRowActions)
Widget memberRowActionsUseCase(BuildContext context) {
  final longName = context.knobs.boolean(label: "Long name");
  final member = storyMembers(Generator(1), 2)[longName ? 1 : 0];
  return Story(
    [
      membership(roles: storyRoles, members: [member]),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Center(
        child: StoryRows(
          items: [member],
          identity: (member) => member.userId,
          builder: (context, selection) =>
              MemberRowActions(member: member, rows: selection.rows),
        ),
      ),
    ),
  );
}
