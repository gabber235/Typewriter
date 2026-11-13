import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final (value, heard) in [
    (false, "not checked"),
    (true, "checked"),
    (null, "partly checked"),
  ]) {
    testWidgets("a check that is $heard is heard that way", (tester) async {
      await tester.showComponent(
        SelectionCheck(
          value: value,
          semanticLabel: "Select all",
          autofocus: true,
          onChanged: () {},
        ),
      );

      final data = tester
          .getSemantics(find.bySemanticsLabel("Select all"))
          .getSemanticsData();
      expect(
        data.flagsCollection.isChecked,
        value == true
            ? CheckedState.isTrue
            : value == null
            ? CheckedState.mixed
            : CheckedState.isFalse,
      );
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
    });
  }

  for (final (key, name) in [
    (LogicalKeyboardKey.space, "Space"),
    (LogicalKeyboardKey.enter, "Enter"),
  ]) {
    testWidgets("$name flips the focused check", (tester) async {
      final value = ValueNotifier<bool?>(false);
      addTearDown(value.dispose);
      final panel = await tester.showComponent(
        ValueListenableBuilder(
          valueListenable: value,
          builder: (context, current, _) => SelectionCheck(
            value: current,
            semanticLabel: "Select all",
            autofocus: true,
            onChanged: () => value.value = !(current ?? true),
          ),
        ),
      );

      await tester.sendKeyEvent(key);
      await panel.settle();
      expect(value.value, isTrue);

      await tester.sendKeyEvent(key);
      await panel.settle();
      expect(value.value, isFalse);
    });
  }

  testWidgets("a check without a change is heard as unavailable and keys do "
      "nothing", (tester) async {
    final panel = await tester.showComponent(
      SelectionCheck(
        value: false,
        semanticLabel: "Select all",
        autofocus: true,
      ),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await panel.settle();

    final data = tester
        .getSemantics(find.bySemanticsLabel("Select all"))
        .getSemanticsData();
    expect(data.flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets("a check fills with the accent when checked", (tester) async {
    final panel = await tester.showComponent(
      SelectionCheck(
        value: false,
        semanticLabel: "Select all",
        autofocus: true,
        onChanged: () {},
      ),
    );
    final empty = tester.selectionCheckFill;

    await tester.showComponent(
      SelectionCheck(
        value: true,
        semanticLabel: "Select all",
        autofocus: true,
        onChanged: () {},
      ),
    );
    await panel.settle();

    final accent = tester.element(find.byType(SelectionCheck)).colors.accent;
    expect(empty.toARGB32(), isNot(accent.toARGB32()));
    expect(tester.selectionCheckFill.toARGB32(), accent.toARGB32());
  });
}
