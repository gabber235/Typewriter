import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";

/// The inspector for the selected join requests: who asks and until when,
/// the roles to grant, Accept once each request has a role, and Decline to
/// hold, for one request or several.
@widgetbook.UseCase(name: "Default", type: JoinRequestInspection)
Widget joinRequestInspectionUseCase(BuildContext context) {
  return membershipStory(
    context,
    page: const JoinRequestsRoute(),
    varied: MembershipList.joinRequests,
    selection: "One",
  );
}
