import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "completion receives the exact draft once when Escape ends editing",
    (tester) async {
      final completions = <TextEditingValue>[];
      await tester.pumpTestApp(
        child: Scaffold(
          body: EditorTextField(text: "1", onCommittedDone: completions.add),
        ),
      );
      await tester.enterText(find.byType(TextFormField), "01.500");
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(completions.map((value) => value.text), ["01.500"]);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(completions.length, 1);
    },
  );

  testWidgets("completion observes committed composition when blur ends editing", (
    tester,
  ) async {
    final completions = <TextEditingValue>[];
    final controller = TextEditingController(text: "a");
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: EditorTextField(
          controller: controller,
          focusNode: focus,
          onCommittedDone: completions.add,
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    controller.value = const TextEditingValue(
      text: "draft",
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 0, end: 5),
    );
    expect(completions,isEmpty);
    focus.unfocus();
    await tester.pump();
    expect(completions.single.composing,TextRange.empty);
    controller.value = controller.value.copyWith(composing: TextRange.empty);
    await tester.pump();
    expect(completions.map((value) => value.text), ["draft"]);
    controller.selection = const TextSelection.collapsed(offset: 0);
    expect(completions.length, 1);
  });

  testWidgets(
    "display text is replaced by the exact editable representation on focus",
    (tester) async {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpTestApp(
        child: Scaffold(
          body: EditorTextField(
            text: "1.2345",
            displayText: "1.23 kg",
            controller: controller,
            focusNode: focus,
          ),
        ),
      );
      expect(controller.text, "1.23 kg");
      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(controller.text, "1.2345");
      focus.unfocus();
      await tester.pumpAndSettle();
      expect(controller.text, "1.23 kg");
    },
  );

  testWidgets("disposing a focused input never completes an edit", (
    tester,
  ) async {
    final completions = <TextEditingValue>[];
    await tester.pumpTestApp(
      child: Scaffold(
        body: EditorTextField(text: "a", onCommittedDone: completions.add),
      ),
    );
    await tester.enterText(find.byType(TextFormField), "b");
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(completions, isEmpty);
  });

  testWidgets("numeric own echoes preserve precise raw editing text", (
    tester,
  ) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    var value = 1.0;
    await tester.pumpTestApp(
      child: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ValidatedTextField<double>(
            value: value,
            controller: controller,
            focusNode: focus,
            serialize: double.parse,
            deserialize: (value) => value.toString(),
            display: (value) => "${value.toStringAsFixed(1)} units",
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), "01.2300");
    await tester.pumpAndSettle();
    expect(value, 1.23);
    expect(controller.text, "01.2300");
    focus.unfocus();
    await tester.pumpAndSettle();
    expect(controller.text, "1.2 units");
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(controller.text, "1.23");
  });
  testWidgets("intermediate accepted echoes never replace a newer raw draft",(tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    late StateSetter update;
    var value = 0;
    await tester.pumpTestApp(child:Scaffold(body:StatefulBuilder(builder:(context,setState) {
      update=setState;
      return ValidatedTextField<int>(value:value,controller:controller,serialize:int.parse,onChanged:(_) {});
    })));
    await tester.enterText(find.byType(TextFormField),"1");
    await tester.enterText(find.byType(TextFormField),"12");
    await tester.enterText(find.byType(TextFormField),"123");
    update(()=>value=1);
    await tester.pump();
    expect(controller.text,"123");
    update(()=>value=12);
    await tester.pump();
    expect(controller.text,"123");
    update(()=>value=123);
    await tester.pump();
    expect(controller.text,"123");
    update(()=>value=9);
    await tester.pump();
    expect(controller.text,"9");
  });

}
