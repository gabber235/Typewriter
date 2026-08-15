import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  const context = ExpressionContext(bindings: BindingEnvironment({}));

  test("matches, captures, replaces, and falls back", () {
    final matches = _regex(
      const BooleanType(),
      RegexOperation.matches,
      "mdi:account".asStringLiteral,
      "^mdi:",
    );
    final capture = _regex(
      const StringType(),
      RegexOperation.capture,
      "mdi:account".asStringLiteral,
      r"^([^:]+):(.+)$",
      group: 2,
    );
    final replace = _regex(
      const StringType(),
      RegexOperation.replace,
      "mdi:account".asStringLiteral,
      "^mdi:",
      replacement: "",
    );
    final fallback = _typed(
      const StringType(),
      CoalesceExpression([
        _regex(
          const StringType(),
          RegexOperation.capture,
          "account".asStringLiteral,
          r"^mdi:(.+)$",
          group: 1,
        ),
        "account".asStringLiteral,
      ]),
    );

    expect(
      matches.evaluate(context, registry: null).valueOrNull,
      const BooleanValue(true),
    );
    expect(
      capture.evaluate(context, registry: null).valueOrNull,
      const StringValue("account"),
    );
    expect(
      replace.evaluate(context, registry: null).valueOrNull,
      const StringValue("account"),
    );
    expect(
      fallback.evaluate(context, registry: null).valueOrNull,
      const StringValue("account"),
    );
  });

  test("bounds patterns, inputs, groups, and evaluation", () {
    final invalidPattern = _regex(
      const BooleanType(),
      RegexOperation.matches,
      "value".asStringLiteral,
      "(",
    );
    final longPattern = _regex(
      const BooleanType(),
      RegexOperation.matches,
      "value".asStringLiteral,
      "a" * 513,
    );
    final longInput = _regex(
      const BooleanType(),
      RegexOperation.matches,
      ("a" * 16385).asStringLiteral,
      "a",
    );
    final invalidGroup = _regex(
      const StringType(),
      RegexOperation.capture,
      "value".asStringLiteral,
      "(value)",
      group: 33,
    );
    final budgetedFallback = _typed(
      const StringType(),
      CoalesceExpression([
        _regex(
          const StringType(),
          RegexOperation.capture,
          "value".asStringLiteral,
          "missing",
        ),
        "fallback".asStringLiteral,
      ]),
    );

    expect(
      invalidPattern.evaluate(context, registry: null),
      isA<TypeFailure>(),
    );
    expect(longPattern.evaluate(context, registry: null), isA<TypeFailure>());
    expect(longInput.evaluate(context, registry: null), isA<TypeFailure>());
    expect(invalidGroup.evaluate(context, registry: null), isA<TypeFailure>());
    expect(
      budgetedFallback.evaluate(
        context,
        registry: null,
        budget: const ExpressionBudget(maximumEvaluations: 2),
      ),
      isA<TypeFailure>(),
    );
  });
}

TypedExpression _typed(TypeExpression type, Expression expression) =>
    TypedExpression(resultType: type, expression: expression);

TypedExpression _regex(
  TypeExpression type,
  RegexOperation operation,
  TypedExpression source,
  String pattern, {
  int? group,
  String? replacement,
}) => _typed(
  type,
  RegexExpression(
    operation: operation,
    source: source,
    pattern: pattern,
    group: group,
    replacement: replacement,
  ),
);
