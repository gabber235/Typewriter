import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("clearing is optional and invalid drafts retain the value", (
    tester,
  ) async {
    final values = <int>[];
    var clears = 0;
    Widget field({required bool clearable}) => testApp(
      child: Scaffold(
        body: ValidatedTextField<int>(
          value: 7,
          serialize: int.parse,
          onChanged: values.add,
          onCleared: clearable ? () => clears++ : null,
        ),
      ),
    );

    await tester.pumpWidget(field(clearable: false));
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pump();
    expect(values, isEmpty);
    expect(clears, 0);

    await tester.pumpWidget(field(clearable: true));
    await tester.enterText(find.byType(TextFormField), "invalid");
    await tester.pump();
    expect(values, isEmpty);
    expect(clears, 0);

    await tester.enterText(find.byType(TextFormField), "9");
    await tester.pumpAndSettle();
    expect(values, [9]);

    await tester.enterText(find.byType(TextFormField), " ");
    await tester.pumpAndSettle();
    expect(values, [9]);
    expect(clears, 1);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(clears, 1);
  });

  testWidgets("an external empty value clears text without editing", (
    tester,
  ) async {
    final edits = <int>[];
    var clears = 0;
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Widget field(int? value) => _synchronizedField(
      value: value,
      controller: controller,
      onChanged: edits.add,
      onCleared: () => clears++,
    );

    await tester.pumpWidget(field(7));
    expect(controller.text, "7");

    await tester.pumpWidget(field(null));
    expect(controller.text, isEmpty);
    expect(edits, isEmpty);
    expect(clears, 0);
  });

  testWidgets("an external replacement clears a blurred draft error", (
    tester,
  ) async {
    final edits = <int>[];
    final completions = <int>[];
    var clears = 0;
    var blurs = 0;
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    Widget field(int value) => _synchronizedField(
      value: value,
      controller: controller,
      focusNode: focus,
      onChanged: edits.add,
      onCleared: () => clears++,
      onDone: completions.add,
      onInputBlur: () => blurs++,
    );

    await tester.pumpWidget(field(7));
    await tester.enterText(find.byType(TextFormField), "invalid");
    await tester.pumpAndSettle();
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(controller.text, "invalid");
    expect(find.text("Enter a whole number"), findsOneWidget);
    expect(blurs, 1);
    expect(completions, isEmpty);

    await tester.pumpWidget(field(9));
    await tester.pumpAndSettle();
    expect(controller.text, "9");
    expect(find.text("Enter a whole number"), findsNothing);
    expect(edits, isEmpty);
    expect(completions, isEmpty);
    expect(clears, 0);
    expect(blurs, 1);
  });

  for (final replacement in <int?>[9, null]) {
    testWidgets(
      "a focused field synchronizes external ${replacement == null ? "reset" : "replacement"} immediately",
      (tester) async {
        final edits = <int>[];
        final completions = <int>[];
        var clears = 0;
        var blurs = 0;
        final controller = TextEditingController();
        final focus = FocusNode();
        addTearDown(controller.dispose);
        addTearDown(focus.dispose);
        Widget field(int? value) => _synchronizedField(
          value: value,
          controller: controller,
          focusNode: focus,
          onChanged: edits.add,
          onCleared: () => clears++,
          onDone: completions.add,
          onInputBlur: () => blurs++,
        );

        await tester.pumpWidget(field(7));
        await tester.enterText(find.byType(TextFormField), "invalid");
        controller.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 4,
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(field(replacement));
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isTrue);
        expect(controller.text, replacement?.toString() ?? "");
        final length = controller.text.length;
        expect(
          controller.selection,
          TextSelection(
            baseOffset: 1.clamp(0, length),
            extentOffset: 4.clamp(0, length),
          ),
        );
        expect(find.text("Enter a whole number"), findsNothing);

        focus.unfocus();
        await tester.pumpAndSettle();
        expect(controller.text, replacement?.toString() ?? "");
        expect(find.text("Enter a whole number"), findsNothing);
        expect(blurs, 1);
        expect(completions, replacement == null ? isEmpty : [replacement]);

        focus.requestFocus();
        await tester.pumpAndSettle();
        expect(controller.text, replacement?.toString() ?? "");
        expect(find.text("Enter a whole number"), findsNothing);
        expect(edits, isEmpty);
        expect(completions, replacement == null ? isEmpty : [replacement]);
        expect(clears, 0);
        expect(blurs, 1);
      },
    );
  }
}

Widget _synchronizedField({
  required int? value,
  required TextEditingController controller,
  required ValueChanged<int> onChanged,
  required VoidCallback onCleared,
  FocusNode? focusNode,
  ValueChanged<int>? onDone,
  VoidCallback? onInputBlur,
}) => testApp(
  child: Scaffold(
    body: ValidatedTextField<int>(
      key: const ValueKey("controlled number"),
      value: value,
      controller: controller,
      focusNode: focusNode,
      serialize: (draft) =>
          int.tryParse(draft) ??
          (throw const FormatException("Enter a whole number")),
      onChanged: onChanged,
      onCleared: onCleared,
      onDone: onDone,
      onInputBlur: onInputBlur,
    ),
  ),
);
