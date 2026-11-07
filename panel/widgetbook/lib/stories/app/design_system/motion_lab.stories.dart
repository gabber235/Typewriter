import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/design_system/motion_lab.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Pick each token's value: three live options of one token on real panel
/// widgets, with reduced motion and replay.
@widgetbook.UseCase(
  name: "Motion lab",
  type: MotionLab,
  path: "app/design_system",
)
Widget motionLabUseCase(BuildContext context) {
  final token = context.knobs.object.dropdown<MotionToken<Landing>>(
    label: "Token",
    options: MotionToken.values,
    initialOption: MotionToken.rowIn,
    labelBuilder: (token) => token.name,
  );
  return Story([
    ...context.knobs.traits("Motion", {
      "Full": const [],
      "Reduced": const [reducedMotion],
    }),
  ], at: PanelLocation.component(MotionLab(token: token)));
}
