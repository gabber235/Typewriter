import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The live member list without its page: a table on desktop, cards on
/// smaller windows, a skeleton while loading and the failure when the
/// membership service is unreachable. Selecting members shows the bulk bar.
@widgetbook.UseCase(name: "Default", type: MembersTab)
Widget membersTabUseCase(BuildContext context) {
  final amount = context.knobs.object.dropdown(
    label: "Members",
    options: const ["None", "Few", "Many", "Loading", "Failing"],
    initialOption: "Few",
  );
  final generator = Generator(context.knobs.seed());
  return Story(
    [
      membership(
        roles: storyRoles,
        members: switch (amount) {
          "None" => const [],
          "Few" => storyMembers(generator, 6),
          "Many" => storyMembers(generator, 60),
          _ => null,
        },
        failure: amount == "Failing"
            ? StateError("The membership service is unreachable")
            : null,
      ),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: const PanelLocation.component(StorySliverPane(slivers: [MembersTab()])),
  );
}
