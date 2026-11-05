import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Reading the semantics tree the way assistive technology does.
extension SemanticsReading on SemanticsNode {
  SemanticsFlags get _flags => getSemanticsData().flagsCollection;

  /// The label assistive technology reads for this node, including the
  /// labels of the nodes merged into it.
  String get spoken => getSemanticsData().label;

  /// Whether the user can activate this node with a tap.
  bool get isTappable => getSemanticsData().hasAction(SemanticsAction.tap);

  /// Whether this node holds the keyboard focus.
  bool get isFocused => _flags.isFocused == Tristate.isTrue;

  /// Whether the user can activate this node as a button.
  bool get isButton => _flags.isButton;

  /// Whether this node is enabled; nodes without an enabled state count.
  bool get isEnabled => _flags.isEnabled != Tristate.isFalse;

  /// The nodes below this one, depth first in reading order.
  List<SemanticsNode> get descendants {
    final nodes = <SemanticsNode>[];
    void visit(SemanticsNode node) {
      nodes.add(node);
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visitChildren((child) {
      visit(child);
      return true;
    });
    return nodes;
  }

  /// The labels of the buttons below this node, in reading order.
  List<String> get buttonLabels => [
    for (final node in descendants)
      if (node.isButton && node.spoken.isNotEmpty) node.spoken,
  ];

  /// The button labeled [label] below this node.
  SemanticsNode button(String label) =>
      descendants.firstWhereOrNull(
        (node) => node.isButton && node.spoken == label,
      ) ??
      (throw TestFailure("No button $label here; there are $buttonLabels"));

  /// The nearest ancestor that starts a route, such as a dialog.
  SemanticsNode? get route {
    for (var node = parent; node != null; node = node.parent) {
      if (node._flags.scopesRoute) return node;
    }
    return null;
  }

  /// This node's rectangle in logical screen coordinates; the root's
  /// transform only scales to physical pixels.
  Rect get screenRect {
    var rect = this.rect;
    for (var node = this; node.parent != null; node = node.parent!) {
      if (node.transform case final transform?) {
        rect = MatrixUtils.transformRect(transform, rect);
      }
    }
    return rect;
  }
}

/// The visible nodes labeled exactly [label].
List<SemanticsNode> semanticsLabeled(String label) =>
    find.semantics.byLabel(label).evaluate().toList();

/// The visible buttons the user hears as [label].
List<SemanticsNode> semanticsButtons(String label) => find.semantics
    .byPredicate((node) => node.isButton && node.spoken == label)
    .evaluate()
    .toList();

/// The one visible button the user hears as [label]; fails the test when
/// there is none or more than one.
SemanticsNode semanticsButton(String label) =>
    switch (semanticsButtons(label)) {
      [final button] => button,
      final buttons => throw TestFailure(
        "Expected one button $label on screen, found ${buttons.length}",
      ),
    };
