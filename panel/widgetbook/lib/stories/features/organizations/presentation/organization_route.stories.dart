import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The traits every organization story shares: Ada in Acme with its
/// members, codes and requests and the showcase Realm, plus a services
/// backend when the story opens the services page; that backend would
/// replace the Realm's topology.
List<Trait> _acme(Generator generator, {bool services = false}) => [
  signedIn(ada, organization: acme),
  showcaseRealm(),
  if (services) servicesService(),
  membershipService(
    roles: storyRoles,
    members: storyMembers(generator, 8),
    joinCodes: storyJoinCodes(generator, 3),
    joinRequests: storyJoinRequests(generator, 3),
  ),
];

/// [OrganizationPage] opened at each of its child pages, so its nested
/// router shows them inside the same organization shell.
@widgetbook.UseCase(name: "Child pages", type: OrganizationPage)
Widget organizationPageUseCase(BuildContext context) {
  final page = context.knobs.object.dropdown(
    label: "Page",
    options: const [
      "Services",
      "Members",
      "Join requests",
      "Join codes",
      "Realm",
    ],
    initialOption: "Services",
  );
  return Story(
    [
      ..._acme(Generator(context.knobs.seed()), services: page == "Services"),
      ...context.knobs.traits("Window", {
        "Desktop": const [],
        "Compact": const [compact],
      }),
    ],
    at: PanelLocation.route(switch (page) {
      "Members" => organizationPage(
        MembersRoute(children: [const MemberListRoute()]),
      ),
      "Join requests" => organizationPage(
        MembersRoute(children: [const JoinRequestsRoute()]),
      ),
      "Join codes" => organizationPage(
        MembersRoute(children: [const JoinCodesRoute()]),
      ),
      "Realm" => const RealmRouteTree().realm(showcaseScope),
      _ => organizationPage(const ServicesRoute()),
    }),
  );
}

/// The [OrganizationScaffold] around a Realm: app bar, sidebar, inspector
/// and action row at every window size, and the suspension barrier it
/// raises when the Realm's host stops or its state cannot be read.
@widgetbook.UseCase(
  name: "Windows and Realm states",
  type: OrganizationScaffold,
)
Widget organizationScaffoldUseCase(BuildContext context) {
  return Story([
    ..._acme(Generator(context.knobs.seed())),
    ...context.knobs.traits("Realm", {
      "Online": const [],
      "Host offline": const [realmHostStopped],
      "Checking": [servicesService(topologyArrives: false)],
    }),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Narrow": [window(const Size(900, 700))],
      "Compact": const [compact],
      "Phone": [window(const Size(360, 720))],
    }),
  ], at: PanelLocation.route(const RealmRouteTree().realm(showcaseScope)));
}
