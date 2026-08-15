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
}
