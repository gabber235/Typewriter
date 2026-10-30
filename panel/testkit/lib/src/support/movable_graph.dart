import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/shared/selectables/test_selectable.dart";
import "package:typewriter_testkit/src/support/graph.dart";

/// A selectable identifier of a graph node, focused or selected by its [id].
class GraphSelectableIdentifier extends TestSelectableIdentifier
    implements GraphIdentifier {
  GraphSelectableIdentifier({required super.id});
}

/// A graph that the test moves: its nodes keep the focus nodes they were given
/// and the moves the graph committed, in order, in [calls].
typedef MovableGraph = ({
  PanelDriver panel,
  Map<String, FocusNode> focusNodes,
  List<List<GraphMoveCommitPayload>> calls,
});

/// Pumps a graph of one node per id in [ids], each with its own focus node,
/// in a canvas of [size]. Moves commit back into the graph, so a node keeps
/// its new place.
///
/// [selection] picks what the user selected from the identifiers of the
/// focusable nodes; the selection is applied before the first frame.
extension PumpMovableGraph on WidgetTester {
  Future<MovableGraph> pumpMovableGraph({
    required List<String> ids,
    required List<SelectableIdentifier> Function(
      Map<String, GraphSelectableIdentifier> focused,
    )
    selection,
    Size size = const Size(800, 600),
  }) async {
    final focusedIds = {
      for (final id in ids) id: GraphSelectableIdentifier(id: id),
    };
    final focusNodes = {for (final id in ids) id: FocusNode(debugLabel: id)};
    addTearDown(() {
      for (final node in focusNodes.values) {
        node.dispose();
      }
    });
    final calls = <List<GraphMoveCommitPayload>>[];
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        _MovableGraph(
          focusedIds: focusedIds,
          focusNodes: focusNodes,
          onMoved: calls.add,
          size: size,
        ),
      ),
    );
    panel.container
        .read(selectionProvider.notifier)
        .selectAll(selection(focusedIds));
    await panel.settle();
    return (panel: panel, focusNodes: focusNodes, calls: calls);
  }
}

/// Moves a graph into move mode with the Shift+M keys.
extension EnterGraphMoveMode on PanelDriver {
  /// Presses Shift+M and sends the next key before any frame runs.
  Future<void> pressMoveModeKeysWithoutPump() async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }

  /// Presses Shift+M once the focus settled and lets the move mode start.
  Future<void> enterMoveMode() async {
    await settle();
    await pressMoveModeKeysWithoutPump();
    await settle();
  }
}

class _MovableGraph extends StatefulWidget {
  const _MovableGraph({
    required this.focusedIds,
    required this.focusNodes,
    required this.onMoved,
    required this.size,
  });

  final Map<String, GraphSelectableIdentifier> focusedIds;
  final Map<String, FocusNode> focusNodes;
  final ValueChanged<List<GraphMoveCommitPayload>> onMoved;
  final Size size;

  @override
  State<_MovableGraph> createState() => _MovableGraphState();
}

class _MovableGraphState extends State<_MovableGraph> {
  late final Map<String, (int, int)> positions = {
    for (final MapEntry(key: index, value: id)
        in widget.focusedIds.keys.toList().asMap().entries)
      id: (index * 3, 0),
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.fromSize(
        size: widget.size,
        child: Graph(
          data: GraphData(
            cellSize: 50,
            elements: [
              for (final entry in positions.entries)
                GraphElement(
                  id: GraphIdentifier(entry.key),
                  x: entry.value.$1,
                  y: entry.value.$2,
                  width: 2,
                  height: 2,
                  builder: (_) => Selector(
                    selectableId: widget.focusedIds[entry.key]!,
                    focusNode: widget.focusNodes[entry.key]!,
                    builder: (_, _, _) => GraphNode(entry.key),
                  ),
                ),
            ],
            edges: const [],
          ),
          onElementsMoved: (changes) {
            widget.onMoved(changes);
            setState(() {
              for (final change in changes) {
                positions[change.id.id] = (change.x, change.y);
              }
            });
          },
        ),
      ),
    );
  }
}
