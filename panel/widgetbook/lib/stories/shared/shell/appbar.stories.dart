import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/authoring/showcase.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The organization the story's user can switch to from the breadcrumbs.
final globex = organization("Globex");

/// The real [CustomAppBar] of an open Realm: organization and Realm
/// breadcrumbs, search, the Realm inbox, the interaction mode and, in a
/// compact window, the sidebar button. Narrower windows collapse its items
/// in their order.
@widgetbook.UseCase(name: "Default", type: CustomAppBar)
Widget customAppBarUseCase(BuildContext context) {
  return Story([
    signedIn(ada, organization: acme, others: [globex]),
    showcaseRealm(),
    ...context.knobs.traits("Window", {
      "Desktop": const [],
      "Narrow": [window(const Size(900, 700))],
      "Compact": const [compact],
      "Phone": [window(const Size(360, 720))],
    }),
  ]);
}
