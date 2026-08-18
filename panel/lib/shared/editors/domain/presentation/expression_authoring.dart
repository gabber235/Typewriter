import "package:typewriter_panel/typewriter_panel.dart";

extension TypedExpressionAuthoring on TypedExpression {
  TypedExpression withResultType(TypeExpression type) =>
      TypedExpression(resultType: type, expression: expression);

  TypedExpression isType(TypeExpression type) => TypedExpression(
    resultType: const BooleanType(),
    expression: IsTypeExpression(source: this, type: type),
  );

  TypedExpression compare(ComparisonOperator operator, TypedExpression other) =>
      TypedExpression(
        resultType: const BooleanType(),
        expression: ComparisonExpression(
          operator: operator,
          left: this,
          right: other,
        ),
      );

  TypedExpression greaterThanOrEqual(int other) =>
      compare(ComparisonOperator.greaterThanOrEqual, other.asIntegerLiteral);

  TypedExpression trim() => _string(StringOperation.trim, [this]);

  TypedExpression lowerCase() => _string(StringOperation.lowerCase, [this]);

  TypedExpression upperCase() => _string(StringOperation.upperCase, [this]);

  TypedExpression titleCase() => _string(StringOperation.titleCase, [this]);

  TypedExpression replaceLiteral(String source, String replacement) => _string(
    StringOperation.replace,
    [this, source.asStringLiteral, replacement.asStringLiteral],
  );

  TypedExpression splitLiteral(String separator) => TypedExpression(
    resultType: const ListType(element: StringType()),
    expression: StringOperationExpression(
      operation: StringOperation.split,
      operands: [this, separator.asStringLiteral],
    ),
  );

  TypedExpression joinWith(String separator) =>
      _string(StringOperation.join, [this, separator.asStringLiteral]);

  TypedExpression substring(int start, [int? end]) => _string(
    StringOperation.substring,
    [this, start.asIntegerLiteral, if (end != null) end.asIntegerLiteral],
  );

  TypedExpression containsText(String value) =>
      _booleanString(StringOperation.contains, value);

  TypedExpression startsWithText(String value) =>
      _booleanString(StringOperation.startsWith, value);

  TypedExpression endsWithText(String value) =>
      _booleanString(StringOperation.endsWith, value);

  TypedExpression access(
    TypedExpression key, {
    required TypeExpression resultType,
  }) => TypedExpression(
    resultType: resultType,
    expression: CollectionOperationExpression(
      operation: CollectionOperation.access,
      operands: [this, key],
    ),
  );

  TypedExpression length() => TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: CollectionOperationExpression(
      operation: CollectionOperation.length,
      operands: [this],
    ),
  );

  TypedExpression containsValue(TypedExpression value) => TypedExpression(
    resultType: const BooleanType(),
    expression: CollectionOperationExpression(
      operation: CollectionOperation.contains,
      operands: [this, value],
    ),
  );

  TypedExpression regexMatches(String pattern) => TypedExpression(
    resultType: const BooleanType(),
    expression: RegexExpression(
      operation: RegexOperation.matches,
      source: this,
      pattern: pattern,
    ),
  );

  TypedExpression regexCapture(String pattern, {int group = 0}) =>
      _regex(RegexOperation.capture, pattern, group: group);

  TypedExpression regexReplace(String pattern, String replacement) =>
      _regex(RegexOperation.replace, pattern, replacement: replacement);

  TypedExpression coalesce(TypedExpression fallback) => TypedExpression(
    resultType: resultType,
    expression: CoalesceExpression([this, fallback]),
  );

  TypedExpression withAlpha(int alpha) => TypedExpression(
    resultType: NamedType(standardTypeRefs.color),
    expression: ColorOperationExpression(
      operation: ColorOperation.withAlpha,
      color: this,
      alpha: alpha.asIntegerLiteral,
    ),
  );

  TypedExpression _string(
    StringOperation operation,
    List<TypedExpression> operands,
  ) => TypedExpression(
    resultType: const StringType(),
    expression: StringOperationExpression(
      operation: operation,
      operands: operands,
    ),
  );

  TypedExpression _booleanString(StringOperation operation, String value) =>
      TypedExpression(
        resultType: const BooleanType(),
        expression: StringOperationExpression(
          operation: operation,
          operands: [this, value.asStringLiteral],
        ),
      );

  TypedExpression _regex(
    RegexOperation operation,
    String pattern, {
    int? group,
    String? replacement,
  }) => TypedExpression(
    resultType: const StringType(),
    expression: RegexExpression(
      operation: operation,
      source: this,
      pattern: pattern,
      group: group,
      replacement: replacement,
    ),
  );
}
