import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a field that cannot be cleared ignores an empty draft", (
    tester,
  ) async {
    final values = <int>[];
    await tester.showNumberField(
      value: testNotifier<int?>(7),
      onChanged: values.add,
    );

    await tester.enterText(find.bySemanticsLabel("Amount"), "");
    await tester.pump();

    expect(values, isEmpty);
  });

  testWidgets("a clearable field clears on a blank draft and keeps invalid "
      "drafts out of the value", (tester) async {
    final values = <int>[];
    var clears = 0;
    await tester.showNumberField(
      value: testNotifier<int?>(7),
      onChanged: values.add,
      onCleared: () => clears++,
    );

    await tester.enterText(find.bySemanticsLabel("Amount"), "invalid");
    await tester.pump();
    expect(values, isEmpty);
    expect(clears, 0);

    await tester.enterText(find.bySemanticsLabel("Amount"), "9");
    await tester.pumpAndSettle();
    expect(values, [9]);

    await tester.enterText(find.bySemanticsLabel("Amount"), " ");
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
    final value = testNotifier<int?>(7);
    await tester.showNumberField(
      value: value,
      controller: controller,
      onChanged: edits.add,
      onCleared: () => clears++,
    );
    expect(controller.text, "7");

    value.value = null;
    await tester.pump();
    expect(controller.text, isEmpty);
    expect(edits, isEmpty);
    expect(clears, 0);
  });

  testWidgets("an external replacement clears a blurred draft error", (
    tester,
  ) async {
    final value = testNotifier<int?>(7);
    final field = await tester.showWatchedNumberField(value);
    final WatchedNumberField(:controller, :focus) = field;
    await tester.enterText(find.bySemanticsLabel("Amount"), "invalid");
    await tester.pumpAndSettle();
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(controller.text, "invalid");
    expect(find.text("Enter a whole number"), findsOneWidget);
    expect(field.blurs, 1);
    expect(field.completions, isEmpty);

    value.value = 9;
    await tester.pump();
    await tester.pumpAndSettle();
    expect(controller.text, "9");
    expect(find.text("Enter a whole number"), findsNothing);
    expect(field.edits, isEmpty);
    expect(field.completions, isEmpty);
    expect(field.clears, 0);
    expect(field.blurs, 1);
  });

  for (final replacement in <int?>[9, null]) {
    testWidgets(
      "a focused field synchronizes external ${replacement == null ? "reset" : "replacement"} immediately",
      (tester) async {
        final value = testNotifier<int?>(7);
        final field = await tester.showWatchedNumberField(value);
        final WatchedNumberField(:controller, :focus) = field;
        await tester.enterText(find.bySemanticsLabel("Amount"), "invalid");
        controller.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 4,
        );
        await tester.pumpAndSettle();

        value.value = replacement;
        await tester.pump();
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
        expect(field.blurs, 1);
        expect(
          field.completions,
          replacement == null ? isEmpty : [replacement],
        );

        focus.requestFocus();
        await tester.pumpAndSettle();
        expect(controller.text, replacement?.toString() ?? "");
        expect(find.text("Enter a whole number"), findsNothing);
        expect(field.edits, isEmpty);
        expect(
          field.completions,
          replacement == null ? isEmpty : [replacement],
        );
        expect(field.clears, 0);
        expect(field.blurs, 1);
      },
    );
  }
}

/// A field's controller and focus, and the callbacks it reported.
