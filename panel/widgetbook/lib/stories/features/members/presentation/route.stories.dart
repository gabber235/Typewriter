import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The members section of Acme, which hosts the Members, Join Requests and
/// Join Codes pages; the sidebar moves between them.
@widgetbook.UseCase(name: "Default", type: MembersPage)
Widget membersPageUseCase(BuildContext context) {
  final page = context.knobs.object.segmented(
    label: "Page",
    options: const ["Members", "Join requests", "Join codes"],
    initialOption: "Members",
  );
  final lists = context.knobs.object.dropdown(
    label: "Lists",
    options: const ["Few", "None", "Loading", "Failing"],
    initialOption: "Few",
  );
  final generator = Generator(context.knobs.seed());
  List<T>? listOf<T>(List<T> Function(int count) make) => switch (lists) {
    "Few" => make(6),
    "None" => make(0),
    _ => null,
  };
  final child = switch (page) {
    "Join requests" => const JoinRequestsRoute(),
    "Join codes" => const JoinCodesRoute(),
    _ => const MemberListRoute(),
  };
  return Story(
    [
      signedIn(ada, organization: acme),
      membershipService(
        roles: storyRoles,
        members: listOf((count) => storyMembers(generator, count)),
        joinCodes: listOf((count) => storyJoinCodes(generator, count)),
        joinRequests: listOf((count) => storyJoinRequests(generator, count)),
        failure: lists == "Failing"
            ? StateError("The membership service is unreachable")
            : null,
      ),
      ...context.knobs.windows(),
    ],
    at: PanelLocation.route(organizationPage(MembersRoute(children: [child]))),
  );
}
