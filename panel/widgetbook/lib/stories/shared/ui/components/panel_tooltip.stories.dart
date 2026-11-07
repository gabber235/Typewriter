import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A tooltip that waits briefly on hover, then grows out of its control with
/// panelIn and leaves with panelOut.
@widgetbook.UseCase(name: "Default", type: PanelTooltip)
Widget panelTooltipUseCase(BuildContext context) => Story(
  const [],
  at: const PanelLocation.component(
    Center(
      child: PanelTooltip(
        message: "Published to every server in this Realm",
        child: Icon(Icons.public),
      ),
    ),
  ),
);
