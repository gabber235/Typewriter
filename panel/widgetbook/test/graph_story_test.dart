import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/shared/graph/presentation/graph.stories.dart";
import "package:widgetbook_workspace/stories/shared/graph/presentation/resizable_element.stories.dart";

import "support/stories.dart";

void main() {
  testWidgets("dragging the resize handle grows the node by whole cells", (
    tester,
  ) async {
    final panel = (await tester.pumpStory(resizableElementUseCase))!;
    expect(panel.shows("Quest 4 x 2"), isTrue);

    await tester.drag(
      find.bySemanticsLabel("Resize"),
      const Offset(ResizableElementStory.cellSize * 2, 0),
    );
    await tester.runStory();

    expect(panel.shows("Quest 6 x 2"), isTrue);
  });

  testWidgets("a graph node keeps the place it is dragged to", (tester) async {
    final panel = (await tester.pumpStory(
      graphUseCase,
      knobs: {"Content": "Simple"},
    ))!;
    double offset() =>
        tester.getRect(find.text("Start")).top -
        tester.getRect(find.text("End")).top;
    final before = offset();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text("Start")),
      kind: PointerDeviceKind.mouse,
    );
    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.runStory();

    expect(panel.shows("Start"), isTrue);
    expect(offset(), greaterThan(before + 40));
  });
}
