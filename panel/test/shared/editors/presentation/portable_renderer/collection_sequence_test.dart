import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final reorderable in [false, true]) {
    testWidgets(
      "an added item slides in and a removed one squashes shut with its neighbour taking its place (reorderable: $reorderable)",
      (tester) async {
        final collection = await tester.showCollection([
          "Alpha",
          "Beta",
        ], allowReorder: reorderable);
        final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;

        collection.update(["Beta", "Gamma"]);
        await tester.pump();
        expect(
          find.text("Alpha"),
          findsOneWidget,
          reason: "the item stays while it leaves",
        );
        await tester.pumpAndSettle();
        expect(find.text("Alpha"), findsNothing);
        expect(tester.paintedRectOf(find.text("Beta")).top, alphaTop);
        expect(tester.paintedOpacityOf(find.text("Gamma")), 1);
      },
    );

    testWidgets(
      "with reduced motion a change lands on the next frame (reorderable: $reorderable)",
      (tester) async {
        final collection = await tester.showCollection(
          ["Alpha", "Beta"],
          allowReorder: reorderable,
          reducedMotion: true,
        );
        collection.update(["Beta", "Gamma"]);
        await tester.pump();
        await tester.pump();
        expect(find.text("Alpha"), findsNothing);
        expect(tester.paintedOpacityOf(find.text("Gamma")), 1);
      },
    );
  }

  testWidgets(
    "dragging an item by its handle reorders it without an arrival or removal move",
    (tester) async {
      final collection = await tester.showCollection([
        "Alpha",
        "Beta",
        "Gamma",
      ], allowReorder: true);
      final alphaTop = tester.paintedRectOf(find.text("Alpha")).top;

      await tester.dragHandleOf("Gamma", to: alphaTop);
      // The list commits the move once its drop animation ends; a second
      // covers the drop and any arrival the move could start.
      for (var frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          tester.paintedOpacityOf(find.text("Gamma")),
          1,
          reason: "a moved item does not arrive again",
        );
      }
      expect(collection.order, ["Gamma", "Alpha", "Beta"]);

      await tester.pumpAndSettle();
      expect(tester.paintedRectOf(find.text("Gamma")).top, alphaTop);
      expect(find.text("Alpha"), findsOneWidget);
    },
  );

  testWidgets(
    "an item removed by another during a drag leaves after the drop, and the drop lands where aimed",
    (tester) async {
      final collection = await tester.showCollection([
        "Alpha",
        "Beta",
        "Gamma",
      ], allowReorder: true);
      final betaTop = tester.paintedRectOf(find.text("Beta")).top;

      final drag = await tester.startHandleDrag("Gamma");
      collection.removeByOther("Alpha");
      await tester.pump();
      expect(
        find.text("Alpha"),
        findsOneWidget,
        reason: "nothing changes under the drag",
      );
      await drag.moveTo(betaTop);
      await drag.up();
      await tester.pumpAndSettle();

      expect(collection.order, ["Gamma", "Beta"]);
      expect(find.text("Alpha"), findsNothing);
    },
  );

  testWidgets("a leaving item cannot be dragged", (tester) async {
    final collection = await tester.showCollection([
      "Alpha",
      "Beta",
    ], allowReorder: true);
    collection.update(["Beta"]);
    await tester.pump();
    await tester.dragHandleOf("Alpha", by: const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(collection.order, ["Beta"]);
  });

  testWidgets("a service override reaches rowIn and listOut", (tester) async {
    // A timed override twice as long as the tuned token; read from the
    // token, never literal, in a panel shown first.
    await tester.showCollection(["Alpha"], allowReorder: false);
    final arrival = tester.settleTimeOf(MotionToken.rowIn);
    final leave = tester.settleTimeOf(MotionToken.listOut);
    final slow = await tester.showCollection(
      ["Alpha"],
      allowReorder: false,
      appearance:
          (skir.CollectionAppearance.defaultInstance.toMutable()
                ..itemArrival = skir.PresentationTransition.wrapTimed(
                  skir.PresentationTimedTransition(
                    milliseconds: arrival.inMilliseconds * 2,
                    curve: null,
                  ),
                )
                ..itemLeave = skir.PresentationTransition.wrapTimed(
                  skir.PresentationTimedTransition(
                    milliseconds: leave.inMilliseconds * 2,
                    curve: null,
                  ),
                ))
              .toFrozen(),
    );
    slow.update(["Alpha", "Beta"]);
    await tester.pump();
    await tester.pump(arrival);
    await tester.pump();
    expect(
      tester.hasRunningAnimations,
      isTrue,
      reason: "Beta arrives at the service's length",
    );
    await tester.pumpAndSettle();

    slow.update(["Beta"]);
    await tester.pump();
    await tester.pump(leave);
    await tester.pump();
    expect(
      find.text("Alpha"),
      findsOneWidget,
      reason: "Alpha leaves at the service's length",
    );
    await tester.pumpAndSettle();
    expect(find.text("Alpha"), findsNothing);
  });

  testWidgets("with no override an item plays the tuned rowIn and listOut", (
    tester,
  ) async {
    final collection = await tester.showCollection([
      "Alpha",
    ], allowReorder: false);
    collection.update(["Alpha", "Beta"]);
    await tester.pump();
    await tester.pump(tester.settleTimeOf(MotionToken.rowIn));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    collection.update(["Beta"]);
    await tester.pump();
    await tester.pump(tester.settleTimeOf(MotionToken.listOut));
    await tester.pump();
    expect(find.text("Alpha"), findsNothing);
  });

  testWidgets(
    "an added map entry slides in and a removed one squashes shut with its neighbour taking its place",
    (tester) async {
      final map = await tester.showMap({"alpha": "1", "beta": "2"});
      final alphaTop = tester.paintedRectOf(find.text("alpha")).top;

      map.update({"beta": "2", "gamma": "3"});
      await tester.pump();
      expect(
        find.text("alpha"),
        findsOneWidget,
        reason: "the entry stays while it leaves",
      );
      await tester.pumpAndSettle();
      expect(find.text("alpha"), findsNothing);
      expect(tester.paintedRectOf(find.text("beta")).top, alphaTop);
      expect(tester.paintedOpacityOf(find.text("gamma")), 1);
    },
  );
}
