import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const confirmation = "Delete 1 item(s)?";

  testWidgets("delete operation denies invocation when mutation is disabled", (
    tester,
  ) async {
    var deletions = 0;
    final identifier = DeletableSelectableIdentifier(() => deletions++);
    final operation = DeleteOperation(canMutate: () => false);
    final panel = await tester.pumpDeletion(operation, identifier);

    expect(operation.canExecuteOn([DeletableSelectable(identifier)]), isFalse);
    await panel.tapOn(find.text("Invoke deletion"));

    expect(panel.dialog.showing(confirmation), isFalse);
    expect(deletions, 0);
    expect(panel.container.read(selectionProvider), [identifier]);
  });

  testWidgets("delete operation rechecks access after confirmation", (
    tester,
  ) async {
    var allowed = true;
    var deletions = 0;
    final identifier = DeletableSelectableIdentifier(() => deletions++);
    final operation = DeleteOperation(canMutate: () => allowed);
    final panel = await tester.pumpDeletion(operation, identifier);

    await panel.tapOn(find.text("Invoke deletion"));
    expect(panel.dialog.showing(confirmation), isTrue);
    allowed = false;
    await panel.dialog.choose("Delete", message: confirmation);

    expect(deletions, 0);
    expect(panel.container.read(selectionProvider), [identifier]);
    expect(panel.dialog.showing(confirmation), isFalse);
  });

  testWidgets("ordinary delete operation deletes and clears its selection", (
    tester,
  ) async {
    var deletions = 0;
    final identifier = DeletableSelectableIdentifier(() => deletions++);
    const operation = DeleteOperation();
    final panel = await tester.pumpDeletion(operation, identifier);

    expect(operation.canExecuteOn([DeletableSelectable(identifier)]), isTrue);
    await panel.tapOn(find.text("Invoke deletion"));
    await panel.dialog.choose("Delete", message: confirmation);

    expect(deletions, 1);
    expect(panel.container.read(selectionProvider), isEmpty);
  });

  final variants = {
    "filled": OperationButton.filledIcon,
    "outlined": OperationButton.outlinedIcon,
  };
  for (final MapEntry(key: variant, value: button) in variants.entries) {
    for (final available in [true, false]) {
      testWidgets(
        "$variant button ${available ? "shows" : "omits"} the operation "
        "shortcut when it is ${available ? "" : "un"}available",
        (tester) async {
          final panel = await tester.pumpPanel(
            const [],
            at: PanelLocation.component(
              button(
                operation: ShortcutTestOperation(
                  activators: [
                    if (available)
                      const SingleActivator(LogicalKeyboardKey.keyR),
                  ],
                ),
                icon: const Icon(Icons.bolt),
                label: const Text("Run"),
                onPressed: () {},
              ),
            ),
          );

          expect(panel.shows("Run"), isTrue);
          expect(panel.shows("R"), available);
        },
      );
    }
  }

  testWidgets("narrow button keeps its shortcut without overflowing", (
    tester,
  ) async {
    const label = "Run this operation with a long label";
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 150,
          child: OperationButton.filledIcon(
            operation: const ShortcutTestOperation(
              activators: [SingleActivator(LogicalKeyboardKey.keyR)],
            ),
            icon: const Icon(Icons.bolt),
            label: const Text(label),
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(panel.shows("R"), isTrue);
    expect(find.bySemanticsLabel(RegExp("^$label")), findsOneWidget);
  });
}
