import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("the ring travels from one target to the next across panes", (
    tester,
  ) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingPanes()),
    );
    await panel.focusOn("left 1");
    await panel.settle();
    final left = panel.boundsOf("left 1");
    final right = panel.boundsOf("right 1");
    expect(ringedRect(tester), rectMoreOrLessEquals(left));

    await panel.focusOn("right 1");
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final between = ringedRect(tester)!;
    expect(between.left, allOf(greaterThan(left.left), lessThan(right.left)));

    await panel.settle();
    expect(ringedRect(tester), rectMoreOrLessEquals(right));
  });

  testWidgets("a held key makes the ring jump", (tester) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingPanes()),
    );
    await panel.focusOn("left 1");
    await panel.settle();
    for (final row in ["left 2", "left 3", "left 4"]) {
      await panel.focusOn(row);
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(ringedRect(tester), rectMoreOrLessEquals(panel.boundsOf("left 4")));
  });

  testWidgets("a table row target rings the whole row", (tester) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingTable()),
    );
    await panel.focusOn("Ada name");
    await panel.settle();
    final row = panel
        .boundsOf("Ada name")
        .expandToInclude(panel.boundsOf("Ada role"))
        .expandToInclude(panel.boundsOf("Ada email"));
    expect(ringedRect(tester), rectMoreOrLessEquals(row));
  });

  testWidgets("reduced motion: the ring jumps", (tester) async {
    final panel = await tester.mountComponent(
      const ReducedMotion(child: RingStage(child: RingPanes())),
    );
    await panel.focusOn("left 1");
    await panel.settle();
    await panel.focusOn("right 1");
    await tester.pump();
    expect(ringedRect(tester), rectMoreOrLessEquals(panel.boundsOf("right 1")));
  });

  testWidgets("the ring stays on its target while the list scrolls", (
    tester,
  ) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingScrollList()),
    );
    await panel.focusOn("item 5");
    await panel.settle();
    final before = panel.boundsOf("item 5");
    panel.scrollPosition.jumpTo(100);
    await tester.pump();
    await tester.pump();
    final after = panel.boundsOf("item 5");
    expect(after.top, before.top - 100);
    expect(ringedRect(tester), rectMoreOrLessEquals(after));
  });

  testWidgets("a null target hides the ring", (tester) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingPanes()),
    );
    await panel.focusOn("left 1");
    await panel.settle();
    expect(ringedRect(tester), isNotNull);
    await tester.showComponent(
      const RingStage(follows: false, child: RingPanes()),
    );
    expect(ringedRect(tester), isNull);
  });

  testWidgets("a node with no target is ringed by its own rect", (
    tester,
  ) async {
    final panel = await tester.mountComponent(
      const RingStage(child: RingPanes()),
    );
    await panel.focusOn("bare");
    await panel.settle();
    expect(ringedRect(tester), rectMoreOrLessEquals(panel.boundsOf("bare")));
  });
}
