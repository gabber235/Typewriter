import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final registry = TypeRegistry(const TypeCatalog([]));
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  test("color operation replaces the alpha channel", () {
    final expression = TypedExpression(
      resultType: NamedType(standardTypeRefs.color),
      expression: ColorOperationExpression(
        operation: ColorOperation.withAlpha,
        color: IntegerValue(
          BigInt.from(0xFF336699),
        ).asLiteral(NamedType(standardTypeRefs.color)),
        alpha: 46.asIntegerLiteral,
      ),
    );

    final result = expression.evaluate(context, registry: registry);

    expect(result.diagnostics, isEmpty);
    expect(
      (result.valueOrNull! as IntegerValue).value,
      BigInt.from(0x2E336699),
    );
  });

  test("color operation rejects an invalid alpha channel", () {
    final expression = TypedExpression(
      resultType: NamedType(standardTypeRefs.color),
      expression: ColorOperationExpression(
        operation: ColorOperation.withAlpha,
        color: IntegerValue(
          BigInt.from(0xFF336699),
        ).asLiteral(NamedType(standardTypeRefs.color)),
        alpha: 256.asIntegerLiteral,
      ),
    );

    final result = expression.evaluate(context, registry: registry);

    expect(result.valueOrNull, isNull);
    expect(result.diagnostics.single.message, contains("between 0 and 255"));
  });
}
