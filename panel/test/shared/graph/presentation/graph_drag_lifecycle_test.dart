import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("stationary pointer follows viewport resize and layout shift", (
    tester,
  ) async {
    final width = ValueNotifier(500.0);
    final left = ValueNotifier(0.0);
    addTearDown(width.dispose);
    addTearDown(left.dispose);
    await tester.pumpTestApp(
      child: HookBuilder(
        builder: (context) {
          useListenable(width);
          useListenable(left);
          return Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.only(left: left.value),
              child: SizedBox(
                width: width.value,
                height: 300,
                child: Graph(
                  data: _graphData(const _Source()),
                  onElementsMoved: (_) {},
                ),
              ),
            ),
          );
        },
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey("source"))),
    );
    await gesture.moveBy(const Offset(25, 0));
    await tester.pump();
    final controller = tester
        .widget<GraphDrag>(find.byType(GraphDrag))
        .controller;
    final position = controller.value!.globalPosition;
    expect(controller.value?.inside, isTrue);
    expect(find.byKey(const ValueKey("feedback")), findsNothing);

    width.value = 100;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.globalPosition, position);
    expect(controller.value?.inside, isFalse);
    expect(find.byKey(const ValueKey("feedback")), findsOneWidget);

    width.value = 500;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.inside, isTrue);
    left.value = position.dx + 20;
    await tester.pump();
    await tester.pump();
    expect(controller.value?.inside, isFalse);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final cancelOld in [false, true]) {
    testWidgets(
      "same ID avatar cannot change replacement movement with old cancel $cancelOld",
      (tester) async {
        final generation = ValueNotifier(0);
        addTearDown(generation.dispose);
        final moves = <List<GraphMoveCommitPayload>>[];
        await tester.pumpTestApp(
          child: SizedBox(
            width: 600,
            height: 400,
            child: Graph(
              data: _graphData(
                ValueListenableBuilder<int>(
                  valueListenable: generation,
                  builder: (_, value, _) => _Source(key: ValueKey(value)),
                ),
              ),
              onElementsMoved: moves.add,
            ),
          ),
        );
        final source = find.byKey(const ValueKey("source"));
        final oldGesture = await tester.startGesture(
          tester.getCenter(source),
          pointer: 1,
        );
        await oldGesture.moveBy(const Offset(25, 0));
        await tester.pump();
        final controller = tester
            .widget<GraphDrag>(find.byType(GraphDrag))
            .controller;
        final old = controller.value!.payload;
        generation.value++;
        await tester.pump();
        await tester.pump();
        expect(old.phase, GraphDragPhase.retired);

        final newGesture = await tester.startGesture(
          tester.getCenter(source),
          pointer: 2,
        );
        await newGesture.moveBy(const Offset(25, 0));
        await tester.pump();
        await newGesture.moveBy(const Offset(50, 0));
        await tester.pump();
        final replacement = controller.value!.payload;
        expect(replacement.value.graphId, old.value.graphId);
        expect(replacement, isNot(same(old)));
        final position = controller.value!.globalPosition;
        final preview = controller.preview(50);

        await oldGesture.moveTo(const Offset(790, 590));
        await tester.pump();
        await oldGesture.moveTo(position);
        await tester.pump();
        if (cancelOld) {
          await oldGesture.cancel();
        } else {
          await oldGesture.up();
        }
        await tester.pump();
        expect(moves, isEmpty);
        expect(controller.value!.payload, same(replacement));
        expect(controller.value!.globalPosition, position);
        expect(controller.preview(50), preview);
        await newGesture.up();
        await tester.pumpAndSettle();
        expect(moves, hasLength(1));
        expect(moves.single.single.id, const GraphIdentifier("same"));
        expect(controller.value, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    "source rebuild preserves the avatar snapshot until its next gesture",
    (tester) async {
      final revision = ValueNotifier(0);
      addTearDown(revision.dispose);
      final payloads = <GraphDragPayload<_Data>>[];
      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 150,
            height: 100,
            child: ValueListenableBuilder<int>(
              valueListenable: revision,
              builder: (_, value, _) =>
                  _Source(revision: value, observe: payloads.add),
            ),
          ),
        ),
      );
      final source = find.byKey(const ValueKey("source"));
      final first = await tester.startGesture(tester.getCenter(source));
      await first.moveBy(const Offset(25, 0));
      await tester.pump();
      final active = payloads.last;
      revision.value = 1;
      await tester.pump();
      expect(payloads.last, same(active));
      expect(active.value.revision, 0);
      await first.up();
      await tester.pumpAndSettle();
      expect(payloads.last, isNot(same(active)));
      expect(payloads.last.value.revision, 1);
      expect(active.phase, GraphDragPhase.retired);
    },
  );
}

GraphData _graphData(Widget child) => GraphData(
  cellSize: 50,
  elements: [
    GraphElement(
      id: const GraphIdentifier("same"),
      x: 0,
      y: 0,
      width: 2,
      height: 2,
      builder: (_) => child,
    ),
  ],
  edges: const [],
);

class _Data extends GraphDragData {
  const _Data(this.revision);
  final int revision;
  @override
  GraphIdentifier get graphId => const GraphIdentifier("same");
}

class _Source extends HookWidget {
  const _Source({this.revision = 0, this.observe, super.key});
  final int revision;
  final void Function(GraphDragPayload<_Data>)? observe;

  @override
  Widget build(BuildContext context) {
    final source = useGraphDragSource(context, _Data(revision));
    final offered = source.payload;
    observe?.call(offered);
    return Draggable<GraphDragPayload<_Data>>(
      key: ObjectKey(offered),
      data: offered,
      rootOverlay: true,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: (widget, context, position) =>
          source.anchor(offered, widget, context, position),
      onDragStarted: () => source.begin(offered),
      onDragUpdate: (details) => source.update(offered, details),
      onDragEnd: (_) => source.end(offered),
      feedback: HookBuilder(
        builder: (context) {
          useListenable(source.state);
          useListenable(offered);
          return source.showFeedback(offered)
              ? const SizedBox(key: ValueKey("feedback"), width: 40, height: 40)
              : const SizedBox.shrink();
        },
      ),
      child: const ColoredBox(key: ValueKey("source"), color: Colors.blue),
    );
  }
}
