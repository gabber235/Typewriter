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
