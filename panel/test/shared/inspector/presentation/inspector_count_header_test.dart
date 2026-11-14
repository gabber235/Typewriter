import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const member = SelectableNoun(one: "member", many: "members");
  const service = SelectableNoun(one: "service", many: "services");

  testWidgets("several items of one kind are counted by their noun", (
    tester,
  ) async {
    final panel = await tester.pumpDesktopInspector();

    panel.container.read(selectionProvider.notifier).selectAll([
      TestSelectableIdentifier(id: "ada", noun: member),
      TestSelectableIdentifier(id: "grace", noun: member),
    ]);
    await panel.settle();

    expect(panel.inspector.texts.first, "2 members");
  });

  testWidgets("items of different kinds are counted as items", (tester) async {
    final panel = await tester.pumpDesktopInspector();

    panel.container.read(selectionProvider.notifier).selectAll([
      TestSelectableIdentifier(id: "ada", noun: member),
      TestSelectableIdentifier(id: "lobby", noun: service),
      TestSelectableIdentifier(id: "grace", noun: member),
    ]);
    await panel.settle();

    expect(panel.inspector.texts.first, "3 items");
  });

  testWidgets("one item shows no count", (tester) async {
    final panel = await tester.pumpDesktopInspector();

    panel.container.read(selectionProvider.notifier).selectAll([
      TestSelectableIdentifier(id: "ada", noun: member),
    ]);
    await panel.settle();

    expect(panel.inspector.texts, isNot(contains("1 member")));
    expect(panel.inspector.texts.first, "Ada");
  });
}
