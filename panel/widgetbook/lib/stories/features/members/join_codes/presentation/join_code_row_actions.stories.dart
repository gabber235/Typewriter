import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The revoke icon at the end of a join code's table row. Holding it fills
/// and states that nobody new can join; this story has no membership
/// service, so the revoke is refused once the hold completes.
@widgetbook.UseCase(name: "Default", type: JoinCodeRowActions)
Widget joinCodeRowActionsUseCase(BuildContext context) {
  final code = storyJoinCodes(Generator(1), 1).single;
  return Story(
    [
      membership(roles: storyRoles, joinCodes: [code]),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      Center(
        child: StoryRows(
          items: [code],
          identity: (code) => code.code,
          builder: (context, selection) =>
              JoinCodeRowActions(code: code, rows: selection.rows),
        ),
      ),
    ),
  );
}
