import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "expression_evaluator.freezed.dart";
part "expression_advanced_evaluator.dart";
part "expression_collection_operations.dart";

@freezed
abstract class ExpressionContext with _$ExpressionContext {
  const factory ExpressionContext({
    required BindingEnvironment bindings,
    @Default({}) Map<ConversionId, ConversionDefinition> conversions,
  }) = _ExpressionContext;

  const ExpressionContext._();

  ExpressionContext withBinding(BindingId id, BindingSnapshot binding) =>
      ExpressionContext(
        bindings: BindingEnvironment({...bindings.bindings, id: binding}),
        conversions: conversions,
      );
}

extension TypedExpressionEvaluation on TypedExpression {
  TypeResult<DataValue> evaluate(
    ExpressionContext context, {
    required TypeRegistry? registry,
    ExpressionBudget budget = const ExpressionBudget(),
  }) {
    final evaluator = _ExpressionEvaluator(context, budget, registry);
    final result = evaluator.evaluate(this, 1);
    if (result case TypeFailure()) return result;
    final diagnostics = result.valueOrNull!.validateAgainst(
      resultType,
      registry: registry,
    );
    return diagnostics.isEmpty ? result : TypeResult.failure(diagnostics);
  }
}

final class _ExpressionEvaluator {
  _ExpressionEvaluator(this.context, this.budget, this.registry);

  final ExpressionContext context;
  final ExpressionBudget budget;
  final TypeRegistry? registry;
  int nodes = 0;
  int evaluations = 0;

  TypeResult<DataValue> evaluate(TypedExpression typed, int depth) {
    nodes++;
    evaluations++;
    final budgetFailure = _checkBudget(depth);
    if (budgetFailure != null) return budgetFailure;
    final result = _evaluate(typed.expression, depth);
    if (result case TypeFailure()) return result;
    final diagnostics = (result.valueOrNull!).validateAgainst(
      typed.resultType,
      registry: registry,
    );
    return diagnostics.isEmpty ? result : TypeResult.failure(diagnostics);
  }

  TypeResult<DataValue> _evaluate(Expression expression, int depth) =>
      switch (expression) {
        LiteralExpression(:final value) => TypeResult.success(value),
        BindingExpression(:final binding) => _binding(binding),
        FieldAccessExpression() => _field(expression, depth),
        InterpolationExpression() => _interpolate(expression, depth),
        ComparisonExpression() => _compare(expression, depth),
        BooleanExpression() => _boolean(expression, depth),
        ArithmeticExpression() => _arithmetic(expression, depth),
        ConditionalExpression() => _conditional(expression, depth),
        CollectionProjectionExpression() => _project(expression, depth),
        ConversionExpression() => _convert(expression, depth),
        StringOperationExpression() => _stringOperation(expression, depth),
        CollectionOperationExpression() => _collectionOperation(
          expression,
          depth,
        ),
        RegexExpression() => _regex(expression, depth),
        CoalesceExpression() => _coalesce(expression, depth),
      };

