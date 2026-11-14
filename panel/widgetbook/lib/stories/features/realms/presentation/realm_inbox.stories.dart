import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/data/features/publication.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

const _noRealm = "No realm open";

/// The review of the showcase Realm, as the organization app bar shows it:
/// the inbox button opens it, and outside a Realm the activity button
/// shows the organization's own saves instead.
@widgetbook.UseCase(name: "Live review", type: RealmInboxButton)
Widget realmInboxButtonUseCase(BuildContext context) {
  final review = context.knobs.object.dropdown(
    label: "Review",
    options: [...storyPublications.keys, _noRealm],
    initialOption: "Ready",
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      showcaseRealm(),
      ...?storyPublications[review],
      ...context.knobs.traits("Window", {
        "Desktop": const [],
        "Compact": const [compact],
      }),
    ],
    at: PanelLocation.route(
      review == _noRealm
          ? OrganizationRoute(
              organizationId: acme.organizationId.id,
              children: const [ServicesRoute()],
            )
          : const RealmRouteTree().realm(showcaseScope),
    ),
  );
}

/// The app bar's activity control: inside a Realm it is the realm inbox,
/// outside one the organization's own saves.
@widgetbook.UseCase(
  name: "Inside and outside a Realm",
  type: WorkspaceActivityButton,
)
Widget workspaceActivityButtonUseCase(BuildContext context) {
  final place = context.knobs.object.segmented(
    label: "Place",
    options: const ["Realm", "Organization"],
    initialOption: "Realm",
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      showcaseRealm(),
      ...?storyPublications["Ready"],
      ...context.knobs.window(),
    ],
    at: PanelLocation.route(
      place == "Organization"
          ? OrganizationRoute(
              organizationId: acme.organizationId.id,
              children: const [ServicesRoute()],
            )
          : const RealmRouteTree().realm(showcaseScope),
    ),
  );
}

/// The realm page, where Shift+P in Normal mode opens the realm inbox.
/// While the Realm is offline or checking, the key does nothing.
@widgetbook.UseCase(name: "Shift P opens the inbox", type: RealmInboxShortcut)
Widget realmInboxShortcutUseCase(BuildContext context) {
  return realmStory(context, traits: [...?storyPublications["Ready"]]);
}

/// The review inline, at the width of the popup or a wide surface.
@widgetbook.UseCase(name: "Provider owned review", type: RealmInboxContent)
Widget realmInboxContentUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: "Surface width",
    initialValue: 760,
    min: 280,
    max: 1200,
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      showcaseRealm(),
      ...context.knobs.traits("Review", storyPublications),
    ],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 720,
        child: Material(
          child: RealmInboxContent(scope: showcaseScope, onClose: () {}),
        ),
      ),
    ),
  );
}
