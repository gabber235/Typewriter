import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/shell.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The desktop [Sidebar] pane at the left of a window, with help links and
/// the account footer. Drag its edge, or press comma and period, to resize
/// it; it never grows past a third of the window.
@widgetbook.UseCase(name: "Default", type: Sidebar)
Widget sidebarUseCase(BuildContext context) {
  return Story(
    [
      signedIn(ada, organization: acme),
      ...context.knobs.traits("Window", {
        "Desktop": [window(const Size(1280, 800))],
        "Wide": [window(const Size(1920, 1080))],
        "Small": [window(const Size(560, 640))],
      }),
    ],
    at: const PanelLocation.component(
      SizedBox.expand(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Sidebar(child: StorySidebarContent()),
            Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
}
