import "package:flutter/cupertino.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "empty choices are disabled and recover without changing the value",
    (tester) async {
      var choices = <String, String>{"one": "One"};
      var changes = 0;
      late StateSetter rebuild;
      await tester.pumpTestApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return AdaptiveChoiceControl<String>(
              choices: choices,
              selected: "one",
              onSelected: (_) => changes++,
            );
          },
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

  testWidgets("uses segmented controls for three choices", (tester) async {
    String? selected;

    await tester.pumpTestApp(
      child: AdaptiveChoiceControl<String>(
        choices: const {"one": "One", "two": "Two", "three": "Three"},
        selected: "one",
        onSelected: (value) => selected = value,
      ),
    );

    expect(
      find.byType(CupertinoSlidingSegmentedControl<String>),
      findsOneWidget,
    );
    expect(find.byType(Dropdown<String>), findsNothing);

    await tester.tap(find.text("Two"));
    await tester.pump();

    expect(selected, "two");
  });

  testWidgets("uses searchable dropdowns for four choices", (tester) async {
    await tester.pumpTestApp(
      child: AdaptiveChoiceControl<String>(
        choices: const {
          "one": "One",
          "two": "Two",
          "three": "Three",
          "four": "Four",
        },
        selected: "one",
        onSelected: (_) {},
      ),
    );

    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsNothing);
    expect(find.byType(Dropdown<String>), findsOneWidget);
  });

  testWidgets("uses a dropdown for a single choice", (tester) async {
    await tester.pumpTestApp(
      child: AdaptiveChoiceControl<String>(
        choices: const {"one": "One"},
        selected: "one",
        onSelected: (_) {},
      ),
    );

    expect(find.byType(CupertinoSlidingSegmentedControl<String>), findsNothing);
    expect(find.byType(Dropdown<String>), findsOneWidget);
  });

  testWidgets("disables every segment when interaction is disabled", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: AdaptiveChoiceControl<String>(
        choices: const {"one": "One", "two": "Two"},
        selected: "one",
        enabled: false,
        onSelected: (_) {},
      ),
    );

    final control = tester.widget<CupertinoSlidingSegmentedControl<String>>(
      find.byType(CupertinoSlidingSegmentedControl<String>),
    );

    expect(control.disabledChildren, {"one", "two"});
  });
}
