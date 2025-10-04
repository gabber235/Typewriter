import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/logic/graph/edge_side.dart";
import "package:typewriter_panel/logic/graph/graph_data.dart";
import "package:typewriter_panel/logic/graph/graph_edge.dart";
import "package:typewriter_panel/logic/graph/graph_element.dart";
import "package:typewriter_panel/logic/graph/graph_identifier.dart";
import "package:typewriter_panel/utils/context.dart";
import "package:typewriter_panel/utils/fonts.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_drag.dart";
import "package:typewriter_panel/widgets/app/components/graph/graph_group.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;

class SimpleDragData extends GraphDragData {
  const SimpleDragData({
    required this.graphId,
  });

  @override
  final GraphIdentifier graphId;
}

Widget _node<D extends GraphDragData>(
  BuildContext context,
  String text,
  Color color, {
  required D data,
  double padding = 8,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      return HookBuilder(
        builder: (context) {
          final controller = useAnimationController(duration: 200.ms);

          final child = Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                color.withValues(alpha: 0.2),
                Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              border: Border.all(
                color: color,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.all(padding),
            child: FittedBox(
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  letterSpacing: 1.5,
                  fontVariations: [extraBoldWeight],
                ),
              ),
            ),
          );

          final themes = InheritedTheme.capture(
            from: context,
            to: Navigator.of(context, rootNavigator: true).context,
          );

          final graphDrag = GraphDrag.of(context);

          return Draggable(
            data: data,
            onDragStarted: () {
              // Because we initially start dragging over itself, we know that we are dragging inside the graph.
              // And want to prevent the feedback from being shown.
              // However the graph doesn't know that we are dragging on it yet.
              graphDrag.draggingInsideGraph.value = true;
            },
            feedback: HookBuilder(
              builder: (context) {
                useListenable(graphDrag.draggingInsideGraph);
                return graphDrag.draggingInsideGraph.value
                    ? SizedBox()
                    : Opacity(
                        opacity: 0.5,
                        child: themes.wrap(child),
                      );
              },
            ),
            child: GestureDetector(
              onTap: () async {
                await controller.forward();
                await controller.reverse();
              },
              child: child
                  .animate(controller: controller, autoPlay: false)
                  .scaleXY(
                    duration: 200.ms,
                    begin: 1,
                    end: 1.2,
                    curve: Curves.easeInOut,
                  ),
            ),
          );
        },
      );
    },
  );
}

