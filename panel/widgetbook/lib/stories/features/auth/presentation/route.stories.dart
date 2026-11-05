import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The page everyone who is signed out lands on.
@widgetbook.UseCase(name: "Default", type: AuthPage)
Widget authPageUseCase(BuildContext context) {
  return Story(
    context.knobs.traits("Window", {
      "Desktop": const [],
      "Compact": const [compact],
    }),
    at: const PanelLocation.route(AuthRoute()),
  );
}
