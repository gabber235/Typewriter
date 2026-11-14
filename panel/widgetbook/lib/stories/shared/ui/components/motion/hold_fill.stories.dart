import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A hold's [HoldFill] frozen at Fill: it sweeps from the leading edge, and
/// under reduced motion grows in place as a tint. Busy shows the pressed in
/// look while the held action runs.
@widgetbook.UseCase(name: "Default", type: HoldFill)
Widget holdFillUseCase(BuildContext context) {
  final fill = context.knobs.fraction("Fill", initialValue: 0.4);
  final busy = context.knobs.boolean(label: "Busy");
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) => Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            HoldFill(
              fill: fill,
              pressed: busy,
              child: const ButtonContent(
                face: ButtonFace.outlined,
                unavailable: false,
                label: Text("Remove member"),
              ),
            ),
            HoldFill(
              fill: fill,
              pressed: busy,
              color: context.holdFillOnFilledColor,
              child: ButtonContent(
                face: ButtonFace.filled,
                color: context.colors.danger,
                unavailable: false,
                label: const Text("Delete resource"),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// How a held button gives way, frozen at Fill: [HoldPress] sinks and
/// shrinks it as far as Weight allows. Under reduced motion nothing sinks.
@widgetbook.UseCase(name: "Default", type: HoldPress)
Widget holdPressUseCase(BuildContext context) {
  final fill = context.knobs.fraction("Fill", initialValue: 0.6);
  final weight = context.knobs.object.segmented(
    label: "Weight",
    options: const [
      MotionToken.holdLight,
      MotionToken.holdHeavy,
      MotionToken.holdPermanent,
    ],
    initialOption: MotionToken.holdHeavy,
    labelBuilder: (token) => switch (token) {
      MotionToken.holdLight => "Light",
      MotionToken.holdPermanent => "Permanent",
      _ => "Heavy",
    },
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) => HoldPress(
          fill: fill,
          share: fill,
          motion: resolveMotion(context, weight),
          child: HoldFill(
            fill: fill,
            child: const ButtonContent(
              face: ButtonFace.outlined,
              unavailable: false,
              label: Text("Remove member"),
            ),
          ),
        ),
      ),
    ),
  );
}
