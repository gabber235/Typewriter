import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/components/loading_button/action_outcome.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Every style of [LoadingButton] side by side; pressing one runs an action
/// that ends the way the Outcome knob says, so idle, busy and failed states
/// can be clicked through.
@widgetbook.UseCase(name: "Default", type: LoadingButton)
Widget loadingButtonUseCase(BuildContext context) {
  final outcome = context.knobs.actionOutcome();
  final enabled = context.knobs.boolean(label: "Enabled");
  final onPressed = enabled ? outcome.run : null;
  return Story(
    const [],
    at: PanelLocation.component(
      Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          LoadingButton.filled(
            onPressed: onPressed,
            child: const Text("Create"),
          ),
          LoadingButton.filledIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.add),
            label: const Text("Create"),
          ),
          LoadingButton.outlined(
            onPressed: onPressed,
            child: const Text("Duplicate"),
          ),
          LoadingButton.outlinedIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.copy),
            label: const Text("Duplicate"),
          ),
          LoadingButton.text(onPressed: onPressed, child: const Text("Retry")),
          LoadingButton.textIcon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
          ),
        ],
      ),
    ),
  );
}
