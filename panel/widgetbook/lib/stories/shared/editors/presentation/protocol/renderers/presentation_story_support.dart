import "dart:typed_data";

import "package:typewriter_panel/typewriter_panel.dart";

const rootBinding = BindingReference(bindingId: BindingId(0));

PresentationNode storyNode(
  String id,
  PresentationElement element, {
  PresentationHeader? header,
  PresentationProperties properties = const PresentationProperties(),
}) => PresentationNode(
  id: id,
  element: element,
  header: header,
  properties: properties,
);

BoundControl storyControl(String label) => BoundControl(
  binding: rootBinding,
  label: label.asStringLiteral,
  description: "Adjust this value to inspect its renderer.".asStringLiteral,
);

TypedExpression literal(TypeExpression type, DataValue value) =>
    TypedExpression(resultType: type, expression: LiteralExpression(value));

TypedExpression bindingExpression(
  BindingReference binding,
  TypeExpression type,
) => TypedExpression(resultType: type, expression: BindingExpression(binding));

TypedExpression integerLiteral(int value) => literal(
  const IntegerType(width: IntegerWidth.signed64),
  IntegerValue(BigInt.from(value)),
);

TypedExpression floatLiteral(double value) =>
    literal(const FloatType(width: FloatWidth.float64), FloatValue(value));

TypedExpression svgIconLiteral(String value) =>
    literal(NamedType(standardTypeRefs.icon), IconValue.svg(value).typedValue);

EditorAction setRootValue(TypeExpression type, DataValue value) =>
    LocalEditorAction(
      SetValueAction(target: rootBinding, value: literal(type, value)),
    );

final storyBytes = BytesValue(Uint8List.fromList([84, 121, 112, 101]));

ResolvedTypeRef storyTypeRef(String name) => ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "widgetbook", name: name),
  revision: 1,
);
