import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/portable_resources.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("opening a graph element shows its fields in the inspector", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourcesWorkspaceUseCase,
      knobs: {"Layout": "Graph"},
    );

    await panel.tapOn(find.text("Reward").first);

    expect(visibleFieldValues(), containsAllInOrder(["Reward", "7", "4"]));
  });

  testWidgets("dragging an element on the graph stores its new placement", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourcesWorkspaceUseCase,
      knobs: {"Layout": "Graph"},
    );
    await panel.item("Reward").select();
    expect(visibleFieldValues(), containsAllInOrder(["Reward", "7", "4"]));

    // Two cells right and one down, at 50 pixels a cell.
    await panel.graph.drag("Reward", const Offset(100, 50));
    // Reopening the element reads its placement back from the page.
    await panel.item("Introduction").select();
    await panel.item("Reward").select();

    expect(visibleFieldValues(), containsAllInOrder(["Reward", "9", "5"]));
  });

  testWidgets("editing a name in the inspector renames the element on the "
      "page", (tester) async {
    final panel = await tester.pumpStory(
      resourcesWorkspaceUseCase,
      knobs: {"Layout": "Graph"},
    );
    await panel.tapOn(find.text("Reward").first);

    await panel.fieldAt(0).enter("Treasure");

    expect(panel.shows("Treasure"), isTrue);
    expect(panel.shows("Reward"), isFalse);
  });

  testWidgets("opening a timeline cue shows its frames in the inspector", (
    tester,
  ) async {
    await tester.pumpStory(
      resourcesWorkspaceUseCase,
      knobs: {"Layout": "Timeline"},
    );

    // The cue's label lets taps through to the cue beneath it.
    await tester.tap(find.text("Welcome dialogue").first, warnIfMissed: false);
    await tester.runStory();

    expect(
      visibleFieldValues(),
      containsAllInOrder(["Welcome dialogue", "12", "72"]),
    );
  });

  testWidgets("a timeline track menu offers to disconnect or delete", (
    tester,
  ) async {
    final panel = await tester.pumpStory(
      resourcesWorkspaceUseCase,
      knobs: {"Layout": "Timeline"},
    );

    await panel.tapOn(find.tooltip("Member actions").first);

    expect(panel.shows("Disconnect"), isTrue);
    expect(panel.shows("Delete resource"), isTrue);
  });

  testWidgets("a narrow canvas still shows the graph and the inspector", (
    tester,
  ) async {
    await tester.pumpPanel(
      [window(const Size(550, 720))],
      at: const PanelLocation.component(
        ResourcesWorkspaceStory(timeline: false),
      ),
    );

    expect(find.text("Reward"), findsWidgets);
    expect(visibleFieldValues(), contains("Introduction"));
  });
}
