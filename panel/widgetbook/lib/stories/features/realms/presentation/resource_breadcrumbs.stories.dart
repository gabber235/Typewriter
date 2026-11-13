import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

/// The owner chain of the routed resource in the app bar, one crumb per
/// owner below the realm root.
@widgetbook.UseCase(name: "Owner chain", type: ResourceBreadcrumbs)
Widget resourceBreadcrumbsUseCase(BuildContext context) {
  final routed = context.knobs.object.segmented(
    label: "Routed resource",
    options: const ["Page", "Book", "Library"],
    initialOption: "Page",
  );
  return Story(
    [
      signedIn(ada, organization: acme),
      ...context.knobs.showcaseContent(),
      ...context.knobs.window(),
    ],
    at: PanelLocation.route(
      const RealmRouteTree().surface(
        showcaseScope,
        SurfaceTarget.resource(
          routed: switch (routed) {
            "Book" => showcaseBook.bookId,
            "Library" => libraryId,
            _ => showcasePage.pageId,
          },
        ),
      ),
    ),
  );
}

/// One crumb: the resource it shows, and its siblings in a searchable menu
/// that opens on click. Choosing a sibling opens it.
@widgetbook.UseCase(name: "Siblings", type: ResourceCrumbSelector)
Widget resourceCrumbSelectorUseCase(BuildContext context) {
  final crumb = context.knobs.object.segmented(
    label: "Crumb",
    options: const ["Book", "Page"],
    initialOption: "Book",
  );
  return Story(
    [signedIn(ada, organization: acme), ...context.knobs.showcaseContent()],
    at: PanelLocation.component(
      RealmEditingScene(
        builder: (context, workspace, _) {
          final crumbs = workspace.document.breadcrumbs(showcasePage.pageId);
          return ResourceCrumbSelector(
            scope: storyRealmScope,
            crumb: crumb == "Page" ? crumbs.last : crumbs.first,
          );
        },
      ),
    ),
  );
}
