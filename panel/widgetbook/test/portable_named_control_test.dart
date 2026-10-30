import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

import "support/named_control_host.dart";

void main() {
  testWidgets("named payload edits write back through its binding", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(NamedControlHost()),
    );
    expect(
      find.text("MessageStyle at element:welcome_message style"),
      findsOneWidget,
    );
    expect(find.text("Welcome to the village"), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), "Good evening");
    await tester.pump();
    expect(find.text("Writes: 1"), findsOneWidget);
    expect(find.text("Good evening"), findsOneWidget);
  });

  for (final (scenario, message) in [
    (NamedControlScenario.missingBinding, "The control binding is unavailable"),
    (
      NamedControlScenario.unnamedValue,
      "The control binding is not a named value",
    ),
    (
      NamedControlScenario.unlocated,
      "The control binding has no authored location",
    ),
  ]) {
    testWidgets("${scenario.name} renders the unavailable state", (
      tester,
    ) async {
      await tester.pumpPanel(
        const [],
        at: PanelLocation.component(NamedControlHost(scenario: scenario)),
      );
      expect(find.text(message), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });
  }
}
