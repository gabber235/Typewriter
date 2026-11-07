import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("an early release keeps the row", (tester) async {
    final hold = await tester.holdTime();
    final (panel, gesture) = await tester.holdDown();
    await tester.pump(hold ~/ 2);
    await gesture.up();
    await tester.pump(hold * 2);
    expect(panel.says("Removed"), isFalse);
  });

  testWidgets("a full hold completes once", (tester) async {
    final hold = await tester.holdTime();
    final (panel, gesture) = await tester.holdDown();
    await tester.pump(hold - const Duration(milliseconds: 1));
    expect(panel.says("Removed"), isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(panel.says("Removed 1"), isTrue);
    await tester.pump(hold);
    expect(panel.says("Removed 1"), isTrue);
    await gesture.up();
  });

  testWidgets("a re-press continues from the fill", (tester) async {
    final hold = await tester.holdTime();
    final (panel, gesture) = await tester.holdDown();
    await tester.pump(hold ~/ 2);
    await gesture.up();
    await tester.pump(hold ~/ 8);
    await gesture.down(panel.boundsOf("Remove").center);
    // Half held, an eighth run back: five eighths remain, not the whole hold.
    await tester.pump(hold * 5 ~/ 8 - const Duration(milliseconds: 1));
    expect(panel.says("Removed"), isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(panel.says("Removed 1"), isTrue);
    await gesture.up();
  });

  testWidgets("reduced motion keeps the hold's time", (tester) async {
    final hold = await tester.holdTime();
    final (panel, gesture) = await tester.holdDown(reduced: true);
    await tester.pump(hold - const Duration(milliseconds: 1));
    expect(panel.says("Removed"), isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(panel.says("Removed 1"), isTrue);
    await gesture.up();
  });
}
