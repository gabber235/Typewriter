import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The outcome of the last command under the search field: nothing while
/// idle, the command rippling while it runs, Completed, or the failure,
/// which jams once and stays selectable.
@widgetbook.UseCase(name: "Default", type: SearchCommandInfo)
Widget searchCommandInfoUseCase(BuildContext context) {
  final state = context.knobs.object.segmented(
    label: "Command",
    options: [...storyCommandStates.keys, "Long failure"],
    initialOption: "Running",
  );
  final width = context.knobs.width(const {"Overlay": 640, "Narrow": 300});
  final reduced = context.knobs.boolean(label: "Reduced motion");
  final commandState = state == "Long failure"
      ? SearchCommandExecutionState.failed(
          command: storyOpenCommandId,
          resultIds: const {storyFirstResultId},
          message:
              "The realm did not answer within ten seconds while it was "
              "opening the page, and the connection to its host dropped "
              "twice. Check that the host runs, then press Open page to try "
              "again.",
        )
      : storyCommandStates[state]!;
  return Story(
    [if (reduced) reducedMotion],
    at: PanelLocation.component(
      SizedBox(
        width: width,
        child: StorySearchRoot(
          snapshot: storySearchSnapshots["Few"]!,
          commandState: commandState,
          child: const SearchCommandInfo(),
        ),
      ),
    ),
  );
}
