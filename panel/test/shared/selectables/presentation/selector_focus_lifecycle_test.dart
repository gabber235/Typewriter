import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("focused descendants resolve the nearest selectable identity", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableScope(
              id: TestSelectableIdentifier(id: "outer"),
              child: SelectableScope(
                id: TestSelectableIdentifier(id: "inner"),
                child: const LabeledTextField("Inside"),
              ),
            ),
            const LabeledTextField("Outside"),
          ],
        ),
      ),
    );

    await panel.tapOn(panel.labeled("Inside"));
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "inner"),
    );
    expect(panel.container.read(selectionProvider), isEmpty);

    await panel.tapOn(panel.labeled("Outside"));
    expect(SelectableScope.primaryFocusedId(), isNull);
  });

  testWidgets("changing identity preserves descendant focus and draft", (
    tester,
  ) async {
    final id = ValueNotifier<SelectableIdentifier>(
      TestSelectableIdentifier(id: "old"),
    );
    addTearDown(id.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: id,
          builder: (context, value, child) {
            return SelectableScope(id: value, child: child!);
          },
          child: const LabeledTextField("Editor"),
        ),
      ),
    );
    await tester.enterText(panel.labeled("Editor"), "draft");
    await panel.settle();
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "old"),
    );

    id.value = TestSelectableIdentifier(id: "new");
    await panel.settle();

    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "new"),
    );
    expect(panel.focused, "Editor");
    expect(find.text("draft"), findsOneWidget);
  });

  testWidgets("global key reparenting updates enclosing focus identity", (
    tester,
  ) async {
    final move = ValueNotifier(false);
    final editorKey = GlobalKey();
    addTearDown(move.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        ValueListenableBuilder(
          valueListenable: move,
          builder: (context, moved, _) {
            final editor = LabeledTextField("Editor", key: editorKey);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableScope(
                  id: TestSelectableIdentifier(id: "left"),
                  child: moved ? const SizedBox.shrink() : editor,
                ),
                SelectableScope(
                  id: TestSelectableIdentifier(id: "right"),
                  child: moved ? editor : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.enterText(panel.labeled("Editor"), "draft");
    await panel.settle();
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "left"),
    );

    move.value = true;
    await panel.settle();

    expect(tester.takeException(), isNull);
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "right"),
    );
    expect(panel.focused, "Editor");
    expect(find.text("draft"), findsOneWidget);
  });

  testWidgets("identity boundaries do not add stops to keyboard traversal", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableScope(
              id: TestSelectableIdentifier(id: "first"),
              child: const LabeledTextField("First"),
            ),
            SelectableScope(
              id: TestSelectableIdentifier(id: "second"),
              child: const LabeledTextField("Second"),
            ),
          ],
        ),
      ),
    );
    await panel.tapOn(panel.labeled("First"));

    await panel.press(LogicalKeyboardKey.tab);
    expect(panel.focused, "Second");
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "second"),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await panel.press(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(panel.focused, "First");
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "first"),
    );
  });

  testWidgets("graph layout remains safe when its focused editor is removed", (
    tester,
  ) async {
    final width = ValueNotifier(300.0);
    final showEditor = ValueNotifier(true);
    addTearDown(width.dispose);
    addTearDown(showEditor.dispose);
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        AnimatedBuilder(
          animation: Listenable.merge([width, showEditor]),
          builder: (context, _) {
            return Row(
              children: [
                SizedBox(
                  width: width.value,
                  height: 400,
                  child: Graph(
                    data: GraphData(
                      cellSize: 50,
                      elements: [
                        GraphElement(
                          id: const GraphIdentifier("editor"),
                          x: 0,
                          y: 0,
                          width: 2,
                          height: 2,
                          builder: (_) => const SizedBox.expand(),
                        ),
                      ],
                      edges: const [],
                    ),
                  ),
                ),
                Expanded(
                  child: showEditor.value
                      ? SelectableScope(
                          id: TestSelectableIdentifier(id: "editor"),
                          child: const LabeledTextField("Editor"),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );
          },
        ),
      ),
    );
    await panel.tapOn(panel.labeled("Editor"));
    expect(
      SelectableScope.primaryFocusedId(),
      TestSelectableIdentifier(id: "editor"),
    );

    width.value = 301;
    showEditor.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(panel.shows("Editor"), isFalse);
    await panel.settle();
    expect(SelectableScope.primaryFocusedId(), isNull);
  });
}
