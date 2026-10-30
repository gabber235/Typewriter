import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/components/loading_button/action_outcome.dart";
import "package:widgetbook_workspace/support/story.dart";

/// A [FloatingButton] over page content; pressing it runs an action that
/// ends the way the Outcome knob says.
@widgetbook.UseCase(name: "Default", type: FloatingButton)
Widget floatingButtonUseCase(BuildContext context) {
  final outcome = context.knobs.actionOutcome();
  final enabled = context.knobs.boolean(label: "Enabled");
  return Story(
    const [],
    at: PanelLocation.component(
      FloatingButton(
        icon: const Icon(Icons.add),
        onPressed: enabled ? outcome.run : null,
        child: const SizedBox.expand(
          child: Center(child: Text("No join codes yet")),
        ),
      ),
    ),
  );
}
