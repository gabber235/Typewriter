import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Where the [showcaseRealm] lives: Acme's Realm `main`.
final showcaseScope = AuthoringScope(
  organizationId: acme.organizationId,
  realmId: skir.recordId("realm_instance:main"),
);

/// The showcase Realm opened at [target] as Ada sees it, with knobs for
/// how the Realm answers and the window, plus [traits] of the story.
Widget realmStory(
  BuildContext context, {
  SurfaceTarget target = const SurfaceTarget.home(),
  List<Trait> traits = const [],
}) {
  return Story(
    [
      signedIn(ada, organization: acme),
      showcaseRealm(),
      ...traits,
      ...context.knobs.traits("Realm", {
        "Online": const [],
        "Host offline": const [realmHostStopped],
        "Checking": [servicesService(topologyArrives: false)],
        "Unavailable": [
          servicesService(
            topologyArrives: false,
            failure: StateError("The topology could not be read"),
          ),
        ],
        "Content unreadable": [
          realmDocumentFails(StateError("The Realm did not answer")),
        ],
      }),
      ...context.knobs.traits("Window", {
        "Desktop": const [],
        "Compact": const [compact],
      }),
    ],
    at: PanelLocation.route(
      const RealmRouteTree().surface(showcaseScope, target),
    ),
  );
}
