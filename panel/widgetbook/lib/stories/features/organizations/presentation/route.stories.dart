import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/organization.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The page a signed in user lands on to pick, create or join an
/// organization, with the organizations they belong to and the requests to
/// join they wait on.
@widgetbook.UseCase(name: "Default", type: IndexPage)
Widget indexPageUseCase(BuildContext context) {
  final generator = Generator(context.knobs.seed());
  final organizations = context.knobs.object.dropdown(
    label: "Organizations",
    options: const ["None", "Few", "Many", "Loading"],
    initialOption: "Few",
  );
  final requests = context.knobs.object.dropdown(
    label: "Join requests",
    options: const ["None", "Few", "Request limit reached"],
    initialOption: "None",
  );
  final belongsTo = switch (organizations) {
    "Few" => storyOrganizations(generator, 3),
    "Many" => storyOrganizations(generator, 24),
    _ => const <skir.Organization>[],
  };
  return Story([
    signedIn(ada, others: belongsTo),
    userBackend(
      organizationsArrive: organizations != "Loading",
      joinRequests: storyUserJoinRequests(generator, switch (requests) {
        "Few" => 2,
        "Request limit reached" => 5,
        _ => 0,
      }),
    ),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ], at: const PanelLocation.route(IndexRoute()));
}
