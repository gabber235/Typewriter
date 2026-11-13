import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/design_system/hold_weights.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Hold each button to feel its weight: Discard draft is light, Remove
/// member heavy, Delete resource permanent.
@widgetbook.UseCase(name: "Hold weights", type: CommandButton)
Widget holdWeightsUseCase(BuildContext context) {
  return Story([
    ...context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
  ], at: const PanelLocation.component(HoldWeights()));
}
