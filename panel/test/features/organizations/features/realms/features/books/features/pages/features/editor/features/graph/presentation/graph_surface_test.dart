import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../../../../../../../support/test_utils.dart";

GraphElement _element(String id, {int priority = 0, WidgetBuilder? builder}) {
  return GraphElement(
    id: GraphIdentifier(id),
    x: 0,
    y: 0,
    width: 2,
    height: 2,
    priority: priority,
    builder: builder ?? (_) => const SizedBox.expand(),
  );
}

GraphData _data({
  required List<GraphElement> elements,
  List<GraphEdge> edges = const [],
}) {
  return GraphData(cellSize: 50, elements: elements, edges: edges);
}

void main() {
  group("GraphSurface", () {
    testWidgets("refreshes replaced and removed edges", (tester) async {
      final elements = [_element("source"), _element("target")];

      Future<RenderGraphSurface> pump(List<GraphEdge> edges) async {
        await tester.pumpTestApp(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(
              data: _data(elements: elements, edges: edges),
            ),
          ),
        );
        return tester.renderObject<RenderGraphSurface>(
          find.byType(GraphSurface),
        );
      }

      final initial = await pump(const [
        GraphEdge(
          id: "edge",
          source: GraphIdentifier("source"),
          target: GraphIdentifier("target"),
          color: Colors.red,
        ),
      ]);
      expect(initial.visibleEdges.single.edge.color, Colors.red);

      final replaced = await pump(const [
        GraphEdge(
          id: "edge",
          source: GraphIdentifier("source"),
          target: GraphIdentifier("target"),
          color: Colors.blue,
          sourceSide: EdgeSide.bottom,
          targetSide: EdgeSide.top,
        ),
      ]);
      expect(replaced.visibleEdges.single.edge.color, Colors.blue);
      expect(replaced.visibleEdges.single.edge.sourceSide, EdgeSide.bottom);

      final removed = await pump(const []);
      expect(removed.visibleEdges, isEmpty);
    });

    testWidgets("reconciles visible children by graph identifier", (
      tester,
    ) async {
      var nextToken = 0;
      final disposed = <String>[];

      GraphElement probe(String id, int priority) {
        return _element(
          id,
          priority: priority,
          builder: (_) => _IdentityProbe(
            id: id,
            token: ++nextToken,
            onDispose: disposed.add,
          ),
        );
      }

      Future<void> pump(List<GraphElement> elements) {
        return tester.pumpTestApp(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Graph(data: _data(elements: elements)),
          ),
        );
      }

      await pump([probe("a", 0), probe("b", 1)]);
      expect(find.text("a:1"), findsOneWidget);
      expect(find.text("b:2"), findsOneWidget);

      await pump([probe("b", 0), probe("a", 1)]);
      expect(find.text("a:1"), findsOneWidget);
      expect(find.text("b:2"), findsOneWidget);
      expect(disposed, isEmpty);

      await pump([probe("a", 0)]);
      expect(find.text("a:1"), findsOneWidget);
      expect(disposed, ["b"]);

      await pump([probe("a", 0), probe("c", 1)]);
      expect(find.text("a:1"), findsOneWidget);
      expect(find.text("c:7"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("disposes viewport animation during unmount", (tester) async {
      GraphViewportController? controller;
      await tester.pumpTestApp(
        child: HookBuilder(
          builder: (context) {
            controller = useGraphViewportController(
              tickerProvider: useSingleTickerProvider(),
              initialTransform: Matrix4.identity(),
            );
            return const SizedBox();
          },
        ),
      );

      controller!.zoomAt(Offset.zero, 1.2);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
    });

    testWidgets("recursively reduces and fades dots while zooming out", (
      tester,
    ) async {
      await tester.pumpTestApp(
        child: SizedBox(
          width: 800,
          height: 600,
          child: Graph(data: _data(elements: const [])),
        ),
      );

      RenderGraphSurface surface() =>
          tester.renderObject<RenderGraphSurface>(find.byType(GraphSurface));

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final transformation = viewer.transformationController!;

      expect(surface().dotPattern, (stride: 1, fadingOpacity: 1, radius: 2));

      transformation.value = Matrix4.diagonal3Values(0.4, 0.4, 1);
      await tester.pump();
      expect(surface().dotPattern.stride, 1);
      expect(surface().dotPattern.fadingOpacity, closeTo(0.678, 0.001));
      expect(surface().dotPattern.radius, closeTo(2.5, 0.001));

      transformation.value = Matrix4.diagonal3Values(0.25, 0.25, 1);
      await tester.pump();
      expect(surface().dotPattern, (stride: 2, fadingOpacity: 1, radius: 4));

      transformation.value = Matrix4.diagonal3Values(0.125, 0.125, 1);
      await tester.pump();
      expect(surface().dotPattern, (stride: 4, fadingOpacity: 1, radius: 8));
    });
  });
}

class _IdentityProbe extends StatefulWidget {
  const _IdentityProbe({
    required this.id,
    required this.token,
    required this.onDispose,
  });

  final String id;
  final int token;
  final ValueChanged<String> onDispose;

  @override
  State<_IdentityProbe> createState() => _IdentityProbeState();
}

class _IdentityProbeState extends State<_IdentityProbe> {
  late final int token = widget.token;

  @override
  Widget build(BuildContext context) => Text("${widget.id}:$token");

  @override
  void dispose() {
    widget.onDispose(widget.id);
    super.dispose();
  }
}