@widgetbook.UseCase(name: "Simple Graph", type: Graph)
Widget simpleGraphUseCase(BuildContext context) {
  final data = GraphData(
    cellSize: 40.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("start"),
        x: 20,
        y: 20,
        width: 3,
        height: 2,
        builder: (_) => _node(
          context,
          "Start",
          Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("start")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("end"),
        x: 28,
        y: 20,
        width: 3,
        height: 2,
        builder: (_) => _node(
          context,
          "End",
          Colors.red,
          data: const SimpleDragData(graphId: GraphIdentifier("end")),
        ),
        priority: 1,
      ),
    ],
    edges: [
      const GraphEdge(
        id: "start_to_end",
        source: GraphIdentifier("start"),
        target: GraphIdentifier("end"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
    ],
  );

  return FakeApp(
    child: SizedBox(
      height: 400,
      child: Graph(
        onElementsDragged: (changes) {},
        onElementsResize: (changes) {},
        data: data,
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Complex Flow", type: Graph)
Widget complexFlowGraphUseCase(BuildContext context) {
  final data = GraphData(
    cellSize: 50.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("entry"),
        x: 1,
        y: 1,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Entry Point",
          Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("entry")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("process1"),
        x: 5,
        y: 0,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Process A",
          Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("process1")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("process2"),
        x: 5,
        y: 2,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Process B",
          Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("process2")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("decision"),
        x: 9,
        y: 1,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Decision",
          Colors.pink,
          data: const SimpleDragData(graphId: GraphIdentifier("decision")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("output"),
        x: 13,
        y: 1,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Output",
          Colors.green,
          data: const SimpleDragData(graphId: GraphIdentifier("output")),
        ),
        priority: 1,
      ),

      // Groups
      GraphElement(
        id: const GraphIdentifier("processing_group"),
        x: 4,
        y: -1,
        width: 4,
        height: 5,
        builder: (_) => GraphGroup(
          data: SimpleDragData(graphId: GraphIdentifier("processing_group")),
          title: "Processing",
          color: context.isDarkMode ? Colors.grey : Colors.grey.shade700,
        ),
      ),
    ],
    edges: [
      const GraphEdge(
        id: "entry_to_process1",
        source: GraphIdentifier("entry"),
        target: GraphIdentifier("process1"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "entry_to_process2",
        source: GraphIdentifier("entry"),
        target: GraphIdentifier("process2"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "process1_to_decision",
        source: GraphIdentifier("process1"),
        target: GraphIdentifier("decision"),
        color: Colors.orange,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "process2_to_decision",
        source: GraphIdentifier("process2"),
        target: GraphIdentifier("decision"),
        color: Colors.orange,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "decision_to_output",
        source: GraphIdentifier("decision"),
        target: GraphIdentifier("output"),
        color: Colors.pink,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
    ],
  );

  return FakeApp(
    child: SizedBox(
      height: 600,
      child: Graph(
        onElementsDragged: (changes) {},
        onElementsResize: (changes) {},
        data: data,
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Nested Groups", type: Graph)
Widget nestedGroupsGraphUseCase(BuildContext context) {
  final data = GraphData(
    cellSize: 40.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("frontend1"),
        x: 2,
        y: 3,
        width: 3,
        height: 1,
        builder: (_) => _node(
          context,
          "React App",
          Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("frontend1")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("frontend2"),
        x: 2,
        y: 5,
        width: 3,
        height: 1,
        builder: (_) => _node(
          context,
          "Vue App",
          Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("frontend2")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("api"),
        x: 8,
        y: 4,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "API",
          Colors.green,
          data: const SimpleDragData(graphId: GraphIdentifier("api")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("database"),
        x: 12,
        y: 3,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "DB",
          Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("database")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("cache"),
        x: 12,
        y: 5,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Cache",
          Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("cache")),
        ),
        priority: 1,
      ),
      // Groups
      GraphElement(
        id: const GraphIdentifier("frontend"),
        x: 1,
        y: 2,
        width: 5,
        height: 5,
        builder: (_) => GraphGroup(
          title: "Frontend",
          color: Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("frontend")),
        ),
      ),
      GraphElement(
        id: const GraphIdentifier("backend"),
        x: 7,
        y: 1,
        width: 9,
        height: 7,
        builder: (_) => GraphGroup(
          title: "Backend",
          color: Colors.green,
          data: const SimpleDragData(graphId: GraphIdentifier("backend")),
        ),
      ),
      GraphElement(
        id: const GraphIdentifier("storage"),
        x: 11,
        y: 2,
        width: 4,
        height: 5,
        builder: (_) => GraphGroup(
          title: "Storage",
          color: Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("storage")),
        ),
      ),
    ],
    edges: [
      const GraphEdge(
        id: "frontend1_to_api",
        source: GraphIdentifier("frontend1"),
        target: GraphIdentifier("api"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "frontend2_to_api",
        source: GraphIdentifier("frontend2"),
        target: GraphIdentifier("api"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "api_to_database",
        source: GraphIdentifier("api"),
        target: GraphIdentifier("database"),
        color: Colors.green,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "api_to_cache",
        source: GraphIdentifier("api"),
        target: GraphIdentifier("cache"),
        color: Colors.green,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
    ],
  );

  return FakeApp(
    child: Graph(
      onElementsDragged: (changes) {},
      onElementsResize: (changes) {},
      data: data,
    ),
  );
}

@widgetbook.UseCase(name: "Large Grid", type: Graph)
Widget largeGridGraphUseCase(BuildContext context) {
  final elements = <GraphElement>[];
  final edges = <GraphEdge>[];

  final max = 100;

  for (var i = 0; i < max; i++) {
    for (var j = 0; j < max; j++) {
      final id = "node_${i}_$j";
      elements.add(
        GraphElement(
          id: GraphIdentifier(id),
          x: i * 3,
          y: j * 3,
          width: 2,
          height: 1,
          builder: (_) => _node(
            context,
            "$i,$j",
            Colors.teal,
            padding: 2,
            data: SimpleDragData(graphId: GraphIdentifier(id)),
          ),
        ),
      );

      // Connect to right neighbor
      if (i < max - 1) {
        edges.add(
          GraphEdge(
            id: "${id}_to_${i + 1}_$j",
            source: GraphIdentifier(id),
            target: GraphIdentifier("node_${i + 1}_$j"),
            color: Colors.orange,
            sourceSide: EdgeSide.right,
            targetSide: EdgeSide.left,
          ),
        );
      }

      if (j < max - 1) {
        edges.add(
          GraphEdge(
            id: "${id}_to_${i + 1}_${j + 1}",
            source: GraphIdentifier(id),
            target: GraphIdentifier("node_${i + 1}_${j + 1}"),
            color: Colors.teal,
            sourceSide: EdgeSide.bottom,
            targetSide: EdgeSide.top,
          ),
        );
      }
    }
  }

  final data = GraphData(
    cellSize: 25.0,
    elements: elements,
    edges: edges,
  );

  return FakeApp(
    child: SizedBox(
      height: 600,
      child: Graph(data: data),
    ),
  );
}

@widgetbook.UseCase(name: "Edge Orientation Test", type: Graph)
Widget edgeOrientationTestUseCase(BuildContext context) {
  final data = GraphData(
    cellSize: 60.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("center"),
        x: 3,
        y: 3,
        width: 2,
        height: 2,
        builder: (_) => _node(
          context,
          "Center",
          Colors.blue,
          data: const SimpleDragData(graphId: GraphIdentifier("center")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("top"),
        x: 2,
        y: 0,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Top",
          Colors.red,
          data: const SimpleDragData(graphId: GraphIdentifier("top")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("bottom"),
        x: 2,
        y: 7,
        width: 2,
        height: 1,
        builder: (_) => _node(
          context,
          "Bottom",
          Colors.green,
          data: const SimpleDragData(graphId: GraphIdentifier("bottom")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("left"),
        x: -1,
        y: 4,
        width: 2,
        height: 2,
        builder: (_) => _node(
          context,
          "Left",
          Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("left")),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("right"),
        x: 7,
        y: 2,
        width: 2,
        height: 2,
        builder: (_) => _node(
          context,
          "Right",
          Colors.purple,
          data: const SimpleDragData(graphId: GraphIdentifier("right")),
        ),
        priority: 1,
      ),
    ],
    edges: [
      const GraphEdge(
        id: "center_to_top",
        source: GraphIdentifier("center"),
        target: GraphIdentifier("top"),
        color: Colors.red,
        sourceSide: EdgeSide.top,
        targetSide: EdgeSide.bottom,
      ),
      const GraphEdge(
        id: "center_to_bottom",
        source: GraphIdentifier("center"),
        target: GraphIdentifier("bottom"),
        color: Colors.green,
        sourceSide: EdgeSide.bottom,
        targetSide: EdgeSide.top,
      ),
      const GraphEdge(
        id: "center_to_left",
        source: GraphIdentifier("center"),
        target: GraphIdentifier("left"),
        color: Colors.orange,
        sourceSide: EdgeSide.left,
        targetSide: EdgeSide.right,
      ),
      const GraphEdge(
        id: "center_to_right",
        source: GraphIdentifier("center"),
        target: GraphIdentifier("right"),
        color: Colors.purple,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
    ],
  );

  return FakeApp(
    child: SizedBox(
      height: 500,
      child: Graph(
        onElementsDragged: (changes) {},
        onElementsResize: (changes) {},
        data: data,
      ),
    ),
  );
}

@widgetbook.UseCase(name: "Rich Content Nodes", type: Graph)
Widget richContentGraphUseCase(BuildContext context) {
  final data = GraphData(
    cellSize: 60.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("user_profile"),
        x: 1,
        y: 1,
        width: 3,
        height: 2,
        builder: (_) => SizedBox.expand(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const Text(
                    "User Profile",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Active",
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("notification_service"),
        x: 6,
        y: 0,
        width: 3,
        height: 2,
        builder: (_) => SizedBox.expand(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications, color: Colors.orange),
                  const Text(
                    "Notifications",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "3 pending",
                    style: TextStyle(color: Colors.orange, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("analytics"),
        x: 6,
        y: 3,
        width: 3,
        height: 2,
        builder: (_) => SizedBox.expand(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics, color: Colors.purple),
                  const Text(
                    "Analytics",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Tracking",
                    style: TextStyle(color: Colors.purple, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        priority: 1,
      ),
      GraphElement(
        id: const GraphIdentifier("dashboard"),
        x: 11,
        y: 1,
        width: 3,
        height: 2,
        builder: (_) => SizedBox.expand(
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.dashboard, color: Colors.green),
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Updated",
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
        priority: 1,
      ),
      // Groups
      GraphElement(
        id: const GraphIdentifier("services"),
        x: 5,
        y: -1,
        width: 5,
        height: 7,
        builder: (_) => GraphGroup(
          title: "Services",
          color: Colors.grey.shade100,
          data: const SimpleDragData(graphId: GraphIdentifier("services")),
        ),
      ),
    ],
    edges: [
      const GraphEdge(
        id: "profile_to_notifications",
        source: GraphIdentifier("user_profile"),
        target: GraphIdentifier("notification_service"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "profile_to_analytics",
        source: GraphIdentifier("user_profile"),
        target: GraphIdentifier("analytics"),
        color: Colors.blue,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "notifications_to_dashboard",
        source: GraphIdentifier("notification_service"),
        target: GraphIdentifier("dashboard"),
        color: Colors.orange,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
      const GraphEdge(
        id: "analytics_to_dashboard",
        source: GraphIdentifier("analytics"),
        target: GraphIdentifier("dashboard"),
        color: Colors.purple,
        sourceSide: EdgeSide.right,
        targetSide: EdgeSide.left,
      ),
    ],
  );

  return FakeApp(
    child: SizedBox(
      height: 700,
      child: Graph(
        onElementsDragged: (changes) {},
        onElementsResize: (changes) {},
        data: data,
      ),
    ),
  );
}
