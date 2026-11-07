import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("primary action confirms from anywhere inside the dialog", (
    tester,
  ) async {
    var confirmations = 0;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        confirmationDialogLauncher(
          body: const TextField(
            autofocus: true,
            decoration: InputDecoration(labelText: "Reason"),
          ),
          onConfirm: () async => confirmations++,
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel("Reason"));
    await tester.pump();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel("Reason"))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    await tester.pressPrimaryActionShortcut();

    await tester.pumpAndSettle();

    expect(confirmations, 1);
    expect(find.text("Are you sure?"), findsNothing);
  });

  testWidgets("primary action respects the confirmation delay", (tester) async {
    var confirmations = 0;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        confirmationDialogLauncher(
          delayConfirm: const Duration(seconds: 2),
          onConfirm: () async => confirmations++,
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.pressPrimaryActionShortcut();
    await tester.pump();
    expect(confirmations, 0);

    await tester.pump(const Duration(seconds: 2));
    await tester.pressPrimaryActionShortcut();
    await tester.pumpAndSettle();

    expect(confirmations, 1);
  });

  testWidgets("primary action cannot confirm twice while pending", (
    tester,
  ) async {
    final pending = Completer<void>();
    var confirmations = 0;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        confirmationDialogLauncher(
          onConfirm: () {
            confirmations++;
            return pending.future;
          },
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.pressPrimaryActionShortcut();
    await tester.pump();
    await tester.pressPrimaryActionShortcut();
    await tester.pump();

    expect(confirmations, 1);
    pending.complete();
    await tester.pumpAndSettle();
  });

  testWidgets("Escape dismisses through the cancellation callback", (
    tester,
  ) async {
    var cancellations = 0;
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        confirmationDialogLauncher(
          onConfirm: () async {},
          onCancel: () => cancellations++,
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(cancellations, 1);
    expect(find.text("Are you sure?"), findsNothing);
  });

  testWidgets("Escape in a Normal mode dialog clears the selection first", (
    tester,
  ) async {
    final selected = TestSelectableIdentifier(id: "selected");
    final panel = await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showAdvancedDialog<void>(
              context: context,
              builder: (_) => Dialog(
                child: TextButton(
                  autofocus: true,
                  onPressed: () {},
                  child: const Text("Inside"),
                ),
              ),
            ),
            child: const Text("Open"),
          ),
        ),
      ),
    );
    panel.container.read(selectionProvider.notifier).selectAll([selected]);

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(panel.container.read(selectionProvider), isEmpty);
    expect(find.text("Inside"), findsOneWidget);
  });

  testWidgets("the page behind a dialog sinks back and returns", (
    tester,
  ) async {
    await tester.pumpPanel(
      const [],
      at: const PanelLocation.component(DialogBackdropPage()),
    );
    final measured = tester.getRect(find.text("Page heading"));

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
    final sunk = tester.getRect(find.text("Page heading"));
    expect(sunk.width, lessThan(measured.width));
    expect(
      sunk.center.dx,
      closeTo(tester.getCenter(find.byType(DialogBackdrop)).dx, 1),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text("Dialog title"), findsNothing);
    expect(tester.getRect(find.text("Page heading")), measured);
  });

  testWidgets("reduced motion: a dialog appears at once", (tester) async {
    await tester.pumpPanel(const [
      reducedMotion,
    ], at: const PanelLocation.component(DialogBackdropPage()));

    await tester.tap(find.text("Open"));
    await tester.pump();
    await tester.pump();
    final first = tester.getRect(find.text("Dialog title"));
    await tester.pumpAndSettle();

    expect(first, tester.getRect(find.text("Dialog title")));
  });
}
