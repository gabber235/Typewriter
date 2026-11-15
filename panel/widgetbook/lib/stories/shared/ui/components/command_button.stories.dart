import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";

/// Hold Revoke in the inspector of a selection.
@widgetbook.UseCase(name: "Hold buttons", type: CommandButton)
Widget commandButtonStory(BuildContext context) {
  return membershipStory(
    context,
    page: const JoinCodesRoute(),
    varied: MembershipList.joinCodes,
  );
}
