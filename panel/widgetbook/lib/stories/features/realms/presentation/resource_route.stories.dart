import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/stories/authoring/presentation/realm_story.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The resources a surface story can route to, by the name a story knob
/// shows.
skir.ResourceId _routed(String name) => switch (name) {
  "Book" => showcaseBook.bookId,
  "Library" => libraryId,
  "Tags" => taxonomyId,
  "Removed elsewhere" => skir.ResourceId(value: "page:removed"),
  _ => showcasePage.pageId,
};

@widgetbook.UseCase(name: "Routed resource", type: ResourceSurface)
Widget resourceSurfaceUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown(
    label: "Routed resource",
    options: const ["Page", "Book", "Library", "Tags", "Removed elsewhere"],
    initialOption: "Page",
  );
  return realmStory(
    context,
    target: SurfaceTarget.resource(routed: _routed(routed)),
  );
}

/// The page a resource's address opens: its surface, or that it is gone.
@widgetbook.UseCase(name: "Resource address", type: ResourcePage)
Widget resourcePageUseCase(BuildContext context) {
  final routed = context.knobs.object.segmented(
    label: "Routed resource",
    options: const ["Page", "Book", "Removed elsewhere"],
    initialOption: "Page",
  );
  return realmStory(
    context,
    target: SurfaceTarget.resource(routed: _routed(routed)),
  );
}

/// The menu button a narrow surface shows in its heading; it opens the
/// rail navigator in a sheet, and choosing a member closes the sheet.
@widgetbook.UseCase(name: "Narrow surface", type: ResourceRailMenuButton)
Widget resourceRailMenuButtonUseCase(BuildContext context) {
  final rail = context.knobs.object.segmented(
    label: "Rail",
    options: const ["Book", "Library"],
    initialOption: "Book",
  );
  return Story(
    [signedIn(ada, organization: acme), ...context.knobs.showcaseContent()],
    at: PanelLocation.component(
      RealmEditingScene(
        builder: (context, workspace, _) {
          return ResourceRailMenuButton(
            scope: storyRealmScope,
            rail: rail == "Library" ? libraryId : showcaseBook.bookId,
            routedResource: showcasePage.pageId,
          );
        },
      ),
    ),
  );
}

/// The heading of a surface: the routed resource's icon, name and
/// description in its accent, the issues found on it, and a create button
/// for each further kind it owns.
@widgetbook.UseCase(name: "Default", type: ResourceHeading)
Widget resourceHeadingUseCase(BuildContext context) {
  final routed = context.knobs.object.segmented(
    label: "Routed resource",
    options: const ["Page", "Book", "Library", "Tags"],
    initialOption: "Page",
  );
  final leading = context.knobs.boolean(label: "Rail menu");
  final width = context.knobs.width(const {"Wide": 760, "Narrow": 320});
  final resource = _routed(routed);
  return Story(
    [signedIn(ada, organization: acme), ...context.knobs.showcaseContent()],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: RealmEditingScene(
          builder: (context, workspace, _) {
            return ResourceHeading(
              scope: storyRealmScope,
              resource: resource,
              leading: leading
                  ? ResourceRailMenuButton(
                      scope: storyRealmScope,
                      rail: libraryId,
                      routedResource: resource,
                    )
                  : null,
            );
          },
        ),
      ),
    ),
  );
}
