import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The join requests tab without its page: the request cards, a skeleton
/// while they load, and the failure when the membership service is
/// unreachable.
@widgetbook.UseCase(name: "Default", type: JoinRequestsTab)
Widget joinRequestsTabUseCase(BuildContext context) {
  final amount = context.knobs.object.dropdown(
    label: "Join requests",
    options: const ["None", "Few", "Many", "Loading", "Failing"],
    initialOption: "Few",
  );
  final generator = Generator(context.knobs.seed());
  return Story(
    [
      membership(
        roles: storyRoles,
        joinRequests: switch (amount) {
          "None" => const [],
          "Few" => storyJoinRequests(generator, 6),
          "Many" => storyJoinRequests(generator, 60),
          _ => null,
        },
        failure: amount == "Failing"
            ? StateError("The membership service is unreachable")
            : null,
      ),
      ...context.knobs.windows(),
      ...context.knobs.motion(),
    ],
    at: const PanelLocation.component(
      StorySliverPane(slivers: [JoinRequestsTab()]),
    ),
  );
}
