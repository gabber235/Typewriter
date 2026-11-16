import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const alpha = AnimatedItem(id: "a", label: "Alpha");
  const beta = AnimatedItem(id: "b", label: "Beta");
  const gamma = AnimatedItem(id: "g", label: "Gamma");

  for (final layout in AnimatedItemsLayout.values) {
    group(layout.name, () {
      testWidgets("removing the focused row focuses the next row", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([
          alpha,
          beta,
          gamma,
        ], layout: layout);
        await tester.focusAnimatedItem("b");
        source.update([alpha, gamma]);
        await tester.pump();
        expect(AnimatedItems.focusedLabel(tester), "Gamma");
      });

      testWidgets("removing the focused last row focuses the previous row", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([
          alpha,
          beta,
        ], layout: layout);
        await tester.focusAnimatedItem("b");
        source.update([alpha]);
        await tester.pump();
        expect(AnimatedItems.focusedLabel(tester), "Alpha");
      });

      testWidgets("removing the only row focuses the pane", (tester) async {
        final source = await tester.showAnimatedItems(
          [alpha],
          layout: layout,
          inPane: true,
        );
        await tester.focusAnimatedItem("a");
        source.update([]);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus?.debugLabel, "Pane-items");
      });

      testWidgets("a row someone else adds leaves focus where it was", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([
          alpha,
          gamma,
        ], layout: layout);
        await tester.focusAnimatedItem("g");
        source.update([alpha, beta, gamma]);
        await tester.pumpAndSettle();
        expect(AnimatedItems.focusedLabel(tester), "Gamma");
      });

      testWidgets("an announced row takes focus when it arrives", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([alpha], layout: layout);
        await tester.focusAnimatedItem("a");
        source.rows.focus.expect("b");
        source.update([alpha, beta]);
        await tester.pumpAndSettle();
        expect(AnimatedItems.focusedLabel(tester), "Beta");
      });

      testWidgets("a reordered row keeps focus", (tester) async {
        final source = await tester.showAnimatedItems([
          alpha,
          beta,
          gamma,
        ], layout: layout);
        await tester.focusAnimatedItem("a");
        source.update([beta, gamma, alpha]);
        await tester.pumpAndSettle();
        expect(AnimatedItems.focusedLabel(tester), "Alpha");
      });

      testWidgets(
        "a sending row keeps focus, and keeps it when the command is refused",
        (tester) async {
          final source = await tester.showAnimatedItems([
            alpha,
            beta,
          ], layout: layout);
          await tester.focusAnimatedItem("a");
          final refused = Completer<void>();
          final sending = source.rows.sending(["a"], () => refused.future);
          await tester.pump();
          expect(AnimatedItems.focusedLabel(tester), "Alpha");
          refused.completeError(StateError("refused"));
          await expectLater(sending, throwsStateError);
          await tester.pumpAndSettle();
          expect(AnimatedItems.focusedLabel(tester), "Alpha");
        },
      );

      testWidgets("Tab never stops on a leaving row", (tester) async {
        final source = await tester.showAnimatedItems([
          alpha,
          beta,
          gamma,
        ], layout: layout);
        await tester.focusAnimatedItem("a");
        source.update([alpha, gamma]);
        // Beta is still leaving.
        await tester.pump(const Duration(milliseconds: 16));
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        expect(AnimatedItems.focusedLabel(tester), isNot("Beta"));
      });

      testWidgets(
        "a row removed while a dialog is open hands focus to the next row "
        "when it closes",
        (tester) async {
          final source = await tester.showAnimatedItems([
            alpha,
            beta,
            gamma,
          ], layout: layout);
          await tester.focusAnimatedItem("b");
          await tester.openTestDialog();
          source.update([alpha, gamma]);
          await tester.pumpAndSettle();
          await tester.closeTestDialog();
          expect(AnimatedItems.focusedLabel(tester), "Gamma");
        },
      );

      testWidgets(
        "a field focused inside a row someone else removes hands focus to "
        "the next row at once",
        (tester) async {
          final source = await tester.showAnimatedItems([
            alpha,
            beta,
            gamma,
          ], layout: layout);
          await tester.focusAnimatedItemField("b");
          source.update([alpha, gamma]);
          await tester.pump();
          expect(AnimatedItems.focusedLabel(tester), "Gamma");
        },
      );
    });
  }
}