  TypeResult<DataValue> _binding(BindingReference reference) {
    final binding = context.bindings.resolve(reference);
    if (binding case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return TypeResult.success(binding.valueOrNull!.value);
  }

  TypeResult<DataValue> _field(FieldAccessExpression expression, int depth) {
    final target = evaluate(expression.target, depth + 1);
    if (target case TypeFailure()) return target;
    final value = target.valueOrNull!;
    if (value is! RecordValue) {
      return _failure("Field access requires a record");
    }
    final field = value.fields[expression.fieldName];
    return field == null
        ? _failure("Field '${expression.fieldName}' is absent")
        : TypeResult.success(field);
  }

  TypeResult<DataValue> _interpolate(
    InterpolationExpression expression,
    int depth,
  ) {
    final output = StringBuffer();
    for (final part in expression.parts) {
      if (part is InterpolationText) {
        output.write(part.value);
        continue;
      }
      final value = evaluate((part as InterpolationValue).value, depth + 1);
      if (value case TypeFailure()) return value;
      output.write((value.valueOrNull!).expressionDisplayText);
    }
    return TypeResult.success(StringValue(output.toString()));
  }

  TypeResult<DataValue> _compare(ComparisonExpression expression, int depth) {
    final left = evaluate(expression.left, depth + 1);
    final right = evaluate(expression.right, depth + 1);
    if (left case TypeFailure()) return left;
    if (right case TypeFailure()) return right;
    final leftValue = left.valueOrNull!;
    final rightValue = right.valueOrNull!;
    if (expression.operator == ComparisonOperator.equal) {
      return TypeResult.success(BooleanValue(leftValue == rightValue));
    }
    if (expression.operator == ComparisonOperator.notEqual) {
      return TypeResult.success(BooleanValue(leftValue != rightValue));
    }
    final comparison = compareExpressionValues(leftValue, rightValue);
    if (comparison == null) return _failure("Values are not comparable");
    return TypeResult.success(
      BooleanValue(switch (expression.operator) {
        ComparisonOperator.lessThan => comparison < 0,
        ComparisonOperator.lessThanOrEqual => comparison <= 0,
        ComparisonOperator.greaterThan => comparison > 0,
        ComparisonOperator.greaterThanOrEqual => comparison >= 0,
        _ => false,
      }),
    );
  }

  TypeResult<DataValue> _boolean(BooleanExpression expression, int depth) {
    if (expression.operands.isEmpty) {
      return _failure("Boolean operands are empty");
    }
    if (expression.operator == BooleanOperator.not &&
        expression.operands.length != 1) {
      return _failure("Boolean not requires one operand");
    }
    final values = <bool>[];
    for (final operand in expression.operands) {
      final result = evaluate(operand, depth + 1);
      if (result case TypeFailure()) return result;
      final value = result.valueOrNull!;
      if (value is! BooleanValue) return _failure("Boolean operand is invalid");
      values.add(value.value);
    }
    return TypeResult.success(
      BooleanValue(switch (expression.operator) {
        BooleanOperator.and => values.every((value) => value),
        BooleanOperator.or => values.any((value) => value),
        BooleanOperator.not => !values.single,
      }),
    );
  }

  TypeResult<DataValue> _arithmetic(
    ArithmeticExpression expression,
    int depth,
  ) {
    final values = <DataValue>[];
    for (final operand in expression.operands) {
      final result = evaluate(operand, depth + 1);
      if (result case TypeFailure()) return result;
      values.add(result.valueOrNull!);
    }
    if (values.every((value) => value is IntegerValue)) {
      return expression.operator.evaluateIntegers(values.cast());
    }
    if (values.every((value) => value is FloatValue)) {
      return expression.operator.evaluateFloats(values.cast());
    }
    return _failure("Arithmetic operands must share a numeric type");
  }

  TypeResult<DataValue> _conditional(
    ConditionalExpression expression,
    int depth,
  ) {
    final condition = evaluate(expression.condition, depth + 1);
    if (condition case TypeFailure()) return condition;
    final value = condition.valueOrNull!;
    if (value is! BooleanValue) return _failure("Condition must be boolean");
    return evaluate(
      value.value ? expression.whenTrue : expression.whenFalse,
      depth + 1,
    );
  }

  TypeResult<DataValue> _project(
    CollectionProjectionExpression expression,
    int depth,
  ) {
    final source = evaluate(expression.source, depth + 1);
    if (source case TypeFailure()) return source;
    final value = source.valueOrNull!;
    final items = switch (value) {
      ListValue(:final values) => values,
      MapValue(:final entries) => entries.map((entry) => entry.value).toList(),
      _ => null,
    };
    if (items == null) {
      return _failure("Projection source must be a collection");
    }
    final itemType = switch (expression.source.resultType) {
      ListType(:final element) => element,
      MapType(value: final valueType) => valueType,
      _ => null,
    };
    if (itemType == null) {
      return _failure("Projection source type must be a collection");
    }
    final projected = <DataValue>[];
    for (final item in items) {
      final remainingNodes = budget.maximumNodes - nodes;
      final remainingEvaluations = budget.maximumEvaluations - evaluations;
      if (remainingNodes <= 0 || remainingEvaluations <= 0) {
        return _failure("Expression evaluation budget exceeded");
      }
      final child = _ExpressionEvaluator(
        context.withBinding(
          expression.itemBindingId,
          BindingSnapshot(
            type: itemType,
            value: item,
            revision: 0,
            writable: false,
          ),
        ),
        ExpressionBudget(
          maximumDepth: budget.maximumDepth,
          maximumNodes: remainingNodes,
          maximumEvaluations: remainingEvaluations,
        ),
        registry,
      );
      final result = child.evaluate(expression.projection, depth + 1);
      nodes += child.nodes;
      evaluations += child.evaluations;
      if (result case TypeFailure()) return result;
      projected.add(result.valueOrNull!);
    }
    return TypeResult.success(ListValue(projected));
  }

  TypeResult<DataValue> _convert(ConversionExpression expression, int depth) {
    final input = evaluate(expression.input, depth + 1);
    if (input case TypeFailure()) return input;
    final conversion = context.conversions[expression.conversionId];
    if (conversion == null) return _failure("Conversion is not available");
    if (conversion.locality == ConversionLocality.realm) {
      return _failure("Realm conversion cannot execute locally");
    }
    return switch (conversion.rule.evaluate(input.valueOrNull!)) {
      ConversionSuccess(:final value) => TypeResult.success(value),
      ConversionFailure(:final diagnostics) => TypeResult.failure(diagnostics),
      ConversionUnavailable(:final diagnostics) => TypeResult.failure(
        diagnostics,
      ),
    };
  }

  TypeFailure<DataValue>? _checkBudget(int depth) {
    if (depth > budget.maximumDepth) {
      return _failure("Expression depth budget exceeded");
    }
    if (nodes > budget.maximumNodes) {
      return _failure("Expression node budget exceeded");
    }
    if (evaluations > budget.maximumEvaluations) {
      return _failure("Expression evaluation budget exceeded");
    }
    return null;
  }
}

TypeFailure<DataValue> _failure(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
]);
