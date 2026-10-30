import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

@widgetbook.UseCase(name: "Owner chain", type: ResourceBreadcrumbs)
Widget resourceBreadcrumbsUseCase(BuildContext context) {
  return Story(
    [signedIn(ada, organization: acme), showcaseRealm()],
    at: PanelLocation.route(
      const RealmRouteTree().surface(
        showcaseScope,
        SurfaceTarget.resource(routed: showcasePage.pageId),
      ),
    ),
  );
}
