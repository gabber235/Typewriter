import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  for (final (name, selected, preferred, choices, enabled, expected) in [
    ("sole option", null, null, {"one": "One"}, true, "one"),
    (
      "explicit default",
      null,
      "two",
      {"one": "One", "two": "Two"},
      true,
      "two",
    ),
    (
      "unavailable default falls back",
      null,
      "missing",
      {"one": "One"},
      true,
      "one",
    ),
    ("ambiguous choices", null, null, {"one": "One", "two": "Two"}, true, null),
    (
      "stored selection",
      "one",
      "two",
      {"one": "One", "two": "Two"},
      true,
      null,
    ),
    (
      "unavailable stored selection",
      "removed",
      null,
      {"one": "One"},
      true,
      null,
    ),
    ("disabled", null, "one", {"one": "One"}, false, null),
  ]) {
    testWidgets(name, (tester) async {
      final changes = <String?>[];
      await tester.pumpTestApp(
        child: AdaptiveChoiceControl<String>(
          choices: choices,
          selected: selected,
          defaultValue: preferred,
          enabled: enabled,
          onSelected: changes.add,
        ),
      );
      expect(changes, expected == null ? isEmpty : [expected]);
      await tester.pump();
      expect(changes, expected == null ? isEmpty : [expected]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    "late options initialize once and later defaults cannot overwrite a choice",
    (tester) async {
      final choices = ValueNotifier(<String, String>{});
      addTearDown(choices.dispose);
      final changes = <String?>[];
      await tester.pumpTestApp(
        child: ValueListenableBuilder(
          valueListenable: choices,
          builder: (context, choices, _) => AdaptiveChoiceControl<String>(
            choices: choices,
            selected: changes.lastOrNull,
            onSelected: changes.add,
          ),
        ),
      );
      expect(changes, isEmpty);
      choices.value = {"one": "One"};

      await tester.pumpAndSettle();
      expect(changes, ["one"]);
      choices.value = {"two": "Two"};
      await tester.pumpAndSettle();
      expect(changes, ["one"]);
    },
  );
}
