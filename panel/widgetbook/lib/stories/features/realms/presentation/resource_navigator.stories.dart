import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

import "realm_story.dart";

/// The sidebar's realm area, listing every section of the realm root with
/// the routed one marked.
@widgetbook.UseCase(name: "Realm sections", type: RealmSectionsNavigator)
Widget realmSectionsNavigatorUseCase(BuildContext context) {
  final routed = context.knobs.object.segmented(
    label: "Routed section",
    options: const ["Library", "Tags"],
    initialOption: "Library",
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
          routed: routed == "Tags" ? taxonomyId : libraryId,
        ),
      ),
    ),
  );
}

/// The navigator of one resource as the surface rail shows it: the Books
/// of the library, or the chapter tree of a Book, with the routed resource
/// marked. The header names the resource and opens it.
@widgetbook.UseCase(name: "Rail", type: AuthoredResourceNavigator)
Widget authoredResourceNavigatorUseCase(BuildContext context) {
  final resource = context.knobs.object.segmented(
    label: "Resource",
    options: const ["Library", "Book"],
    initialOption: "Book",
  );
  final header = context.knobs.boolean(label: "Header", initialValue: true);
  final width = context.knobs.width(const {"Rail": 280, "Narrow": 200});
  return Story(
    [signedIn(ada, organization: acme), ...context.knobs.showcaseContent()],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: 640,
        child: SingleChildScrollView(
          child: RealmEditingScene(
            builder: (context, workspace, _) {
              return AuthoredResourceNavigator(
                scope: storyRealmScope,
                resource: resource == "Library"
                    ? libraryId
                    : showcaseBook.bookId,
                routedResource: showcasePage.pageId,
                showHeader: header,
              );
            },
          ),
        ),
      ),
    ),
  );
}
