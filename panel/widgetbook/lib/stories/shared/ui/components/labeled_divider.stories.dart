import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// A [LabeledDivider] between two ways to sign in, lying across a column or
/// standing between two side by side choices; Label tries a longer word.
@widgetbook.UseCase(name: "Default", type: LabeledDivider)
Widget labeledDividerUseCase(BuildContext context) {
  final direction = context.knobs.object.segmented(
    label: "Direction",
    options: Axis.values,
    initialOption: Axis.horizontal,
    labelBuilder: (axis) => axis.name,
  );
  final text = context.knobs.object.segmented(
    label: "Label",
    options: const ["OR", "Or continue with"],
    initialOption: "OR",
  );
  final width = context.knobs.width(const {"Wide": 420, "Narrow": 220});
  const first = Text("Sign in with a join code");
  const second = Text("Sign in with an email");
  final divider = LabeledDivider(text: text, direction: direction);
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        height: direction == Axis.vertical ? 160 : null,
        child: direction == Axis.horizontal
            ? Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [first, divider, second],
              )
            : Row(
                spacing: 12,
                children: [
                  const Expanded(child: first),
                  divider,
                  const Expanded(child: second),
                ],
              ),
      ),
    ),
  );
}
