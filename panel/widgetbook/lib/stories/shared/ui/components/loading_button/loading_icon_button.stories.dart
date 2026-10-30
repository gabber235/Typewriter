import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/ui/components/loading_button/action_outcome.dart";
import "package:widgetbook_workspace/support/story.dart";

/// Every style of [LoadingIconButton] side by side, running an action that
/// ends the way the Outcome knob says.
@widgetbook.UseCase(name: "Default", type: LoadingIconButton)
Widget loadingIconButtonUseCase(BuildContext context) {
  final outcome = context.knobs.actionOutcome();
  final enabled = context.knobs.boolean(label: "Enabled");
  final onPressed = enabled ? outcome.run : null;
  return Story(
    const [],
    at: PanelLocation.component(
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          LoadingIconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: onPressed,
          ),
          LoadingIconButton.filled(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: onPressed,
          ),
          LoadingIconButton.outlined(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
            onPressed: onPressed,
          ),
        ],
      ),
    ),
  );
}
