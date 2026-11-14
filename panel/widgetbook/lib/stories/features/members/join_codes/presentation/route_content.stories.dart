import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/membership.dart";
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The join codes tab without its page: the generator card with its
/// advanced options, then the active codes as a table on desktop and cards
/// on smaller windows. Roles load apart from the codes, so either can be
/// loading or failing.
@widgetbook.UseCase(name: "Default", type: JoinCodesTab)
Widget joinCodesTabUseCase(BuildContext context) {
  final amount = context.knobs.object.dropdown(
    label: "Join codes",
    options: const ["None", "Few", "Many", "Loading", "Failing"],
    initialOption: "Few",
  );
  final generator = Generator(context.knobs.seed());
  return Story(
    [
      membership(
        roles: amount == "Loading" ? null : storyRoles,
        joinCodes: switch (amount) {
          "None" => const [],
          "Few" => storyJoinCodes(generator, 6),
          "Many" => storyJoinCodes(generator, 60),
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
      StorySliverPane(slivers: [JoinCodesTab()]),
    ),
  );
}
