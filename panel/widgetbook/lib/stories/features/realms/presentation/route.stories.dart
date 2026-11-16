import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

import "realm_story.dart";

/// The route of one Realm, which opens its authoring session: the realm
/// home while the Realm answers, is checked, is offline or cannot be read.
@widgetbook.UseCase(name: "Default", type: RealmPage)
Widget realmPageUseCase(BuildContext context) {
  return realmStory(context);
}
