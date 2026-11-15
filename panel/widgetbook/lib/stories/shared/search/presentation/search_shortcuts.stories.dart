import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/data/shared/search.dart";
import "package:widgetbook_workspace/support/story.dart";

/// The keys a search offers wherever its focus is, as its key hints show
/// them: Control with a digit opens one of the first nine results. A
/// result's commands belong to its row and show while it has focus.
@widgetbook.UseCase(name: "Default", type: SearchShortcuts)
Widget searchShortcutsUseCase(BuildContext context) {
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
