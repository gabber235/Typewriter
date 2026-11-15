import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";

/// The inspector for the selected members: one member's details and roles,
/// or for several members their roles as "1 of 2" where only some hold one.
/// A press on a role changes every selected member at once; Remove holds.
@widgetbook.UseCase(name: "Default", type: MemberInspection)
Widget memberInspectionUseCase(BuildContext context) {
  return membershipStory(
    context,
    page: const MemberListRoute(),
    varied: MembershipList.members,
    selection: "One",
  );
}
