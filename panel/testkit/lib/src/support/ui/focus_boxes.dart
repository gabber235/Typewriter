import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../core/pump_panel.dart";
import "../../core/stage.dart";
import "../../drivers/panel_driver.dart";

/// One focusable box the user reads as [id], placed in a 600 by 600 area.
final class FocusBox {
  const FocusBox(this.id, this.left, this.top, this.width, this.height);

  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
}

/// Focus nodes for [boxes], disposed with the test.
Map<String, FocusNode> focusNodesFor(List<FocusBox> boxes) {
  final nodes = {
    for (final box in boxes) box.id: FocusNode(debugLabel: box.id),
  };
  addTearDown(() {
    for (final node in nodes.values) {
      node.dispose();
    }
  });
  return nodes;
}

/// [boxes] under a [TwoDFocusTraversalPolicy], each focusable through its
/// node in [nodes] and labeled with its id.
Widget _focusBoxLayout(
  List<FocusBox> boxes,
  Map<String, FocusNode> nodes, {
  required Axis mainAxis,
  double crossAxisBandTolerance = 12.0,
  TraversalEdgeBehavior edgeBehavior = TraversalEdgeBehavior.stop,
}) {
  return HookBuilder(
    builder: (context) {
      final scope = useEdgeScope(edgeBehavior);
      return FocusTraversalGroup(
        policy: TwoDFocusTraversalPolicy(
          mainAxis: mainAxis,
          crossAxisBandTolerance: crossAxisBandTolerance,
        ),
        child: FocusScope.withExternalFocusNode(
          focusScopeNode: scope,
          child: SizedBox(
            width: 600,
            height: 600,
            child: Stack(
              children: [
                for (final box in boxes)
                  Positioned(
                    left: box.left,
                    top: box.top,
                    width: box.width,
                    height: box.height,
                    child: Semantics(
                      container: true,
                      label: box.id,
                      child: Focus(
                        focusNode: nodes[box.id],
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Showing focusable boxes in the panel.
extension ShowFocusBoxes on WidgetTester {
  /// Shows [boxes] under a [TwoDFocusTraversalPolicy] along [mainAxis],
  /// each focusable through its node and labeled with its id, and returns
  /// the panel with each box's focus node by id.
  Future<(PanelDriver, Map<String, FocusNode>)> showFocusBoxes(
    List<FocusBox> boxes, {
    required Axis mainAxis,
    double crossAxisBandTolerance = 12.0,
    TraversalEdgeBehavior edgeBehavior = TraversalEdgeBehavior.stop,
  }) async {
    final nodes = focusNodesFor(boxes);
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        _focusBoxLayout(
          boxes,
          nodes,
          mainAxis: mainAxis,
          crossAxisBandTolerance: crossAxisBandTolerance,
          edgeBehavior: edgeBehavior,
        ),
      ),
    );
    return (panel, nodes);
  }
}

/// A focus node named [label] that ends with the current test.
FocusNode testFocusNode(String label) {
  final node = FocusNode(debugLabel: label);
  addTearDown(node.dispose);
  return node;
}

/// Moving keyboard focus directly.
extension RequestFocus on PanelDriver {
  /// Puts keyboard focus on [node] and lets the panel react.
  Future<void> requestFocus(FocusNode node) async {
    node.requestFocus();
    await settle();
  }
}

/// A focus scope that [edgeBehavior] governs at its directional edges.
FocusScopeNode useEdgeScope(TraversalEdgeBehavior edgeBehavior) {
  final scope = useMemoized(
    () => FocusScopeNode(directionalTraversalEdgeBehavior: edgeBehavior),
  );
  useEffect(() => scope.dispose, [scope]);
  return scope;
}
