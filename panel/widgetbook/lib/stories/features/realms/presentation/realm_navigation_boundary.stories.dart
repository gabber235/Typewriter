import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";

import "realm_story.dart";

/// A page of the showcase Realm inside the boundary that keeps a field
/// reveal waiting while the user moves between the Realm's pages, such as
/// opening an issue from the inbox. It draws nothing of its own.
@widgetbook.UseCase(name: "Routed page", type: RealmNavigationBoundary)
Widget realmNavigationBoundaryUseCase(BuildContext context) {
  final routed = context.knobs.object.segmented(
    label: "Routed resource",
    options: const ["Page", "Book"],
    initialOption: "Page",
  );
  return realmStory(
    context,
    target: SurfaceTarget.resource(
      routed: routed == "Book" ? showcaseBook.bookId : showcasePage.pageId,
    ),
  );
}
