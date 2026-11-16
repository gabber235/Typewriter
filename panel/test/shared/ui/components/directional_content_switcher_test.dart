import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  testWidgets("a higher index enters from the right, a lower from the left", (
    tester,
  ) async {
    final panel = await tester.showComponent(switcherPage(0));
    double left(String page) => tester.getTopLeft(find.text(page)).dx;
    final rest = left("Page 0");

    await tester.showComponent(switcherPage(1), settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(left("Page 1"), greaterThan(rest));

    await panel.settle();
    await tester.showComponent(switcherPage(0), settle: false);
    await tester.pump(const Duration(milliseconds: 16));
    expect(left("Page 0"), lessThan(rest));
  });

  testWidgets("animates its height to match the current page", (tester) async {
    final panel = await tester.showComponent(switcherPage(0, height: 40));
    double height() =>
        tester.getSize(find.byType(DirectionalContentSwitcher)).height;
    expect(height(), 40);

    await tester.showComponent(switcherPage(1, height: 120), settle: false);
    await tester.pump(const Duration(milliseconds: 150));
    // surfaceIn may carry the height a little past the page before it rests.
    expect(height(), allOf(greaterThan(40), isNot(120)));

    await panel.settle();
    expect(height(), 120);
  });

  testWidgets("the old page leaves at once while the new one enters", (
    tester,
  ) async {
    final panel = await tester.showComponent(switcherPage(0, height: 120));

    await tester.showComponent(switcherPage(1, height: 40), settle: false);
    await tester.pump(const Duration(milliseconds: 150));
    expect(panel.shows("Page 0"), isFalse);
    expect(panel.shows("Page 1"), isTrue);

    await panel.settle();
    expect(panel.shows("Page 0"), isFalse);
    expect(panel.shows("Page 1"), isTrue);
  });

  testWidgets("with reduced motion the destination replaces the page at once", (
    tester,
  ) async {
    final panel = await tester.showComponent(
      ReducedMotion(child: switcherPage(0, height: 40)),
    );

    await tester.showComponent(
      ReducedMotion(child: switcherPage(1, height: 120)),
      settle: false,
    );
    await tester.pump();

    expect(panel.shows("Page 0"), isFalse);
    expect(panel.shows("Page 1"), isTrue);
    expect(tester.getSize(find.byType(DirectionalContentSwitcher)).height, 120);
  });
}
