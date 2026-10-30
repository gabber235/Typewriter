import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";

@widgetbook.UseCase(name: "Default", type: JoinCodesPage)
Widget joinCodesPageUseCase(BuildContext context) {
  return membershipStory(
    context,
    page: const JoinCodesRoute(),
    varied: MembershipList.joinCodes,
  );
}
