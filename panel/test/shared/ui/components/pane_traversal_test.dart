import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a freshly opened Realm surface reaches its Books with Tab "
      "alone", (tester) async {
    final atlas = book("Atlas");
    final zebra = book("Zebra");
    final panel = await tester.pumpPanel([
      signedIn(ada, organization: acme),
      realm(books: [atlas, zebra]),
    ]);
    await panel.openSurface(libraryId);

    await panel.tabTo("Zebra", limit: 30);
    await panel.press(LogicalKeyboardKey.enter);

    expect(panel.resources.selected, [zebra.bookId]);
  });

  testWidgets("Tab passes over a pane with nothing to focus", (tester) async {
    await tester.showPanes([
      Positioned(
        left: 0,
        top: 0,
        width: 80,
        height: 80,
        child: Pane(
          id: "first",
          trapFocus: false,
          child: ElevatedButton(onPressed: () {}, child: const Text("first")),
        ),
      ),
      const Positioned(
        left: 100,
        top: 0,
        width: 80,
        height: 80,
        child: Pane(id: "empty", trapFocus: false, child: Text("nothing")),
      ),
      Positioned(
        left: 200,
        top: 0,
        width: 80,
        height: 80,
        child: Pane(
          id: "last",
          trapFocus: false,
          child: ElevatedButton(onPressed: () {}, child: const Text("last")),
        ),
      ),
    ]);
    Focus.of(tester.element(find.text("first"))).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(Focus.of(tester.element(find.text("last"))).hasPrimaryFocus, isTrue);
  });
}
