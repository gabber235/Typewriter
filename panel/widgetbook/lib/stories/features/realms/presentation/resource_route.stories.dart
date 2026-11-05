import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";

@widgetbook.UseCase(name: "Routed resource", type: ResourceSurface)
Widget resourceSurfaceUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown(
    label: "Routed resource",
    options: const ["Page", "Book", "Library", "Tags", "Removed elsewhere"],
    initialOption: "Page",
  );
  return realmStory(
    context,
    target: SurfaceTarget.resource(
      routed: switch (routed) {
        "Book" => showcaseBook.bookId,
        "Library" => libraryId,
        "Tags" => taxonomyId,
        "Removed elsewhere" => skir.ResourceId(value: "page:removed"),
        _ => showcasePage.pageId,
      },
    ),
  );
}
