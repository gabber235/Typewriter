import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("arrow activation uses the same input interaction", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    await _pumpDropdown(tester, controller);
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    expect(_menu(tester).isOpen, isTrue);
    expect(controller.inputFocusNode.hasPrimaryFocus, isTrue);
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(_menu(tester).isOpen, isFalse);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("keyboard activation opens choices through the input container", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    await _pumpDropdown(tester, controller);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(controller.inputFocusNode.hasPrimaryFocus, isTrue);
    expect(_menu(tester).isOpen, isTrue);
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<InsertMode>(),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Beta",
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_menu(tester).isOpen, isFalse);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });

  testWidgets("escape closes choices and returns to field navigation", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    await _pumpDropdown(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(_menu(tester).isOpen, isTrue);
    await tester.enterText(find.byType(TextField), "Be");
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(_menu(tester).isOpen, isFalse);
    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Alpha",
    );
  });

  testWidgets("leaving the input closes choices without trapping focus", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    await _pumpDropdown(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    expect(_menu(tester).isOpen, isFalse);
    expect(
      Focus.of(tester.element(find.text("Next control"))).hasPrimaryFocus,
      isTrue,
    );
    expect(
      tester.container().read(currentInteractionModeProvider),
      isA<NormalMode>(),
    );
  });

  testWidgets("selection restores a visible field focus highlight", (
    tester,
  ) async {
    final controller = InputFieldController();
    addTearDown(controller.dispose);
    await _pumpDropdown(tester, controller);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Beta").last);
    await tester.pumpAndSettle();

    expect(controller.surroundingFocusNode.hasPrimaryFocus, isTrue);
    final highlight = tester.widget<FocusHighlight>(
      find
          .descendant(
            of: find.byType(InputFieldContainer),
            matching: find.byType(FocusHighlight),
          )
          .first,
    );
    expect(highlight.type, FocusType.focus);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      "Beta",
    );
  });
}

MenuController _menu(WidgetTester tester) =>
    tester.widget<MenuAnchor>(find.byType(MenuAnchor)).controller!;

Future<void> _pumpDropdown(
  WidgetTester tester,
  InputFieldController controller,
) => tester.pumpTestApp(
  child: SizedBox(
    width: 360,
    child: HookBuilder(
      builder: (context) {
        final selected = useState("alpha");
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Dropdown<String>(
              inputFieldController: controller,
              selected: selected.value,
              dropdownMenuEntries: const [
                DropdownMenuEntry(value: "alpha", label: "Alpha"),
                DropdownMenuEntry(
                  value: "unavailable",
                  label: "Unavailable",
                  enabled: false,
                ),
                DropdownMenuEntry(value: "beta", label: "Beta"),
              ],
              onSelected: (value) {
                if (value != null) selected.value = value;
              },
            ),
            TextButton(onPressed: () {}, child: const Text("Next control")),
          ],
        );
      },
    ),
  ),
);
