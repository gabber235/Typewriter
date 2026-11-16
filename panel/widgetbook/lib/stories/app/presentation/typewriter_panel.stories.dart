import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The whole [TypewriterPanel] where it opens for each session: the sign in
/// page when signed out, the organization picker without an organization,
/// the services page of the first organization, or the Realm a user works
/// in.
@widgetbook.UseCase(name: "Default", type: TypewriterPanel)
Widget typewriterPanelUseCase(BuildContext context) {
  return Story([
    ...context.knobs.traits("Session", {
      "Signed out": const [],
      "Without an organization": [signedIn(ada), userBackend()],
      "In an organization": [
        signedIn(ada, organization: acme),
        servicesService(),
      ],
      "In a Realm": [signedIn(ada, organization: acme), showcaseRealm()],
    }, initial: "In a Realm"),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
  ]);
}
