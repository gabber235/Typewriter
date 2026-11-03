import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

const insertion = Duration(milliseconds: 200);
const removal = Duration(milliseconds: 400);

void main() {
  group("useSliverAnimatedList", () {
    testWidgets("renders initial items with completed animations", (
      tester,
    ) async {
      await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
      );

      expect(find.text("Alpha"), findsOneWidget);
      expect(find.text("Beta"), findsOneWidget);
      expect(AnimatedItems.opacityOf(tester, "a"), 1);
      expect(AnimatedItems.opacityOf(tester, "b"), 1);
    });

    // The web engine runs both halves of a frame without flushing microtasks
    // between them, so a list can leave the tree after a row's animation ended
    // and before the code waiting on that animation runs. These frames do the same.
    testWidgets(
      "a list can go away in the frame a removed row finishes leaving",
      (tester) async {
        final source = await tester.showAnimatedItems(
          [const AnimatedItem(id: "a", label: "Alpha")],
          insertDuration: insertion,
          removeDuration: removal,
        );
        source.update(const []);
        await tester.pump();

        final binding = tester.binding;
        binding.handleBeginFrame(
          binding.currentSystemFrameTimeStamp + removal * 2,
        );
        binding.attachRootWidget(binding.wrapWithDefaultView(const SizedBox()));
        binding.handleDrawFrame();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      "a list can go away in the frame an inserted row finishes arriving",
      (tester) async {
        final source = await tester.showAnimatedItems(
          <AnimatedItem>[],
          insertDuration: insertion,
          removeDuration: removal,
        );
        source.update(const [AnimatedItem(id: "a", label: "Alpha")]);
        await tester.pump();

        final binding = tester.binding;
        binding.handleBeginFrame(
          binding.currentSystemFrameTimeStamp + insertion * 2,
        );
        binding.attachRootWidget(binding.wrapWithDefaultView(const SizedBox()));
        binding.handleDrawFrame();
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets("inserts in the middle using the configured duration", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "c", label: "Gamma"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Old Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
          const AnimatedItem(id: "c", label: "Gamma"),
          const AnimatedItem(id: "d", label: "Delta"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        [const AnimatedItem(id: "a", label: "Old")],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        mutableItems,
        insertDuration: insertion,
        removeDuration: removal,
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
      await tester.showAnimatedItems(
        [
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "a", label: "Duplicate"),
        ],
        insertDuration: insertion,
        removeDuration: removal,
      );

      expect(tester.takeException(), isArgumentError);
    });

    testWidgets("rejects duplicate identities before changing state", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems(
        [const AnimatedItem(id: "a", label: "Alpha")],
        insertDuration: insertion,
        removeDuration: removal,
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
      final source = await tester.showAnimatedItems(
        [const AnimatedItem(id: "a", label: "Alpha")],
        insertDuration: insertion,
        removeDuration: removal,
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
    final source = await tester.showAnimatedItems([
      const AnimatedItem(id: "a", label: "Alpha"),
      const AnimatedItem(id: "b", label: "Beta"),
    ], layout: AnimatedItemsLayout.table);

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
    final source = await tester.showAnimatedItems([
      const AnimatedItem(id: "a", label: "Alpha"),
      const AnimatedItem(id: "b", label: "Beta"),
    ], layout: AnimatedItemsLayout.table);

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

  testWidgets("an inserted row survives the removal of the row before it", (
    tester,
  ) async {
    final source = await tester.showAnimatedItems([
      const AnimatedItem(id: "a", label: "Alpha"),
    ]);

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
