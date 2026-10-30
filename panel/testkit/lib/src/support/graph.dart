import "package:typewriter_panel/typewriter_panel.dart";

/// What a test drags across a graph: the element [graphId] names, as it
/// was at [revision].
final class TestGraphDragData extends GraphDragData {
  const TestGraphDragData(this.graphId, {this.revision = 0});

  @override
  final GraphIdentifier graphId;

  /// Which version of the element's content the drag carries; a source
  /// rebuilt with new content offers a new revision.
  final int revision;
}

/// The body of a graph element the user reads as [label]; it fills its
/// element.
///
/// With a [focusNode] the body takes keyboard focus, the way a selectable
/// node does, so graph shortcuts reach it.
class GraphNode extends StatelessWidget {
  const GraphNode(
    this.label, {
    this.focusNode,
    this.color = Colors.blue,
    super.key,
  });

  final String label;
  final FocusNode? focusNode;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final body = Semantics(
      container: true,
      label: label,
      child: SizedBox.expand(child: ColoredBox(color: color)),
    );
    final node = focusNode;
    if (node == null) return body;
    return Focus(focusNode: node, child: body);
  }
}

/// A graph element body the user reads as [label] and drags across the
/// graph, offering [TestGraphDragData] for the element [id] names.
///
/// While dragged outside a graph it shows an avatar read as "Dragging
/// [label]"; inside a graph the graph previews the move instead.
///
/// [id] defaults to [label]; a different id offers an element the graph does
/// not know. [child] replaces the plain body, such as a drop target region
/// around it. [revision] versions the offered data, and [onOffered] sees
/// every payload the node offers.
class DraggableGraphNode extends HookWidget {
  const DraggableGraphNode(
    this.label, {
    this.id,
    this.revision = 0,
    this.onOffered,
    this.child,
    super.key,
  });

  final String label;
  final String? id;
  final int revision;
  final void Function(GraphDragPayload<TestGraphDragData> payload)? onOffered;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final source = useGraphDragSource(
      context,
      TestGraphDragData(GraphIdentifier(id ?? label), revision: revision),
    );
    final offered = source.payload;
    onOffered?.call(offered);
    return Draggable<GraphDragPayload<GraphDragData>>(
      data: offered,
      key: ObjectKey(offered),
      maxSimultaneousDrags: 1,
      // The avatar is read like the node, so a test sees when it shows.
      ignoringFeedbackSemantics: false,
      dragAnchorStrategy: (widget, context, position) =>
          source.anchor(offered, widget, context, position),
      onDragStarted: () => source.begin(offered),
      onDragUpdate: (details) => source.update(offered, details),
      onDragEnd: (_) => source.end(offered),
      feedback: HookBuilder(
        builder: (context) {
          useListenable(source.state);
          useListenable(offered);
          if (!source.showFeedback(offered)) return const SizedBox.shrink();
          return Semantics(
            container: true,
            label: "Dragging $label",
            child: const SizedBox(width: 40, height: 40),
          );
        },
      ),
      child: child ?? GraphNode(label),
    );
  }
}

/// A square element of [cells] cells at cell ([x], [y]), identified by
/// [label], ranked by [priority] when elements overlap.
///
/// Its body is [body], or a [GraphNode] read as [label] that takes
/// [focusNode].
GraphElement graphNode(
  String label, {
  int x = 0,
  int y = 0,
  int cells = 2,
  int priority = 0,
  FocusNode? focusNode,
  Widget? body,
}) => graphElement(
  label,
  x: x,
  y: y,
  width: cells,
  height: cells,
  priority: priority,
  focusNode: focusNode,
  body: body,
);

/// An element identified by [id] at cell ([x], [y]) of [width] by [height]
/// cells, ranked by [priority] when elements overlap.
///
/// Its body is [body], or a [GraphNode] read as [id] that takes [focusNode].
GraphElement graphElement(
  String id, {
  int x = 0,
  int y = 0,
  int width = 1,
  int height = 1,
  int priority = 0,
  FocusNode? focusNode,
  Widget? body,
}) => GraphElement(
  id: GraphIdentifier(id),
  x: x,
  y: y,
  width: width,
  height: height,
  priority: priority,
  builder: (_) => body ?? GraphNode(id, focusNode: focusNode),
);

/// A body that names itself with the [token] it was built with, as "id:token",
/// and reports to [onDispose] when its element leaves the graph.
///
/// A test uses it to see whether a reordered element keeps its state.
class GraphIdentityProbe extends StatefulWidget {
  const GraphIdentityProbe({
    required this.id,
    required this.token,
    required this.onDispose,
    super.key,
  });

  final String id;
  final int token;
  final ValueChanged<String> onDispose;

  @override
  State<GraphIdentityProbe> createState() => _GraphIdentityProbeState();
}

class _GraphIdentityProbeState extends State<GraphIdentityProbe> {
  late final int token = widget.token;

  @override
  Widget build(BuildContext context) => Text("${widget.id}:$token");

  @override
  void dispose() {
    widget.onDispose(widget.id);
    super.dispose();
  }
}
