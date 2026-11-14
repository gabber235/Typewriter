import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The request cards under a Select all row; selecting requests shows roles
/// to accept them with, Accept All and Decline all. The second request has a
/// very long name and is about to expire.
@widgetbook.UseCase(name: "Default", type: JoinRequestsList)
Widget joinRequestsListUseCase(BuildContext context) {
  final requests = storyJoinRequests(
    Generator(context.knobs.seed()),
    context.knobs.rowCount(label: "Join requests"),
  );
  return Story(
    [
      membership(roles: storyRoles, joinRequests: requests),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: PanelLocation.component(
      StorySliverPane(slivers: [JoinRequestsList(requests: requests)]),
    ),
  );
}
