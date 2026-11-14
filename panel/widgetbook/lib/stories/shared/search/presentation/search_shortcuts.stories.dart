import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The keys a search offers, as its key hints show them: the commands of
/// the highlighted result and Space to select it, disabled while a command
/// runs, and Control with a digit to open one of the first nine results.
@widgetbook.UseCase(name: "Default", type: SearchShortcuts)
Widget searchShortcutsUseCase(BuildContext context) {
  final highlighted = context.knobs.boolean(
    label: "Result highlighted",
    initialValue: true,
  );
  final command = context.knobs.object.segmented(
    label: "Command on Arrival",
    options: storyCommandStates.keys.toList(),
    initialOption: "Idle",
  );
  final results = context.knobs.object.segmented(
    label: "Results",
    options: const ["Few", "Many", "Empty"],
    initialOption: "Few",
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: 720,
        height: 480,
        child: StorySearchRoot(
          snapshot: storySearchSnapshots[results]!,
          commandState: storyCommandStates[command]!,
          previewed: highlighted ? storyFirstResultId : null,
          child: SearchShortcuts(
            child: Column(
              children: [
                Expanded(
                  child: SearchTreeResults(
                    rowRenderers: storySearchRowRenderers,
                  ),
                ),
                const ActionRow(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
