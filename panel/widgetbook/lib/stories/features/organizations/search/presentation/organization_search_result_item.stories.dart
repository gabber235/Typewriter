import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A primary search row for an organization, or for the command that
/// creates one.
@widgetbook.UseCase(name: "Default", type: OrganizationSearchResultItem)
Widget organizationSearchResultItemUseCase(BuildContext context) {
  final organizations = storyOrganizations(Generator(context.knobs.seed()), 3);
  final result = context.knobs.object.dropdown(
    label: "Result",
    options: const ["Organization", "Long name", "Without logo", "Create"],
    initialOption: "Organization",
  );
  final row = context.knobs.object.segmented(
    label: "Row",
    options: const ["Idle", "Focused", "Selected", "Loading"],
    initialOption: "Idle",
  );
  final focused = row == "Focused";
  final selected = row == "Selected";
  final loading = row == "Loading";
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 560,
        child: switch (result) {
          "Create" => CreateOrganizationSearchResultItem(
            focused: focused,
            selected: selected,
            loading: loading,
            onTap: () {},
          ),
          _ => OrganizationSearchResultItem.organization(
            organization: switch (result) {
              "Long name" => organizations[1],
              "Without logo" => organizations[0],
              _ => organizations[2],
            },
            focused: focused,
            selected: selected,
            loading: loading,
            onTap: () {},
          ),
        },
      ),
    ),
  );
}
