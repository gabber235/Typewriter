import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Acme's settings page as Ada sees it: the name that saves on its own, the
/// icon that saves when rolled, and the delete hold with its live counts.
///
/// Knobs pick whether Ada founded Acme, whether the counts have arrived,
/// and which commands the backend refuses: a taken name (type "globex") or
/// every delete.
@widgetbook.UseCase(name: "Default", type: OrganizationSettingsPage)
Widget organizationSettingsPageUseCase(BuildContext context) {
  final generator = Generator(context.knobs.seed());
  final founder = context.knobs.boolean(
    label: "Ada founded Acme",
    initialValue: true,
  );
  final counts = context.knobs.object.dropdown(
    label: "Counts",
    options: const ["Arrived", "Loading"],
    initialOption: "Arrived",
  );
  final refusals = context.knobs.object.dropdown(
    label: "Backend refuses",
    options: const ["Nothing", "Taken name globex", "Every delete"],
    initialOption: "Nothing",
  );
  final opened = founder ? acme : organization("Acme", founder: grace);
  return Story(
    [
      signedIn(ada, organization: opened),
      membershipService(
        roles: storyRoles,
        members: counts == "Loading" ? null : storyMembers(generator, 6),
        joinCodes: storyJoinCodes(generator, 3),
      ),
      organizationRefusals(
        takenNames: refusals == "Taken name globex" ? {"globex"} : const {},
        deleteRefusal: refusals == "Every delete" ? founderRequired : null,
      ),
      ...context.knobs.traits("Window", {
        "Desktop": const [],
        "Compact": const [compact],
      }),
      ...context.knobs.traits("Motion", {
        "Full": const [],
        "Reduced": const [reducedMotion],
      }),
    ],
    at: PanelLocation.route(
      organizationPage(const OrganizationSettingsRoute()),
    ),
  );
}

/// What deleting an organization takes with it, counted, or the skeleton of
/// those lines while the counts arrive.
@widgetbook.UseCase(name: "Default", type: OrganizationFootprintList)
Widget organizationFootprintListUseCase(BuildContext context) {
  final loading = context.knobs.boolean(label: "Counts loading");
  final members = context.knobs.int.slider(
    label: "Members",
    initialValue: 3,
    max: 40,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      OrganizationFootprintList(
        footprint: loading
            ? null
            : OrganizationFootprint(
                members: members,
                services: 1,
                joinCodes: 0,
                roles: 2,
              ),
      ),
    ),
  );
}

/// The delete section on its own: the founder holds Delete organization,
/// anyone else sees it unavailable and reads why.
@widgetbook.UseCase(name: "Default", type: OrganizationDeleteSection)
Widget organizationDeleteSectionUseCase(BuildContext context) {
  final founder = context.knobs.boolean(
    label: "Signed in as the founder",
    initialValue: true,
  );
  return Story(
    [signedIn(ada, organization: acme)],
    at: PanelLocation.component(
      OrganizationDeleteSection(
        organization: acme,
        footprint: const OrganizationFootprint(
          members: 4,
          services: 2,
          joinCodes: 1,
          roles: 3,
        ),
        founder: founder,
      ),
    ),
  );
}
