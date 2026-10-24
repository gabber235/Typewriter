import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";
import "../application/selection_test_support.dart";

void main() {
  testWidgets("focused descendants resolve the nearest selectable identity", (
    tester,
  ) async {
    final inside = FocusNode();
    final outside = FocusNode();
    addTearDown(inside.dispose);
    addTearDown(outside.dispose);
    await tester.pumpTestApp(
      child: Column(
        children: [
          SelectableScope(
            id: const MockSelectableIdentifier("outer"),
            child: SelectableScope(
              id: const MockSelectableIdentifier("inner"),
              child: TextField(focusNode: inside),
            ),
          ),
          TextField(focusNode: outside),
        ],
      ),
    );

    inside.requestFocus();
    await tester.pumpAndSettle();
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("inner"),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TextField).first),
    );
    expect(container.read(selectionProvider), isEmpty);

    outside.requestFocus();
    await tester.pumpAndSettle();
    expect(SelectableScope.primaryFocusedId(), isNull);
  });

  testWidgets("changing identity preserves descendant focus and draft", (
    tester,
  ) async {
    final id = ValueNotifier<SelectableIdentifier>(
      const MockSelectableIdentifier("old"),
    );
    addTearDown(id.dispose);
    await tester.pumpTestApp(
      child: ValueListenableBuilder(
        valueListenable: id,
        builder: (context, value, child) {
          return SelectableScope(id: value, child: child!);
        },
        child: const TextField(),
      ),
    );
    await tester.enterText(find.byType(TextField), "draft");
    await tester.pumpAndSettle();
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("old"),
    );

    id.value = const MockSelectableIdentifier("new");
    await tester.pumpAndSettle();
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("new"),
    );
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(before),
    );
    expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
    expect(before.widget.controller.text, "draft");
  });

  testWidgets("global key reparenting updates enclosing focus identity", (
    tester,
  ) async {
    final move = ValueNotifier(false);
    final editorKey = GlobalKey();
    addTearDown(move.dispose);
    await tester.pumpTestApp(
      child: ValueListenableBuilder(
        valueListenable: move,
        builder: (context, moved, _) {
          final editor = TextField(key: editorKey);
          return Row(
            children: [
              Expanded(
                child: SelectableScope(
                  id: const MockSelectableIdentifier("left"),
                  child: moved ? const SizedBox.shrink() : editor,
                ),
              ),
              Expanded(
                child: SelectableScope(
                  id: const MockSelectableIdentifier("right"),
                  child: moved ? editor : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
    await tester.enterText(find.byType(TextField), "draft");
    await tester.pumpAndSettle();
    final before = tester.state<EditableTextState>(find.byType(EditableText));
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("left"),
    );

    move.value = true;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("right"),
    );
    expect(
      tester.state<EditableTextState>(find.byType(EditableText)),
      same(before),
    );
    expect(before.widget.focusNode.hasPrimaryFocus, isTrue);
    expect(before.widget.controller.text, "draft");
  });

  testWidgets("identity boundaries do not add stops to keyboard traversal", (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpTestApp(
      child: Column(
        children: [
          SelectableScope(
            id: const MockSelectableIdentifier("first"),
            child: TextField(focusNode: first),
          ),
          SelectableScope(
            id: const MockSelectableIdentifier("second"),
            child: TextField(focusNode: second),
          ),
        ],
      ),
    );
    first.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(second.hasPrimaryFocus, isTrue);
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("second"),
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(first.hasPrimaryFocus, isTrue);
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("first"),
    );
  });

  testWidgets("graph layout remains safe when its focused editor is removed", (
    tester,
  ) async {
    final width = ValueNotifier(300.0);
    final showEditor = ValueNotifier(true);
    addTearDown(width.dispose);
    addTearDown(showEditor.dispose);
    await tester.pumpTestApp(
      child: AnimatedBuilder(
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
                    ? const SelectableScope(
                        id: MockSelectableIdentifier("editor"),
                        child: TextField(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
    await tester.showKeyboard(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(
      SelectableScope.primaryFocusedId(),
      const MockSelectableIdentifier("editor"),
    );

    width.value = 301;
    showEditor.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.byType(EditableText), findsNothing);
    await tester.pumpAndSettle();
    expect(SelectableScope.primaryFocusedId(), isNull);
  });
}
