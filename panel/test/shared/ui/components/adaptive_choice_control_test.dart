import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets(
    "sliding choices support keyboard selection and skip disabled values",
    (tester) async {
      String? selected = "one";
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          StatefulBuilder(
            builder: (context, setState) => SlidingChoiceControl<String>(
              children: const {
                "one": Text("One"),
                "two": Text("Two"),
                "three": Text("Three"),
              },
              selected: selected,
              disabled: const {"two"},
              onSelected: (value) => setState(() => selected = value),
            ),
          ),
        ),
      );
      await tester.tap(find.text("Two"));
      await tester.pumpAndSettle();
      expect(selected, "one");
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(selected, "three");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "empty choices are disabled and recover without changing the value",
    (tester) async {
      var choices = <String, String>{"one": "One"};
      var changes = 0;
      late StateSetter rebuild;
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return AdaptiveChoiceControl<String>(
                choices: choices,
                selected: "one",
                onSelected: (_) => changes++,
              );
            },
          ),
        ),
      );
      rebuild(() => choices = {});
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text("No options available"), findsOneWidget);
      expect(find.text("One"), findsNothing);
      await tester.tap(find.text("No options available"));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(changes, 0);
      rebuild(() => choices = {"one": "One", "two": "Two"});
      await tester.pump();
      expect(find.text("No options available"), findsNothing);
      await tester.tap(find.text("Two"));
      await tester.pump();

      expect(changes, 1);
    },
  );

  testWidgets("three choices show every option to pick directly", (
    tester,
  ) async {
    final selections = <String?>[];
    await tester.showComponent(
      SizedBox(
        width: 360,
        child: AdaptiveChoiceControl<String>(
          choices: const {"one": "One", "two": "Two", "three": "Three"},
          selected: "one",

          onSelected: selections.add,
        ),
      ),
    );
    expect(find.text("Three"), findsOneWidget);

    await tester.tap(find.text("Two"));
    await tester.pump();

    expect(selections, ["two"]);
  });

  for (final choices in const [
    {"one": "One"},
    {"one": "One", "two": "Two", "three": "Three", "four": "Four"},
  ]) {
    testWidgets("${choices.length} choices are offered in a dropdown", (
      tester,
    ) async {
      await tester.showComponent(
        SizedBox(
          width: 360,
          child: AdaptiveChoiceControl<String>(
            choices: choices,
            selected: "one",

            onSelected: (_) {},
          ),
        ),
      );
      final last = choices.values.last;
      final shownBefore = find.text(last).evaluate().length;
      expect(shownBefore, choices.length > 1 ? 0 : 1);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.text(last).evaluate().length, greaterThan(shownBefore));
    });
  }

  testWidgets("a disabled control ignores taps on its segments", (
    tester,
  ) async {
    final selections = <String?>[];
    await tester.showComponent(
      SizedBox(
        width: 360,
        child: AdaptiveChoiceControl<String>(
          choices: const {"one": "One", "two": "Two"},
          selected: "one",
          enabled: false,
          onSelected: selections.add,
        ),
      ),
    );

    await tester.tap(find.text("Two"));
    await tester.pumpAndSettle();

    expect(selections, isEmpty);
  });
}
