import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/features/realms/presentation/realm_story.dart";

@widgetbook.UseCase(name: "Default", type: RealmHomePage)
Widget realmHomePageUseCase(BuildContext context) {
  return realmStory(context);
}
