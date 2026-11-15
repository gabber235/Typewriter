import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";

/// The inspector for the selected join codes: one code's link with Copy, the
/// roles it grants, how often it works and when it expires, and Revoke to
/// hold for one code or several.
@widgetbook.UseCase(name: "Default", type: JoinCodeInspection)
Widget joinCodeInspectionUseCase(BuildContext context) {
  return membershipStory(
    context,
    page: const JoinCodesRoute(),
    varied: MembershipList.joinCodes,
    selection: "One",
  );
}
