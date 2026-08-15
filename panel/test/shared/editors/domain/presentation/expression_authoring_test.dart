import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  test("composes the Iconify query operations", () {
    final query = "mdi:account".asStringLiteral;
    final remoteQuery = query
        .regexCapture(r"^(?:[^:]+:)?(.+)$", group: 1)
        .coalesce(query);
    final prefix = query.regexCapture(r"^([^:]+):(.+)$", group: 1);
    final gate = query.length().greaterThanOrEqual(2);
    final humanized = "account-box".asStringLiteral
        .regexReplace("-", " ")
        .titleCase();

    expect(
      remoteQuery.evaluate(context, registry: null).valueOrNull,
      const StringValue("account"),
    );
    expect(
      prefix.evaluate(context, registry: null).valueOrNull,
      const StringValue("mdi"),
    );
    expect(
      gate.evaluate(context, registry: null).valueOrNull,
      const BooleanValue(true),
    );
    expect(
      humanized.evaluate(context, registry: null).valueOrNull,
      const StringValue("Account Box"),
    );
  });

  test("authors literals and explicit result types", () {
    final integer = 64.asIntegerLiteral;
    final float = 280.asFloatLiteral;
    final nominal = "mdi:account".asStringLiteral.withResultType(
      NamedType(standardTypeRefs.iconifyIcon),
    );

    expect(integer.resultType, const IntegerType(width: IntegerWidth.signed64));
    expect(integer.expression, isA<LiteralExpression>());
    expect(float.resultType, const FloatType(width: FloatWidth.float64));
    expect(float.expression, isA<LiteralExpression>());
    expect(nominal.resultType, NamedType(standardTypeRefs.iconifyIcon));
  });

  test("authors string and collection operations", () {
    final joined = _strings(["a", "b"]).joinWith("|");
    final indexed = _strings([
      "a",
      "b",
    ]).access(1.asIntegerLiteral, resultType: const StringType());
    final contains = _strings(["a", "b"]).containsValue("b".asStringLiteral);

    expect(
      joined.evaluate(context, registry: null).valueOrNull,
      const StringValue("a|b"),
    );
    expect(
      indexed.evaluate(context, registry: null).valueOrNull,
      const StringValue("b"),
    );
    expect(
      contains.evaluate(context, registry: null).valueOrNull,
      const BooleanValue(true),
    );
  });
}

TypedExpression _strings(List<String> values) => TypedExpression(
  resultType: const ListType(element: StringType()),
  expression: LiteralExpression(
    ListValue(values.map(StringValue.new).toList()),
  ),
);
