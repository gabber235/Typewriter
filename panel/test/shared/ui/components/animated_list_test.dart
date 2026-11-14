import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final layout in AnimatedItemsLayout.values) {
    group("rows in a ${layout.name}", () {
      testWidgets(
        "a removed row is gone and its neighbour sits where it was once the move settles",
        (tester) async {
          final source = await tester.showAnimatedItems([
            const AnimatedItem(id: "a", label: "Alpha"),
            const AnimatedItem(id: "b", label: "Beta"),
          ], layout: layout);
          final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;

          source.update([const AnimatedItem(id: "b", label: "Beta")]);
          await tester.pump();
          expect(
            find.text("Alpha"),
            findsOneWidget,
            reason: "the row stays while it squashes shut",
          );

          await tester.pumpAndSettle();
          expect(find.text("Alpha"), findsNothing);
          expect(tester.paintedRectOf(find.text("Beta")).top, alphaTop);
        },
      );

      testWidgets(
        "a row added after the load slides in from the left and comes to rest",
        (tester) async {
          final source = await tester.showAnimatedItems([
            const AnimatedItem(id: "a", label: "Alpha"),
          ], layout: layout);
          final restLeft = tester.paintedRectOf(find.text("Alpha")).left;

          source.update([
            ...source.items,
            const AnimatedItem(id: "b", label: "Beta"),
          ]);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));
          expect(
            tester.paintedRectOf(find.text("Beta")).left,
            lessThan(restLeft),
          );

          await tester.pumpAndSettle();
          expect(tester.paintedRectOf(find.text("Beta")).left, restLeft);
          expect(tester.paintedOpacityOf(find.text("Beta")), 1);
        },
      );

      testWidgets("with reduced motion a change lands on the next frame", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems(
          [
            const AnimatedItem(id: "a", label: "Alpha"),
            const AnimatedItem(id: "b", label: "Beta"),
          ],
          layout: layout,
          reducedMotion: true,
        );
        final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;

        source.update([
          const AnimatedItem(id: "b", label: "Beta"),
          const AnimatedItem(id: "c", label: "Gamma"),
        ]);
        await tester.pump();
        await tester.pump();
        expect(find.text("Alpha"), findsNothing);
        expect(tester.paintedRectOf(find.text("Beta")).top, alphaTop);
        expect(tester.paintedOpacityOf(find.text("Gamma")), 1);
      });

      testWidgets("a leaving row ignores taps", (tester) async {
        final source = await tester.showAnimatedItems([
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ], layout: layout);

        source.update([const AnimatedItem(id: "b", label: "Beta")]);
        await tester.pump();
        await tester.tap(find.text("Alpha"), warnIfMissed: false);
        expect(source.tapped, isEmpty);
      });

      testWidgets("a reorder moves rows in place without an arrival", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ], layout: layout);
        final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;

        source.update([
          const AnimatedItem(id: "b", label: "Beta"),
          const AnimatedItem(id: "a", label: "Alpha"),
        ]);
        await tester.pump();
        expect(tester.hasRunningAnimations, isFalse);
        expect(tester.paintedRectOf(find.text("Beta")).top, alphaTop);
        expect(tester.paintedOpacityOf(find.text("Alpha")), 1);
      });

      testWidgets("a row added back while it leaves turns around and stays", (
        tester,
      ) async {
        final source = await tester.showAnimatedItems([
          const AnimatedItem(id: "a", label: "Alpha"),
          const AnimatedItem(id: "b", label: "Beta"),
        ], layout: layout);

        source.update([
          const AnimatedItem(id: "b", label: "Beta"),
          const AnimatedItem(id: "a", label: "Alpha moved"),
        ]);
        await tester.pump(const Duration(milliseconds: 50));
        source.update([const AnimatedItem(id: "b", label: "Beta")]);
        await tester.pump(const Duration(milliseconds: 50));
        source.update([
          const AnimatedItem(id: "a", label: "Alpha newest"),
          const AnimatedItem(id: "c", label: "Gamma"),
        ]);
        await tester.pumpAndSettle();

        expect(source.renderedIds, ["a", "c"]);
        expect(find.text("Alpha newest"), findsOneWidget);
        expect(tester.paintedOpacityOf(find.text("Alpha newest")), 1);
        expect(find.text("Beta"), findsNothing);
        expect(tester.takeException(), isNull);
      });
    });
  }

  for (final layout in AnimatedItemsLayout.values) {
    group("a sending row in a ${layout.name}", () {
      testWidgets(
        "stays struck through while its remove sends, then squashes shut once the item leaves",
        (tester) async {
          final source = await tester.showAnimatedItems([
            const AnimatedItem(id: "a", label: "Alpha"),
            const AnimatedItem(id: "b", label: "Beta"),
          ], layout: layout);
          final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;
          final command = Completer<void>();

          final sent = source.rows.sending(["a"], () => command.future);
          await tester.pumpAndSettle();
          expect(
            tester.textDecorationOf(find.text("Alpha")),
            TextDecoration.lineThrough,
          );
          expect(
            tester.paintedRectOf(find.text("Alpha")).top,
            alphaTop,
            reason: "the row stays in place while it sends",
          );
          await tester.tap(find.text("Alpha"), warnIfMissed: false);
          expect(source.tapped, isEmpty, reason: "a sending row ignores input");

          command.complete();
          await sent;
          source.update([const AnimatedItem(id: "b", label: "Beta")]);
          await tester.pump();
          expect(
            find.text("Alpha"),
            findsOneWidget,
            reason: "it leaves with listOut, struck through",
          );
          expect(
            tester.textDecorationOf(find.text("Alpha")),
            TextDecoration.lineThrough,
          );

          await tester.pumpAndSettle();
          expect(find.text("Alpha"), findsNothing);
          expect(tester.paintedRectOf(find.text("Beta")).top, alphaTop);
        },
      );

      testWidgets(
        "returns to present when its remove is refused, and never left",
        (tester) async {
          final source = await tester.showAnimatedItems([
            const AnimatedItem(id: "a", label: "Alpha"),
            const AnimatedItem(id: "b", label: "Beta"),
          ], layout: layout);
          final alphaRect = tester.paintedRectOf(find.text("Alpha"));

          final sent = source.rows.sending([
            "a",
          ], () async => throw StateError("refused"));
          await expectLater(sent, throwsStateError);
          await tester.pump();

          expect(
            tester.textDecorationOf(find.text("Alpha")),
            isNot(TextDecoration.lineThrough),
          );
          expect(tester.paintedRectOf(find.text("Alpha")), alphaRect);
          expect(tester.paintedOpacityOf(find.text("Alpha")), 1);
          expect(
            tester.hasRunningAnimations,
            isFalse,
            reason: "nothing moves back in",
          );
        },
      );
    });
  }

  group("a refused row", () {
    testWidgets(
      "refusing two sending rows ends their sending look together, shows "
      "both messages and jams only the first in screen order",
      (tester) async {
        final source = await tester.showAnimatedItems(numberedItems(3));
        final command = Completer<void>();
        final sent = source.rows.sending(["1", "2"], () => command.future);
        await tester.pump();

        command.complete();
        await sent;
        source.rows.refuse({"2": "Two refused", "1": "One refused"});
        await tester.pump();

        for (final row in ["Row 1", "Row 2"]) {
          expect(
            tester.textDecorationOf(find.text(row)),
            isNot(TextDecoration.lineThrough),
          );
        }
        expect(find.text("One refused"), findsOneWidget);
        expect(find.text("Two refused"), findsOneWidget);
        expect(source.rows["1"]!.jams, 1);
        expect(source.rows["2"]!.jams, 0);
      },
    );

    testWidgets("sending a refused row again clears its message", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems(numberedItems(2));
      await source.rows.sending(["0"], () async {});
      source.rows.refuse({"0": "Refused"});
      await tester.pump();

      final again = Completer<void>();
      final sent = source.rows.sending(["0"], () => again.future);
      await tester.pump();

      expect(find.text("Refused"), findsNothing);
      again.complete();
      await sent;
    });

    testWidgets("refusing a leaving row changes nothing", (tester) async {
      final source = await tester.showAnimatedItems(numberedItems(2));
      source.update(numberedItems(2).sublist(1));
      await tester.pump();

      source.rows.refuse({"0": "Refused"});
      await tester.pump();

      expect(find.text("Refused"), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text("Row 0"), findsNothing);
    });
  });

  group("the load", () {
    testWidgets(
      "rows present when content loads ripple in once, and all are visible after the ripple",
      (tester) async {
        final window = (await resolveMotionIn(
          tester,
          MotionToken.loadIn,
        )).landing.stagger!.within;
        final source = await tester.showAnimatedItems(
          numberedItems(30),
          inPane: true,
          settle: false,
        );
        final visible = [
          for (var row = 0; row < 8; row++) find.text("Row $row"),
        ];
        expect(
          tester.paintedOpacityOf(visible.first),
          lessThan(1),
          reason: "the rows wait for the run",
        );

        await tester.runFrames(window);
        for (final row in visible) {
          expect(
            tester.paintedOpacityOf(row),
            greaterThan(0),
            reason: "every visible row has started",
          );
        }

        await tester.pumpAndSettle();
        for (final row in visible) {
          expect(tester.paintedOpacityOf(row), 1);
        }

        // Once per pane: the same rows shown again do not ripple.
        source.visible.value = false;
        await tester.pump();
        source.visible.value = true;
        await tester.pump();
        expect(tester.paintedOpacityOf(visible.first), 1);
      },
    );

    testWidgets(
      "with reduced motion loaded rows are all visible on the first frame",
      (tester) async {
        await tester.showAnimatedItems(
          numberedItems(30),
          inPane: true,
          settle: false,
          reducedMotion: true,
        );
        await tester.pump();
        expect(tester.paintedOpacityOf(find.text("Row 7")), 1);
      },
    );
  });

  group("the rows hook", () {
    // The web engine runs both halves of a frame without flushing microtasks
    // between them, so a list can leave the tree after a row's move ended
    // and before the code waiting on that move runs. These frames do the same.
    for (final (name, from, to) in [
      (
        "a removed row finishes leaving",
        const [AnimatedItem(id: "a", label: "Alpha")],
        const <AnimatedItem>[],
      ),
      (
        "an inserted row finishes arriving",
        const <AnimatedItem>[],
        const [AnimatedItem(id: "a", label: "Alpha")],
      ),
    ]) {
      testWidgets("a list can go away in the frame $name", (tester) async {
        final source = await tester.showAnimatedItems(List.of(from));
        final settle =
            tester.settleTimeOf(MotionToken.listOut) +
            tester.settleTimeOf(MotionToken.rowIn);
        source.update(List.of(to));
        await tester.pump();

        final binding = tester.binding;
        binding.handleBeginFrame(
          binding.currentSystemFrameTimeStamp + settle * 2,
        );
        binding.attachRootWidget(binding.wrapWithDefaultView(const SizedBox()));
        binding.handleDrawFrame();
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets("mixed changes and a reorder settle in data order", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
        const AnimatedItem(id: "d", label: "Delta"),
      ]);

      source.update([
        const AnimatedItem(id: "d", label: "Delta"),
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "e", label: "Epsilon"),
      ]);
      await tester.pumpAndSettle();

      expect(source.renderedIds, ["d", "b", "e"]);
      expect(
        tester.paintedRectOf(find.text("Delta")).top,
        lessThan(tester.paintedRectOf(find.text("Beta")).top),
      );
      expect(
        tester.paintedRectOf(find.text("Beta")).top,
        lessThan(tester.paintedRectOf(find.text("Epsilon")).top),
      );
      expect(find.text("Alpha"), findsNothing);
      expect(find.text("Gamma"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("stays synchronized across rapid updates", (tester) async {
      final source = await tester.showAnimatedItems([
        const AnimatedItem(id: "a", label: "Alpha"),
        const AnimatedItem(id: "b", label: "Beta"),
      ]);

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
      await tester.pumpAndSettle();

      expect(source.renderedIds, ["d", "e"]);
      expect(find.text("Delta"), findsOneWidget);
      expect(find.text("Epsilon"), findsOneWidget);
      expect(find.text("Beta"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("an updated item changes in place without a move", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems([
        const AnimatedItem(id: "a", label: "Old"),
      ]);

      source.update([const AnimatedItem(id: "a", label: "New")]);
      await tester.pump();

      expect(find.text("Old"), findsNothing);
      expect(find.text("New"), findsOneWidget);
      expect(tester.paintedOpacityOf(find.text("New")), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets("rejects duplicate identities before changing its rows", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems([
        const AnimatedItem(id: "a", label: "Alpha"),
      ]);

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
      await tester.pumpAndSettle();

      expect(source.renderedIds, ["a", "b"]);
      expect(tester.takeException(), isNull);
    });

    testWidgets("rows follow their data while the list is hidden", (
      tester,
    ) async {
      final source = await tester.showAnimatedItems([
        const AnimatedItem(id: "a", label: "Alpha"),
      ]);

      source.visible.value = false;
      await tester.pump();
      source.update([
        const AnimatedItem(id: "b", label: "Beta"),
        const AnimatedItem(id: "c", label: "Gamma"),
      ]);
      await tester.pumpAndSettle();

      source.visible.value = true;
      await tester.pump();

      expect(find.text("Alpha"), findsNothing);
      expect(tester.paintedOpacityOf(find.text("Beta")), 1);
      expect(tester.paintedOpacityOf(find.text("Gamma")), 1);
      expect(tester.takeException(), isNull);
    });
  });
}
