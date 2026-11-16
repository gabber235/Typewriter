import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

const _small = Size(40, 24);
const _large = Size(140, 48);

/// A _small box saying "First" and a _large one saying "Second".
final _first = SizedBox.fromSize(
  key: const ValueKey("first"),
  size: _small,
  child: const Text("First"),
);
final _second = SizedBox.fromSize(
  key: const ValueKey("second"),
  size: _large,
  child: const Text("Second"),
);

void main() {
  testWidgets("switches children with a transition", (tester) async {
    final second = ValueNotifier(false);
    addTearDown(second.dispose);
    await tester.showComponent(
      ValueListenableBuilder(
        valueListenable: second,
        builder: (context, value, _) =>
            ElasticSwitcher(child: value ? _second : _first),
      ),
    );
    expect(find.text("First"), findsOneWidget);
    expect(find.text("Second"), findsNothing);

    second.value = true;
    await tester.pump();
    expect(find.text("First"), findsOneWidget);
    expect(find.text("Second"), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text("First"), findsNothing);
    expect(find.text("Second"), findsOneWidget);
  });

  testWidgets("grows from the old child's size to the new one", (tester) async {
    final second = ValueNotifier(false);
    addTearDown(second.dispose);
    await tester.showComponent(
      ValueListenableBuilder(
        valueListenable: second,
        builder: (context, value, _) =>
            ElasticSwitcher(child: value ? _second : _first),
      ),
    );
    expect(tester.getSize(find.byType(ElasticSwitcher)), _small);

    second.value = true;
    await tester.pump();
    await tester.pump(tester.settleTimeOf(MotionToken.loadIn) ~/ 4);
    final mid = tester.getSize(find.byType(ElasticSwitcher));
    expect(mid.width, allOf(greaterThan(_small.width), lessThan(_large.width)));
    expect(
      mid.height,
      allOf(greaterThan(_small.height), lessThan(_large.height)),
    );

    await tester.pump(const Duration(milliseconds: 1000));
    expect(
      tester.getSize(find.byType(ElasticSwitcher)).width,
      closeTo(_large.width, 0.01),
    );
    expect(
      tester.getSize(find.byType(ElasticSwitcher)).height,
      closeTo(_large.height, 0.01),
    );
  });
}
