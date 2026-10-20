import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "realm_showcase_story.dart";

@widgetbook.UseCase(name: "Realm sections", type: RealmSectionsNavigator)
Widget realmSectionsNavigatorUseCase(BuildContext context) {
  final routed = context.knobs.object.dropdown<String>(
    label: "Routed section",
    options: const ["Library", "Tags"],
    initialOption: "Library",
  );
  return RealmShowcaseStory(
    routed: routed == "Tags" ? fixtureTaxonomyId : fixtureLibraryId,
    child: Scaffold(
      body: SizedBox(
        width: 260,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: RealmSectionsNavigator(scope: realmShowcaseScope),
        ),
      ),
    ),
  );
}
