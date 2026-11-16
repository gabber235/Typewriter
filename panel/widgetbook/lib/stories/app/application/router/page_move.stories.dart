import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The [PageFrame] around every page of Acme. Press the sidebar links: the
/// rows of the page a move reaches ripple in from below going down the
/// sidebar and from above going up; with reduced motion they land at once.
@widgetbook.UseCase(name: "Moving between pages", type: PageFrame)
Widget pageFrameUseCase(BuildContext context) {
  final generator = Generator(context.knobs.seed());
  return Story([
    signedIn(ada, organization: acme),
    servicesService(),
    membershipService(
      roles: storyRoles,
      members: storyMembers(generator, 8),
      joinCodes: storyJoinCodes(generator, 3),
      joinRequests: storyJoinRequests(generator, 3),
    ),
    ...context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
  ], at: PanelLocation.route(organizationPage(const ServicesRoute())));
}
