import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The search in Acme's app bar: it finds the organizations Ada belongs to,
/// Acme's Realms in every runtime state and the command that creates an
/// organization.
@widgetbook.UseCase(name: "App bar trigger", type: PrimarySearchButton)
Widget primarySearchButtonUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  return Story([
    signedIn(
      ada,
      organization: acme,
      others: storyOrganizations(
        Generator(context.knobs.seed()),
        4,
      ).skip(1).toList(),
    ),
    servicesService(services: scenario.services, topology: scenario.topology),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ], at: PanelLocation.route(organizationPage(const ServicesRoute())));
}

/// The Ctrl or Cmd+K shortcut [PrimarySearchShortcut] registers around the
/// showcase Realm: pressed anywhere in the Realm, it opens the same search
/// with the Realm's Books, pages and tags beside the organizations.
@widgetbook.UseCase(name: "Ctrl K in a Realm", type: PrimarySearchShortcut)
Widget primarySearchShortcutUseCase(BuildContext context) {
  return realmStory(context);
}
