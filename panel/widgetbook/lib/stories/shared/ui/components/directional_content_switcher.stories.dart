import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

const _steps = ["Name", "Members", "Review"];

/// A [DirectionalContentSwitcher] stepping through a three step flow: a
/// later step slides in from the right, an earlier one from the left.
@widgetbook.UseCase(name: "Default", type: DirectionalContentSwitcher)
Widget directionalContentSwitcherUseCase(BuildContext context) {
  final step = context.knobs.object.segmented(
    label: "Step",
    options: _steps,
    initialOption: _steps.first,
  );
  final index = _steps.indexOf(step);
  return Story(
    context.knobs.motion(),
    at: PanelLocation.component(
      StoryCard(
        width: 320,
        height: 120,
        child: ClipRect(
          child: DirectionalContentSwitcher(
            index: index,
            child: Center(
              key: ValueKey(step),
              child: Text("Step ${index + 1}: $step"),
            ),
          ),
        ),
      ),
    ),
  );
}
