import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// [page] of Acme, through the organization's real route.
PageRouteInfo organizationPage(PageRouteInfo page) =>
    OrganizationRoute(organizationId: acme.organizationId.id, children: [page]);

/// A members page of Acme opened at [page], as Ada sees it, with knobs for
/// the [varied] [MembershipList] (none, few, many, loading, failing), which
/// of its items start selected, how the membership service answers
/// commands, and the window. [selection] is where the Selection knob
/// starts.
///
/// The membership service keeps every change, so generating, revoking,
/// approving, declining and changing roles can be clicked through.
Widget membershipStory(
  BuildContext context, {
  required PageRouteInfo page,
  required MembershipList varied,
  List<Trait> traits = const [],
  String selection = "None",
}) {
  final label = switch (varied) {
    MembershipList.members => "Members",
    MembershipList.joinCodes => "Join codes",
    MembershipList.joinRequests => "Join requests",
  };
  final amount = context.knobs.object.dropdown(
    label: label,
    options: const ["None", "Few", "Many", "Loading", "Failing"],
    initialOption: "Few",
  );
  final answers = context.knobs.object.dropdown(
    label: "Service answers",
    options: const ["At once", "Slowly", "With a failure"],
    initialOption: "At once",
  );
  final generator = Generator(context.knobs.seed());
  int? count(MembershipList list) => list != varied
      ? 4
      : switch (amount) {
          "None" => 0,
          "Few" => 6,
          "Many" => 60,
          _ => null,
        };
  List<T>? listOf<T>(MembershipList list, List<T> Function(int count) make) =>
      switch (count(list)) {
        final count? => make(count),
        null => null,
      };
  final members = listOf(
    MembershipList.members,
    (count) => storyMembers(generator, count),
  );
  final joinCodes = listOf(
    MembershipList.joinCodes,
    (count) => storyJoinCodes(generator, count),
  );
  final joinRequests = listOf(
    MembershipList.joinRequests,
    (count) => storyJoinRequests(generator, count),
  );
  final picked = context.knobs.selection(initial: selection);
  return Story([
    signedIn(ada, organization: acme),
    membershipService(
      roles: storyRoles,
      members: members,
      joinCodes: joinCodes,
      joinRequests: joinRequests,
      failure: amount == "Failing"
          ? StateError("The membership service is unreachable")
          : null,
      commandFailure: answers == "With a failure"
          ? StateError("The membership service is unreachable")
          : null,
    ),
    if (answers == "Slowly") latency(const Duration(seconds: 3)),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
    ...context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
    ...switch (varied) {
      MembershipList.members => selectionOf(
        picked,
        members ?? const [],
        (member) => MemberIdentifier(member.userId),
      ),
      MembershipList.joinCodes => selectionOf(
        picked,
        joinCodes ?? const [],
        (code) => JoinCodeIdentifier(code.code),
      ),
      MembershipList.joinRequests => selectionOf(
        picked,
        joinRequests ?? const [],
        (request) => JoinRequestIdentifier(request.requestId),
      ),
    },
    ...traits,
  ], at: PanelLocation.route(organizationPage(MembersRoute(children: [page]))));
}
