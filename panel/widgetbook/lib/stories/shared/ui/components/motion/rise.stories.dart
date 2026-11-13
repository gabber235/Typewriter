import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A card and a control that [Rise] while Raised, with `hoverIn` or with
/// `capIn`. Under reduced motion nothing travels: the control shows its
/// soft fill instead and the card, like a row, shows nothing.
@widgetbook.UseCase(name: "Default", type: Rise)
Widget riseUseCase(BuildContext context) {
  final raised = context.knobs.boolean(label: "Raised", initialValue: true);
  final token = context.knobs.object.segmented(
    label: "Token",
    options: const [MotionToken.hoverIn, MotionToken.capIn],
    initialOption: MotionToken.hoverIn,
    labelBuilder: (token) => token == MotionToken.hoverIn ? "hoverIn" : "capIn",
  );
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      Builder(
        builder: (context) {
          final radius = context.shapes.mediumBorderRadius;
          return Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 32,
            children: [
              Rise(
                raised: raised,
                token: token,
                borderRadius: radius,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceRaised,
                    borderRadius: radius,
                  ),
                  child: const SizedBox(
                    width: 200,
                    height: 96,
                    child: Center(child: Text("Card")),
                  ),
                ),
              ),
              Rise(
                raised: raised,
                token: token,
                borderRadius: radius,
                stillFill: context.colors.surfaceEmphasized,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text("Control"),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}
