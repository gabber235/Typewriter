import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "external controller owns focus across navigation selection and escape",
    (tester) async {
      final field = InputFieldController();
      addTearDown(field.dispose);
      final selected = <String>[];

      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          MultiselectDropdown<String>(
            inputFieldController: field,
            dropdownMenuEntries: const [
              MenuChoice(value: "alpha", label: "Alpha"),
              MenuChoice(value: "blocked", label: "Blocked", enabled: false),
              MenuChoice(value: "beta", label: "Beta"),
            ],
            onSelectionChanged: (items) => selected
              ..clear()
              ..addAll(items),
          ),
        ),
      );

      field.requestInputFocus();
      await tester.pumpAndSettle();
      expect(field.inputFocusNode.hasPrimaryFocus, isTrue);
      expect(find.text("Alpha"), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, ["beta"]);

      await tester.tap(find.text("Blocked"));
      await tester.pump();
      expect(selected, ["beta"]);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(field.surroundingFocusNode.hasPrimaryFocus, isTrue);

      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          Focus(focusNode: field.inputFocusNode, child: const SizedBox()),
        ),
      );
      field.requestInputFocus();
      await tester.pump();
      expect(field.inputFocusNode.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets("standalone dropdown owns its focus controller", (tester) async {
    List<String>? selected;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        MultiselectDropdown<String>(
          dropdownMenuEntries: const [
            MenuChoice(value: "alpha", label: "Alpha"),
            MenuChoice(value: "beta", label: "Beta"),
          ],
          onSelectionChanged: (items) => selected = items,
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, ["alpha"]);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets("disabled dropdown cannot change selection", (tester) async {
    final field = InputFieldController();
    addTearDown(field.dispose);
    final selected = <String>[];

    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        MultiselectDropdown<String>(
          inputFieldController: field,
          enabled: false,
          dropdownMenuEntries: const [
            MenuChoice(value: "alpha", label: "Alpha"),
          ],
          onSelectionChanged: selected.addAll,
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, isEmpty);
    expect(find.text("Alpha"), findsNothing);
  });

  testWidgets("the choices leave into the field", (tester) async {
    final field = InputFieldController();
    addTearDown(field.dispose);
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        MultiselectDropdown<String>(
          inputFieldController: field,
          dropdownMenuEntries: const [
            MenuChoice(value: "alpha", label: "Alpha"),
            MenuChoice(value: "beta", label: "Beta"),
          ],
          onSelectionChanged: (_) {},
        ),
      ),
    );
    field.requestInputFocus();
    await tester.pumpAndSettle();
    expect(find.text("Alpha"), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    // The choices go back into the field; they do not vanish.
    expect(find.text("Alpha"), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text("Alpha"), findsNothing);
    expect(field.surroundingFocusNode.hasPrimaryFocus, isTrue);
  });
}
