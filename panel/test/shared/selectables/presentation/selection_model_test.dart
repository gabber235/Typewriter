import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final surface in SelectionSurfaceCase.all) {
    final [first, second, third] = surface.items;

    group("with the mouse on $surface", () {
      testWidgets("a plain click selects only that item, without checks", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await surface.item(panel, first).select();
        await surface.item(panel, second).select();

        expect(surface.selectedIn(panel), [second]);
        expect(surface.checkedIn(panel), isEmpty);
      });

      testWidgets("a toggle click adds and removes one item, and checks show "
          "on every item until nothing is selected", (tester) async {
        final panel = await surface.open(tester);

        await surface.item(panel, first).select();
        await surface.item(panel, third).toggle();
        expect(surface.selectedIn(panel), [first, third]);
        expect(surface.checkedIn(panel), surface.items);
        expect(surface.item(panel, third).isChecked, isTrue);
        expect(surface.item(panel, second).isChecked, isFalse);

        await surface.item(panel, first).toggle();
        expect(surface.selectedIn(panel), [third]);
        expect(surface.checkedIn(panel), surface.items);

        await surface.item(panel, third).toggle();
        expect(surface.selectedIn(panel), isEmpty);
        expect(surface.checkedIn(panel), isEmpty);
      });

      testWidgets(
        "a Shift click selects the range from the last clicked item",
        (tester) async {
          final panel = await surface.open(tester);

          await surface.item(panel, first).select();
          await surface.item(panel, third).selectRangeTo();

          expect(surface.selectedIn(panel), surface.items);
          expect(surface.checkedIn(panel), surface.items);
        },
      );

      testWidgets("a plain click in select mode selects one item and hides "
          "the checks", (tester) async {
        final panel = await surface.open(tester);

        await surface.item(panel, first).toggle();
        await surface.item(panel, second).toggle();
        await surface.item(panel, third).select();

        expect(surface.selectedIn(panel), [third]);
        expect(surface.checkedIn(panel), isEmpty);
      });

      testWidgets(
        "on macOS Command adds an item and Control opens the context menu",
        variant: TargetPlatformVariant.only(TargetPlatform.macOS),
        (tester) async {
          final panel = await surface.open(tester);

          await surface.item(panel, first).select();
          await surface.item(panel, second).toggle();
          expect(surface.selectedIn(panel), [first, second]);

          final menu = await surface
              .item(panel, third)
              .contextMenu(gesture: ContextGesture.controlClick);
          await panel.eventually(() => expect(menu.isOpen, isTrue));
          await menu.dismiss();
          expect(surface.selectedIn(panel), [third]);
        },
      );
    });

    group("with the keyboard on $surface", () {
      testWidgets("Space toggles the focused item and shows checks", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await panel.press(LogicalKeyboardKey.space);
        expect(surface.selectedIn(panel), [first]);
        expect(surface.checkedIn(panel), surface.items);

        await panel.press(surface.forward);
        await panel.press(LogicalKeyboardKey.space);
        expect(surface.selectedIn(panel), [first, second]);

        await panel.press(LogicalKeyboardKey.space);
        expect(surface.selectedIn(panel), [first]);
      });

      testWidgets("Enter selects only the focused item and hides the checks", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await panel.press(LogicalKeyboardKey.space);
        await panel.press(surface.forward);
        await panel.press(LogicalKeyboardKey.enter);

        expect(surface.selectedIn(panel), [second]);
        expect(surface.checkedIn(panel), isEmpty);
      });

      testWidgets("Shift with an arrow extends the range from the anchor", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await panel.press(LogicalKeyboardKey.enter);
        await panel.pressShifted(surface.forward);
        expect(panel.focused, contains(second));
        expect(surface.selectedIn(panel), [first, second]);
        expect(surface.checkedIn(panel), surface.items);

        await panel.pressShifted(surface.back);
        expect(surface.selectedIn(panel), [first]);
      });

      testWidgets("select all selects every item, and pressed again clears", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await panel.pressPrimary(LogicalKeyboardKey.keyA);
        expect(surface.selectedIn(panel), surface.items);
        expect(surface.checkedIn(panel), surface.items);

        await panel.pressPrimary(LogicalKeyboardKey.keyA);
        expect(surface.selectedIn(panel), isEmpty);
        expect(surface.checkedIn(panel), isEmpty);
      });

      testWidgets("Escape clears the whole selection and the checks", (
        tester,
      ) async {
        final panel = await surface.open(tester);

        await panel.press(LogicalKeyboardKey.space);
        await panel.pressShifted(surface.forward);
        expect(surface.selectedIn(panel), [first, second]);

        await panel.press(LogicalKeyboardKey.escape);

        expect(surface.selectedIn(panel), isEmpty);
        expect(surface.checkedIn(panel), isEmpty);
        expect(panel.focused, contains(second));
      });
    });
  }

  testWidgets("checks show only on surfaces holding a selected item", (
    tester,
  ) async {
    final panel = await tester.showComponent(const TwoSelectionSurfaces());
    await panel.card("Left 1").toggle();
    expect(panel.checkedOn("Left"), ["Left 1", "Left 2"]);
    expect(panel.checkedOn("Right"), isEmpty);

    await panel.card("Right 2").toggle();
    expect(panel.checkedOn("Left"), ["Left 1", "Left 2"]);
    expect(panel.checkedOn("Right"), ["Right 1", "Right 2"]);

    await panel.card("Left 1").toggle();
    expect(panel.checkedOn("Left"), isEmpty);
    expect(panel.checkedOn("Right"), ["Right 1", "Right 2"]);
  });
}
