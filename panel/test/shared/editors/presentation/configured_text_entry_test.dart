import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const amount = InputDecoration(labelText: "Amount");

  testWidgets(
    "completion receives the exact draft once when Escape ends editing",
    (tester) async {
      final completions = <TextEditingValue>[];
      final panel = await tester.showComponent(
        EditorTextField(
          text: "1",
          decoration: amount,
          onCommittedDone: completions.add,
        ),
      );

      await panel.field("Amount").type("01.500");
      await panel.press(LogicalKeyboardKey.escape);
      expect(completions.map((value) => value.text), ["01.500"]);
      FocusManager.instance.primaryFocus?.unfocus();
      await panel.settle();
      expect(completions, hasLength(1));
    },
  );

  testWidgets(
    "completion observes committed composition when blur ends editing",
    (tester) async {
      final completions = <TextEditingValue>[];
      final controller = TextEditingController(text: "a");
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.showComponent(
        EditorTextField(
          controller: controller,
          focusNode: focus,
          decoration: amount,
          onCommittedDone: completions.add,
        ),
      );
      focus.requestFocus();
      await tester.pump();
      controller.value = const TextEditingValue(
        text: "draft",
        selection: TextSelection.collapsed(offset: 5),
        composing: TextRange(start: 0, end: 5),
      );
      expect(completions, isEmpty);
      focus.unfocus();
      await tester.pump();
      expect(completions.single.composing, TextRange.empty);
      controller.value = controller.value.copyWith(composing: TextRange.empty);
      await tester.pump();
      expect(completions.map((value) => value.text), ["draft"]);
      controller.selection = const TextSelection.collapsed(offset: 0);
      expect(completions, hasLength(1));
    },
  );

  testWidgets(
    "display text is replaced by the exact editable representation on focus",
    (tester) async {
      final panel = await tester.showComponent(
        const EditorTextField(
          text: "1.2345",
          displayText: "1.23 kg",
          decoration: amount,
        ),
      );
      final field = panel.field("Amount");

      expect(field.value, "1.23 kg");
      await field.focus();
      expect(field.value, "1.2345");
      FocusManager.instance.primaryFocus?.unfocus();
      await panel.settle();
      expect(field.value, "1.23 kg");
    },
  );

  testWidgets("disposing a focused input never completes an edit", (
    tester,
  ) async {
    final completions = <TextEditingValue>[];
    final panel = await tester.showComponent(
      EditorTextField(
        text: "a",
        decoration: amount,
        onCommittedDone: completions.add,
      ),
    );

    await panel.field("Amount").type("b");
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(completions, isEmpty);
  });

  testWidgets("numeric own echoes preserve precise raw editing text", (
    tester,
  ) async {
    var value = 1.0;
    final panel = await tester.showComponent(
      StatefulBuilder(
        builder: (context, setState) => ValidatedTextField<double>(
          value: value,
          decoration: amount,
          serialize: double.parse,
          deserialize: (value) => value.toString(),
          display: (value) => "${value.toStringAsFixed(1)} units",
          onChanged: (next) => setState(() => value = next),
        ),
      ),
    );
    final field = panel.field("Amount");

    await field.type("01.2300");
    expect(value, 1.23);
    expect(field.value, "01.2300");
    FocusManager.instance.primaryFocus?.unfocus();
    await panel.settle();
    expect(field.value, "1.2 units");
    await field.focus();
    expect(field.value, "1.23");
  });

  testWidgets("intermediate accepted echoes never replace a newer raw draft", (
    tester,
  ) async {
    late StateSetter update;
    var value = 0;
    final panel = await tester.showComponent(
      StatefulBuilder(
        builder: (context, setState) {
          update = setState;
          return ValidatedTextField<int>(
            value: value,
            decoration: amount,
            serialize: int.parse,
            onChanged: (_) {},
          );
        },
      ),
    );
    final field = panel.field("Amount");
    await field.type("1");
    await field.type("12");
    await field.type("123");

    for (final echo in [1, 12, 123]) {
      update(() => value = echo);
      await tester.pump();
      expect(field.value, "123", reason: "after the echo $echo");
    }
    update(() => value = 9);
    await tester.pump();
    expect(field.value, "9");
  });
}
