import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const size = Size(1000, 700);
  final traits = [window(size)];
  final reduced = [window(size), reducedMotion];

  testWidgets("a sheet rests on the bottom edge, no wider than a reading "
      "column, and Escape closes it", (tester) async {
    final panel = await tester.pumpPanel(
      traits,
      at: const PanelLocation.component(SheetOpener()),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    final sheet = tester.getRect(find.byKey(SheetOpener.sheetKey));
    expect(sheet.bottom, size.height);
    expect(sheet.width, PanelSheetRoute.maxWidth);
    expect(sheet.center.dx, size.width / 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await panel.settle();
    expect(find.text("Sheet line"), findsNothing);
  });

  testWidgets("a sheet's words read in the panel's text colour", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      traits,
      at: const PanelLocation.component(SheetOpener()),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    final line = tester.element(find.text("Sheet line"));
    expect(
      DefaultTextStyle.of(line).style.color?.toARGB32(),
      line.colors.contentPrimary.toARGB32(),
    );
    expect(
      DefaultTextStyle.of(line).style.decoration,
      isNot(TextDecoration.underline),
    );
  });

  testWidgets("the sheet rises from below the edge as it opens", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      traits,
      at: const PanelLocation.component(SheetOpener()),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(tester.settleTimeOf(MotionToken.surfaceIn) ~/ 20);
    final rising = tester.getRect(find.byKey(SheetOpener.sheetKey));
    await panel.settle();

    expect(rising.bottom, greaterThan(size.height));
    expect(
      tester.getRect(find.byKey(SheetOpener.sheetKey)).bottom,
      size.height,
    );
  });

  testWidgets("with reduced motion a sheet is there at once", (tester) async {
    await tester.pumpPanel(
      reduced,
      at: const PanelLocation.component(SheetOpener()),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(
      tester.getRect(find.byKey(SheetOpener.sheetKey)).bottom,
      size.height,
    );
  });

  testWidgets("dragging a sheet down past half its height closes it", (
    tester,
  ) async {
    final panel = await tester.pumpPanel(
      traits,
      at: const PanelLocation.component(SheetOpener()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    final sheet = tester.getRect(find.byKey(SheetOpener.sheetKey));
    await tester.dragFrom(
      sheet.topCenter + const Offset(0, 8),
      Offset(0, sheet.height * 0.6),
    );
    await panel.settle();

    expect(find.text("Sheet line"), findsNothing);
  });

  testWidgets("a short drag down lets the sheet settle back", (tester) async {
    final panel = await tester.pumpPanel(
      traits,
      at: const PanelLocation.component(SheetOpener()),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await panel.settle();

    final sheet = tester.getRect(find.byKey(SheetOpener.sheetKey));
    await tester.timedDragFrom(
      sheet.topCenter + const Offset(0, 8),
      Offset(0, sheet.height * 0.2),
      const Duration(seconds: 1),
    );
    await panel.settle();

    expect(tester.getRect(find.byKey(SheetOpener.sheetKey)), sheet);
  });
}
