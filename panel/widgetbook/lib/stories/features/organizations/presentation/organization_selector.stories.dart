import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The organization switcher in the app bar of Acme's services page; picking
/// another organization opens it.
@widgetbook.UseCase(name: "Default", type: OrganizationSelector)
Widget organizationSelectorUseCase(BuildContext context) {
  final generator = Generator(context.knobs.seed());
  final others = context.knobs.object.dropdown(
    label: "Other organizations",
    options: const ["None", "Few", "Many"],
    initialOption: "Few",
  );
  return Story([
    signedIn(
      ada,
      organization: acme,
      others: storyOrganizations(generator, switch (others) {
        "Few" => 4,
        "Many" => 30,
        _ => 1,
      }).skip(1).toList(),
    ),
    servicesService(),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ], at: PanelLocation.route(organizationPage(const ServicesRoute())));
}
