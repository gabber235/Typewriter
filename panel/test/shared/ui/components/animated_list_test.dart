import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

const insertion = Duration(milliseconds: 200);
const removal = Duration(milliseconds: 400);

void main() {
  group("useSliverAnimatedList", () {
    testWidgets("renders initial items with completed animations", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);

      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "a"), 1);
      expect(AnimatedItems.opacityOf(tester, "b"), 1);
    });

    testWidgets("inserts in the middle using the configured duration", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "c", label: "Gamma"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump();

      expect(find.text("Beta"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "b"), 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(AnimatedItems.opacityOf(tester, "b"), closeTo(0.5, 0.01));

      await tester.pump(const Duration(milliseconds: 100));
      expect(AnimatedItems.opacityOf(tester, "b"), 1);
      expect(source.renderedIds, ["a", "b", "c"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("keeps captured removed item for the removal duration", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Old Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([const AnimatedItem(id: "b", label: "Beta")]);
      await tester.pump();

      expect(find.text("Old Alpha"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "removed-a"), 1);

      await tester.pump(const Duration(milliseconds: 399));
      expect(find.text("Old Alpha"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "removed-a"), greaterThan(0));

      await tester.pump(const Duration(milliseconds: 2));
      await tester.pump();
      expect(find.text("Old Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
    });

    testWidgets("handles mixed changes and reorder without index errors", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
        const AnimatedItem(id: "d", label: "Delta"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([
        const AnimatedItem(id: "d", label: "Delta"),
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "e", label: "Epsilon"),
      ]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(source.renderedIds, ["d", "b", "e"]);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Gamma"), findsNothing);

      expect(tester.takeException(), isNull);
    });

    testWidgets("stays synchronized across rapid updates", (tester) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump(const Duration(milliseconds: 50));
      source.update([
        const AnimatedItem(id: "d", label: "Delta"),
        const AnimatedItem(id: "c", label: "Gamma"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);
      await tester.pump(const Duration(milliseconds: 50));
      source.update([
        const AnimatedItem(id: "d", label: "Delta"),
        const AnimatedItem(id: "e", label: "Epsilon"),
      ]);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();

      expect(source.renderedIds, ["d", "e"]);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("updates payload without a structural animation", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Old"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([const AnimatedItem(id: "a", label: "New")]);
      await tester.pump();

      expect(find.text("Old"), findsNothing);
      expect(find.text("New"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "a"), 1);
      expect(source.removedIds, isEmpty);
    });

    testWidgets("snapshots a mutable source list", (tester) async {
      final mutableItems = <AnimatedItem>[
        const AnimatedItem(id: "a", label: "Alpha"),
      ];
      final source = AnimatedItemSource(mutableItems);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      final previousSnapshot = source.renderedItems;
      mutableItems.add(const AnimatedItem(id: "b", label: "Beta"));

      expect(previousSnapshot.map((item) => item.id), ["a"]);
      expect(
        () => previousSnapshot.add(const AnimatedItem(id: "c", label: "Gamma")),
        throwsUnsupportedError,
      );

      source.rebuild();
      await tester.pump();

      expect(source.renderedIds, ["a", "b"]);
      expect(find.text("Beta"), findsOneWidget);
    });

    testWidgets("rejects duplicate identities on initial build", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "a", label: "Duplicate"),
      ]);

      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      expect(tester.takeException(), isArgumentError);
    });

    testWidgets("rejects duplicate identities before changing state", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.update([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "a", label: "Duplicate"),
      ]);
      await tester.pump();

      expect(tester.takeException(), isArgumentError);
      expect(source.renderedIds, ["a"]);

      source.update([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);
      await tester.pump();

      expect(source.renderedIds, ["a", "b"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("synchronizes while unmounted and remounts latest items", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
      ]);
      await tester.showComponent(
        AnimatedItems(
          source: source,
          insertDuration: insertion,
          removeDuration: removal,
        ),
      );

      source.visible.value = false;
      await tester.pump();
      source.update([
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
      ]);
      await tester.pump();

      source.visible.value = true;
      await tester.pump();

      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
      expect(find.text("Gamma"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "b"), 1);
      expect(AnimatedItems.opacityOf(tester, "c"), 1);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets("useAnimatedTable captures removed items and synchronizes", (
    tester,
  ) async {
    final source = AnimatedItemSource([
      const AnimatedItem(id: "a", label: "Alpha"),
      const AnimatedItem(id: "b", label: "Beta"),
    ]);
    await tester.showComponent(
      AnimatedItems(source: source, layout: AnimatedItemsLayout.table),
    );

    source.update([const AnimatedItem(id: "c", label: "Gamma")]);
    await tester.pump();
    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta"), findsOneWidget);
    expect(find.text("Gamma"), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 301));

    await tester.pump();
    expect(source.renderedIds, ["c"]);
    expect(find.text("Alpha"), findsNothing);
    expect(find.text("Beta"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("useAnimatedTable handles keyed reorder and rapid re-add", (
    tester,
  ) async {
    final source = AnimatedItemSource([
      const AnimatedItem(id: "a", label: "Alpha"),
      const AnimatedItem(id: "b", label: "Beta"),
    ]);
    await tester.showComponent(
      AnimatedItems(source: source, layout: AnimatedItemsLayout.table),
    );

    source.update([
      const AnimatedItem(id: "b", label: "Beta"),
      const AnimatedItem(id: "a", label: "Alpha moved"),
    ]);
    await tester.pump(const Duration(milliseconds: 50));
    source.update([
      const AnimatedItem(id: "a", label: "Alpha newest"),
      const AnimatedItem(id: "c", label: "Gamma"),
    ]);
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(source.renderedIds, ["a", "c"]);
    expect(find.text("Alpha newest"), findsOneWidget);
    expect(find.text("Gamma"), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  for (final variant in [
    AnimatedItemsLayout.list,
    AnimatedItemsLayout.sliverList,
    AnimatedItemsLayout.grid,
    AnimatedItemsLayout.sliverGrid,
  ]) {
    testWidgets("${variant.name} uses its typed key and synchronizes", (
      tester,
    ) async {
      final source = AnimatedItemSource([
        const AnimatedItem(id: "a", label: "Alpha"),
      ]);

      await tester.showComponent(
        AnimatedItems(source: source, layout: variant),
      );

      source.update([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);
      await tester.pump();
      source.update([const AnimatedItem(id: "b", label: "Beta")]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 501));
      await tester.pump();

      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Beta"), findsOneWidget);
      expect(source.renderedIds, ["b"]);
      expect(tester.takeException(), isNull);
    });
  }
}
