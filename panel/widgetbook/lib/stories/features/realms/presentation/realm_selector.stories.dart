import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

/// The realm switcher in the app bar of the showcase Realm. Its menu lists
/// every realm of the organization with its runtime state; choosing one
/// opens it.
@widgetbook.UseCase(name: "Default", type: RealmSelector)
Widget realmSelectorUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  return Story([
    signedIn(ada, organization: acme),
    ...context.knobs.showcaseContent(),
    ...context.knobs.traits("Realms", {
      "Every runtime state": [
        servicesService(
          services: scenario.services,
          topology: scenario.topology,
        ),
      ],
      "Only this one": const [],
      "Checking": [servicesService(topologyArrives: false)],
    }),
    ...context.knobs.window(),
  ], at: PanelLocation.route(const RealmRouteTree().realm(showcaseScope)));
}
