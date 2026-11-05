import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a higher index enters from the right, a lower from the left", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 0,
        child: SizedBox(
          key: ValueKey(0),
          width: 200,
          height: 80,
          child: Text("Page 0"),
        ),
      ),
    );
    double left(String page) => tester.getTopLeft(find.text(page)).dx;
    final rest = left("Page 0");

    await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 1,
        child: SizedBox(
          key: ValueKey(1),
          width: 200,
          height: 80,
          child: Text("Page 1"),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(left("Page 1"), greaterThan(rest));
    expect(left("Page 0"), lessThan(rest));

    await panel.settle();
    await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 0,
        child: SizedBox(
          key: ValueKey(0),
          width: 200,
          height: 80,
          child: Text("Page 0"),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(left("Page 0"), lessThan(rest));
    expect(left("Page 1"), greaterThan(rest));
  });

  testWidgets("animates its height to match the current page", (tester) async {
    final panel = await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 0,
        child: SizedBox(
          key: ValueKey(0),
          width: 200,
          height: 40,
          child: Text("Page 0"),
        ),
      ),
    );
    double height() =>
        tester.getSize(find.byType(DirectionalContentSwitcher)).height;
    expect(height(), 40);

    await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 1,
        child: SizedBox(
          key: ValueKey(1),
          width: 200,
          height: 120,
          child: Text("Page 1"),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(height(), allOf(greaterThan(40), lessThan(120)));

    await panel.settle();
    expect(height(), 120);
  });

  testWidgets("keeps both pages during the transition", (tester) async {
    final panel = await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 0,
        child: SizedBox(
          key: ValueKey(0),
          width: 200,
          height: 120,
          child: Text("Page 0"),
        ),
      ),
    );

    await tester.showComponent(
      const DirectionalContentSwitcher(
        index: 1,
        child: SizedBox(
          key: ValueKey(1),
          width: 200,
          height: 40,
          child: Text("Page 1"),
        ),
      ),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(panel.shows("Page 0"), isTrue);
    expect(panel.shows("Page 1"), isTrue);

    await panel.settle();
    expect(panel.shows("Page 0"), isFalse);
    expect(panel.shows("Page 1"), isTrue);
  });

  testWidgets("with reduced motion the destination replaces the page at once", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      const ReducedMotion(
        child: DirectionalContentSwitcher(
          index: 0,
          child: SizedBox(
            key: ValueKey(0),
            width: 200,
            height: 40,
            child: Text("Page 0"),
          ),
        ),
      ),
    );

    await tester.showComponent(
      const ReducedMotion(
        child: DirectionalContentSwitcher(
          index: 1,
          child: SizedBox(
            key: ValueKey(1),
            width: 200,
            height: 120,
            child: Text("Page 1"),
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(panel.shows("Page 0"), isFalse);
    expect(panel.shows("Page 1"), isTrue);
    expect(tester.getSize(find.byType(DirectionalContentSwitcher)).height, 120);
  });
}
