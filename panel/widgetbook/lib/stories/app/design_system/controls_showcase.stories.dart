import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/design_system/controls_showcase.dart";
import "package:widgetbook_workspace/support/story.dart";

@widgetbook.UseCase(
  name: "Default",
  type: ControlsShowcase,
  path: "app/design_system",
)
Widget controlsShowcaseUseCase(BuildContext context) {
  return const Story([], at: PanelLocation.component(ControlsShowcase()));
}
