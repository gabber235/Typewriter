import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The organization sidebar beside the showcase Realm: the Realm's sections,
/// the organization's pages with the join requests badge, and the links at
/// the bottom; a compact window moves it into a drawer.
@widgetbook.UseCase(name: "Default", type: OrganizationSidebarContent)
Widget organizationSidebarContentUseCase(BuildContext context) {
  final generator = Generator(context.knobs.seed());
  final requests = context.knobs.object.dropdown(
    label: "Join requests",
    options: const ["None", "Few", "Many"],
    initialOption: "Few",
  );
  return realmStory(
    context,
    traits: [
      membershipService(
        roles: storyRoles,
        joinRequests: storyJoinRequests(generator, switch (requests) {
          "Few" => 3,
          "Many" => 120,
          _ => 0,
        }),
      ),
    ],
  );
}
