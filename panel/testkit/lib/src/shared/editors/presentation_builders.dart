/// Builders for portable presentation trees in tests and Widgetbook stories.
///
/// Nodes keep default properties and no header. Callers needing more detail
/// adjust the result through `toMutable()` or build the element themselves.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A literal expression for [value].
skir.ExpressionNode literalExpression(skir.DataValue value) =>
    skir.ExpressionNode.wrapLiteral(value);

/// A literal text expression.
skir.ExpressionNode textLiteral(String value) =>
    literalExpression(skir.DataValue.wrapStringValue(value));

/// A literal floating point expression.
skir.ExpressionNode numberLiteral(double value) =>
    literalExpression(skir.DataValue.wrapFloat(value));

/// A literal integer expression.
skir.ExpressionNode integerLiteral(int value) =>
    literalExpression(skir.DataValue.wrapInteger("$value"));

/// Reads [binding] at [path], or at the single [field] below its root.
skir.ExpressionNode inputExpression(
  skir.ExpressionBindingId binding, {
  String? field,
  skir.ValuePath? path,
}) {
  assert(field == null || path == null, "Supply either a field or a path.");
  return skir.ExpressionNode.createInput(
    binding: binding,
    path:
        path ?? (field == null ? editorRootPath : editorRootPath.field(field)),
  );
}

/// Reads the local in [slot] at lexical [depth].
skir.ExpressionNode localExpression(
  int slot, {
  int depth = 0,
  skir.ValuePath? path,
}) => skir.ExpressionNode.createLocal(
  depth: depth,
  slot: slot,
  path: path ?? editorRootPath,
);

/// Reads field [name] from [source].
skir.ExpressionNode fieldExpression(skir.ExpressionNode source, String name) =>
    skir.ExpressionNode.createField(
      source: source,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: name)],
      ),
    );

/// A presentation node with default properties and no header.
skir.PresentationNode presentationNode(
  String id,
  skir.PresentationElement element,
) =>
    (skir.PresentationNode.mutable()
          ..nodeId = id
          ..element = element)
        .toFrozen();

/// A column of fixed children.
skir.PresentationNode presentationColumn(
  String id,
  List<skir.PresentationNode> children, {
  skir.AxisChildrenLayout? layout,
}) => presentationNode(
  id,
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [for (final child in children) skir.AxisChild.wrapFixed(child)],
      layout: layout ?? skir.AxisChildrenLayout.defaultInstance,
    ),
  ),
);

/// A text element showing [value] with default styling.
skir.PresentationNode presentationText(String id, skir.ExpressionNode value) =>
    presentationNode(
      id,
      skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()..value = value).toFrozen(),
      ),
    );
