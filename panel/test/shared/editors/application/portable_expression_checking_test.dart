import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final catalog = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot.defaultInstance,
  );
  final candidate = skir.ExpressionBindingId(value: "candidate");
  final parent = skir.ExpressionBindingId(value: "parent");
  final text = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
  final decimal = skir.TypeUse.wrapScalar(skir.ScalarKind.decimal);
  final floating = skir.TypeUse.wrapScalar(
    skir.ScalarKind.createFloat(width: skir.FloatWidth.thirtyTwo),
  );
  skir.ExpressionType type(skir.TypeUse value, [bool missing = false]) =>
      skir.ExpressionType(
        value: skir.ExpressionValueType.wrapNominal(value),
        mayBeMissing: missing,
      );
  skir.ExpressionNode read(skir.ExpressionBindingId binding) =>
      skir.ExpressionNode.createInput(
        binding: binding,
        path: skir.ValuePath.defaultInstance,
      );
  skir.ExpressionNode literal(skir.DataValue value) =>
      skir.ExpressionNode.wrapLiteral(value);
  skir.ExpressionNode round(skir.ExpressionNode value, skir.DataValue step) =>
      skir.ExpressionNode.createNumberRound(
        source: value,
        increment: literal(step),
        rounding: literal(skir.DataValue.wrapStringValue("NearestTiesToEven")),
      );

  test("completion preserves candidate families and rejects mixing", () {
    expect(
      checkPortableExpression(
        round(read(candidate), skir.DataValue.wrapDecimal("0.01")),
        catalog: catalog,
        bindings: {candidate: type(decimal)},
        expectedOutput: type(decimal),
      ),
      isEmpty,
    );
    expect(
      checkPortableExpression(
        round(read(candidate), skir.DataValue.wrapFloat(0.5)),
        catalog: catalog,
        bindings: {candidate: type(floating)},
        expectedOutput: type(floating),
      ),
      isEmpty,
    );
    expect(
      checkPortableExpression(
        round(read(candidate), skir.DataValue.wrapDecimal("0.5")),
        catalog: catalog,
        bindings: {candidate: type(floating)},
        expectedOutput: type(floating),
      ),
      contains("numeric_family_mismatch"),
    );
  });
  test("completion cannot implicitly narrow a declared source width", () {
    final wide = skir.TypeUse.wrapScalar(
      skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
    );
    expect(
      checkPortableExpression(
        read(parent),
        catalog: catalog,
        bindings: {parent: type(wide)},
        expectedOutput: type(floating),
      ),
      contains("incompatible_expression_result_type"),
    );
    expect(
      checkPortableExpression(
        read(parent),
        catalog: catalog,
        bindings: {parent: type(wide)},
        expectedOutput: type(floating),
        allowResultNumericWidth: true,
      ),
      isEmpty,
    );
  });
  test("completion must handle unavailable parent values", () {
    final bindings = {candidate: type(text), parent: type(text, true)};
    expect(
      checkPortableExpression(
        read(parent),
        catalog: catalog,
        bindings: bindings,
        expectedOutput: type(text),
      ),
      contains("expression_result_may_be_missing"),
    );
    expect(
      checkPortableExpression(
        skir.ExpressionNode.createOrElse(
          input: read(parent),
          fallback: read(candidate),
        ),
        catalog: catalog,
        bindings: bindings,
        expectedOutput: type(text),
      ),
      isEmpty,
    );
  });
  test("local candidate cannot escape its declared mapping", () {
    expect(
      checkPortableExpression(
        read(candidate),
        catalog: catalog,
        bindings: const {},
        expectedOutput: type(text),
      ),
      contains("unknown_expression_binding"),
    );
  });
  test("unknown operation and missing operands fail admission", () {
    final unknown = skir.ExpressionNode.createTextUnary(
      operation: skir.TextUnaryOperation.unknown,
      source: literal(skir.DataValue.wrapStringValue("value")),
    );
    expect(
      checkPortableExpression(
        unknown,
        catalog: catalog,
        bindings: const {},
        expectedOutput: type(text),
      ),
      contains("unknown_expression_operation"),
    );
    final omittedOperand = skir.ExpressionNode.serializer.fromJson({
      "kind": "text_unary",
      "value": {"operation": "trim"},
    });
    expect(
      checkPortableExpression(
        omittedOperand,
        catalog: catalog,
        bindings: const {},
        expectedOutput: type(text),
      ),
      contains("unknown_expression"),
    );
  });
}
