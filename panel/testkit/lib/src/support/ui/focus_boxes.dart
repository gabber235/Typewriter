import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

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

/// [boxes] under a [TwoDFocusTraversalPolicy] along [mainAxis], each
/// focusable through its node in [nodes] and labeled with its id, inside a
/// focus scope that [edgeBehavior] governs at its directional edges.
final class FocusBoxLayout extends HookWidget {
  const FocusBoxLayout(
    this.boxes,
    this.nodes, {
    required this.mainAxis,
    this.crossAxisBandTolerance = 12.0,
    this.edgeBehavior = TraversalEdgeBehavior.stop,
    super.key,
  });

  final List<FocusBox> boxes;
  final Map<String, FocusNode> nodes;
  final Axis mainAxis;
  final double crossAxisBandTolerance;
  final TraversalEdgeBehavior edgeBehavior;

  @override
  Widget build(BuildContext context) {
    final scope = useMemoized(
      () => FocusScopeNode(directionalTraversalEdgeBehavior: edgeBehavior),
    );
    useEffect(() => scope.dispose, [scope]);
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
