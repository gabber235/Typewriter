import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
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

  for (final theme in [null, dark]) {
    testWidgets("the page behind a dialog stays visible through a light veil"
        "${theme == null ? "" : " in the dark theme"}", (tester) async {
      await tester.pumpPanel([
        ?theme,
      ], at: const PanelLocation.component(DialogBackdropPage()));

      await tester.tap(find.text("Open"));
      await tester.pumpAndSettle();

      final veils = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .map((barrier) => barrier.color)
          .nonNulls;
      expect(veils, isNotEmpty);
      for (final veil in veils) {
        expect(veil.a, lessThanOrEqualTo(0.3));
      }
    });
  }
}
