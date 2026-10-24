import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "realm_showcase_story.dart";

@widgetbook.UseCase(name: "Routed resource", type: ResourceSurface)
Widget resourceSurfaceUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown<String>(
    label: "Routed resource",
    options: const ["Page", "Book", "Library", "Tags"],
    initialOption: "Page",
  );
  final resource = switch (routed) {
    "Book" => fixtureShowcaseBook,
    "Library" => fixtureLibraryId,
    "Tags" => fixtureTaxonomyId,
    _ => fixtureShowcasePage,
  };
  return RealmShowcaseStory(
    routed: resource,
    child: Scaffold(
      body: ResourceSurface(scope: realmShowcaseScope, resource: resource),
    ),
  );
}

@widgetbook.UseCase(name: "Narrow surface rail", type: ResourceRailMenuButton)
Widget resourceRailMenuButtonUseCase(BuildContext context) =>
    RealmShowcaseStory(
      routed: fixtureShowcasePage,
      child: Scaffold(
        body: Center(
          child: ResourceRailMenuButton(
            scope: realmShowcaseScope,
            rail: fixtureShowcaseBook,
            routedResource: fixtureShowcasePage,
          ),
        ),
      ),
    );
