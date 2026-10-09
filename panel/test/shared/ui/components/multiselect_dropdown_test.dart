import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "external controller owns focus across navigation selection and escape",
    (tester) async {
      final field = InputFieldController();
      addTearDown(field.dispose);
      final selected = <String>[];

      await tester.pumpTestApp(
        child: MultiselectDropdown<String>(
          inputFieldController: field,
          dropdownMenuEntries: const [
            DropdownMenuEntry(value: "alpha", label: "Alpha"),
            DropdownMenuEntry(
              value: "blocked",
              label: "Blocked",
              enabled: false,
            ),
            DropdownMenuEntry(value: "beta", label: "Beta"),
          ],
          onSelectionChanged: (items) => selected
            ..clear()
            ..addAll(items),
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

      await tester.pumpTestApp(
        child: Focus(focusNode: field.inputFocusNode, child: const SizedBox()),
      );
      field.requestInputFocus();
      await tester.pump();
      expect(field.inputFocusNode.hasPrimaryFocus, isTrue);
    },
  );

  testWidgets("standalone dropdown owns its focus controller", (tester) async {
    List<String>? selected;
    await tester.pumpTestApp(
      child: MultiselectDropdown<String>(
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: "alpha", label: "Alpha"),
          DropdownMenuEntry(value: "beta", label: "Beta"),
        ],
        onSelectionChanged: (items) => selected = items,
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

    await tester.pumpTestApp(
      child: MultiselectDropdown<String>(
        inputFieldController: field,
        enabled: false,
        dropdownMenuEntries: const [
          DropdownMenuEntry(value: "alpha", label: "Alpha"),
        ],
        onSelectionChanged: selected.addAll,
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selected, isEmpty);
    expect(find.text("Alpha"), findsNothing);
  });
}
