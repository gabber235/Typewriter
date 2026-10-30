import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/data/features/topology.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

@widgetbook.UseCase(name: "Default", type: RealmSelector)
Widget realmSelectorUseCase(BuildContext context) {
  final scenario = completeTopologyScenario();
  return Story([
    signedIn(ada, organization: acme),
    showcaseRealm(),
    ...context.knobs.traits("Realms", {
      "Every runtime state": [
        servicesService(
          services: scenario.services,
          topology: scenario.topology,
        ),
      ],
      "Only this one": const [],
    }),
  ], at: PanelLocation.route(const RealmRouteTree().realm(showcaseScope)));
}
