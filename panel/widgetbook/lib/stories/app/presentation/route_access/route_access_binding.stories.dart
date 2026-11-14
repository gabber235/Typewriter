import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/members/membership_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// What the router opens at Acme's services page once [RouteAccessBinding]
/// fed it the session and memberships: the page for a member, the
/// organization picker for someone outside Acme, and the sign in page when
/// signed out.
@widgetbook.UseCase(name: "Default", type: RouteAccessBinding)
Widget routeAccessBindingUseCase(BuildContext context) {
  return Story(
    context.knobs.traits("Access", {
      "Member": [signedIn(ada, organization: acme), servicesService()],
      "Not a member": [
        signedIn(ada, organization: organization("Globex")),
        userBackend(),
      ],
      "Signed out": const [],
    }),
    at: PanelLocation.route(organizationPage(const ServicesRoute())),
  );
}
