import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

class SimpleDragData extends GraphDragData {
  const SimpleDragData({required this.graphId});

  @override
  final GraphIdentifier graphId;
}

@widgetbook.UseCase(name: "Default", type: Graph)
Widget graphUseCase(BuildContext context) {
  final content = context.knobs.object.dropdown(
    label: "Content",
    options: const [
      "Simple",
      "Complex flow",
      "Groups",
      "Edge sides",
      "Rich nodes",
      "Grid",
    ],
    initialOption: "Complex flow",
  );
  final size = context.knobs.int.slider(
    label: "Grid size",
    description: "Nodes per row and column of the Grid content",
    initialValue: 8,
    min: 2,
    max: 40,
  );
  final data = switch (content) {
    "Simple" => _simpleGraph(),
    "Groups" => _nestedGroups(),
    "Edge sides" => _edgeOrientation(),
    "Rich nodes" => _richContent(),
    "Grid" => _largeGrid(size),
    _ => _complexFlow(),
  };
  return Story(
    const [],
    at: PanelLocation.component(
      _EditableGraph(key: ValueKey((content, size)), data: data),
    ),
  );
}

/// A graph whose nodes keep where they are moved and how they are resized.
class _EditableGraph extends HookWidget {
  const _EditableGraph({required this.data, super.key});

  final GraphData data;

  @override
  Widget build(BuildContext context) {
    final elements = useState(data.elements);
    void place(GraphIdentifier id, GraphElement Function(GraphElement) change) {
      elements.value = [
        for (final element in elements.value)
          if (element.id == id) change(element) else element,
      ];
    }

    return SizedBox(
      width: 1100,
      height: 700,
      child: Graph(
        data: GraphData(
          cellSize: data.cellSize,
          elements: elements.value,
          edges: data.edges,
        ),
        onElementsMoved: (changes) {
          for (final change in changes) {
            place(change.id, (it) => it.copyWith(x: change.x, y: change.y));
          }
        },
        onElementsResized: (changes) {
          for (final change in changes) {
            place(
              change.id,
              (it) => it.copyWith(width: change.width, height: change.height),
            );
          }
        },
      ),
    );
  }
}

class _SimpleNode<D extends GraphDragData> extends HookWidget {
  const _SimpleNode({
    required this.text,
    required this.color,
    required this.data,
    this.padding = 8,
    super.key,
  });

  final String text;
  final Color color;
  final double padding;
  final D data;

  @override
  Widget build(BuildContext context) {
    final lift = useMotionController();
    final hoverIn = resolveMotion(context, MotionToken.hoverIn);
    final hoverOut = resolveMotion(context, MotionToken.hoverOut);
    final dragSource = useGraphDragSource(context, data);
    final offered = dragSource.payload;
    return LayoutBuilder(
      builder: (context, constraints) {
        final child = Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: .alphaBlend(
              color.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ),
            border: .all(color: color, width: 2),
            borderRadius: .circular(8),
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

        return Draggable<GraphDragPayload<GraphDragData>>(
          data: offered,
          key: ObjectKey(offered),
          maxSimultaneousDrags: 1,
          dragAnchorStrategy: (widget, context, position) =>
              dragSource.anchor(offered, widget, context, position),
          onDragUpdate: (details) => dragSource.update(offered, details),
          onDragEnd: (_) => dragSource.end(offered),
          feedback: HookBuilder(
            builder: (context) {
              useListenable(dragSource.state);
              useListenable(offered);
              return !dragSource.showFeedback(offered)
                  ? SizedBox()
                  : Opacity(opacity: 0.5, child: themes.wrap(child));
            },
          ),
          child: GestureDetector(
            // A tap lifts the node and lets it settle back.
            onTap: () async {
              await lift.to(1, hoverIn);
              await lift.to(0, hoverOut);
            },
            child: AnimatedBuilder(
              animation: lift,
              child: child,
              builder: (context, child) =>
                  Transform.scale(scale: 1 + 0.2 * lift.value, child: child),
            ),
          ),
        );
      },
    );
  }
}

GraphData _simpleGraph() {
  final data = GraphData(
    cellSize: 40.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("start"),
        x: 20,
        y: 20,
        width: 3,
        height: 2,
        builder: (_) => _SimpleNode(
          text: "Start",
          color: Colors.blue,
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
        builder: (_) => _SimpleNode(
          text: "End",
          color: Colors.red,
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

  return data;
}

GraphData _complexFlow() {
  final data = GraphData(
    cellSize: 50.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("entry"),
        x: 1,
        y: 1,
        width: 2,
        height: 1,
        builder: (_) => _SimpleNode(
          text: "Entry Point",
          color: Colors.blue,
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
        builder: (_) => _SimpleNode(
          text: "Process A",
          color: Colors.orange,
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
        builder: (_) => _SimpleNode(
          text: "Process B",
          color: Colors.orange,
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
        builder: (_) => _SimpleNode(
          text: "Decision",
          color: Colors.pink,
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
        builder: (_) => _SimpleNode(
          text: "Output",
          color: Colors.green,
          data: const SimpleDragData(graphId: GraphIdentifier("output")),
        ),
        priority: 1,
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

  return data;
}

GraphData _nestedGroups() {
  final data = GraphData(
    cellSize: 40.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("frontend1"),
        x: 2,
        y: 3,
        width: 3,
        height: 1,
        builder: (_) => _SimpleNode(
          text: "React App",
          color: Colors.blue,
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
        builder: (_) => _SimpleNode(
          text: "Vue App",
          color: Colors.blue,
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
        builder: (_) => _SimpleNode(
          text: "API",
          color: Colors.green,
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
        builder: (_) => _SimpleNode(
          text: "DB",
          color: Colors.orange,
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
        builder: (_) => _SimpleNode(
          text: "Cache",
          color: Colors.orange,
          data: const SimpleDragData(graphId: GraphIdentifier("cache")),
        ),
        priority: 1,
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

  return data;
}

GraphData _largeGrid(int size) {
  final elements = <GraphElement>[];
  final edges = <GraphEdge>[];

  final max = size;

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
          builder: (_) => _SimpleNode(
            text: "$i,$j",
            color: Colors.teal,
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

  final data = GraphData(cellSize: 25.0, elements: elements, edges: edges);

  return data;
}

GraphData _edgeOrientation() {
  final data = GraphData(
    cellSize: 60.0,
    elements: [
      GraphElement(
        id: const GraphIdentifier("center"),
        x: 3,
        y: 3,
        width: 2,
        height: 2,
        builder: (_) => _SimpleNode(
          text: "Center",
          color: Colors.blue,
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
        builder: (_) => _SimpleNode(
          text: "Top",
          color: Colors.red,
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
        builder: (_) => _SimpleNode(
          text: "Bottom",
          color: Colors.green,
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
        builder: (_) => _SimpleNode(
          text: "Left",
          color: Colors.orange,
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
        builder: (_) => _SimpleNode(
          text: "Right",
          color: Colors.purple,
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

  return data;
}

GraphData _richContent() {
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

  return data;
}
