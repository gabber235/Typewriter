import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirExpressionEncoder {
  SkirExpressionEncoder(this.types, this.values)
    : paths = SkirDataPathCodec(values);

  final SkirTypeCodec types;
  final SkirDataValueCodec values;
  final SkirDataPathCodec paths;

  TypeResult<wire.TypedExpression> encode(TypedExpression value) {
    final type = types.encodeExpression(value.resultType);
    final expression = _expression(value.expression);
    return combineResults(
      type,
      expression,
      (type, expression) =>
          wire.TypedExpression(resultType: type, expression: expression),
    );
  }

  TypeResult<wire_binding.BindingRef> binding(BindingReference value) => paths
      .encode(value.path)
      .mapValue(
        (path) => wire_binding.BindingRef(
          bindingId: wire_binding.BindingId(value: value.bindingId.value),
          path: path,
        ),
      );

  TypeResult<wire.Expression> _expression(Expression value) => switch (value) {
    LiteralExpression(:final value) =>
      values.encode(value).mapValue(wire.Expression.wrapLiteral),
    BindingExpression(:final binding) =>
      this.binding(binding).mapValue(wire.Expression.wrapBinding),
    FieldAccessExpression(:final target, :final fieldName) =>
      encode(target).mapValue(
        (target) => wire.Expression.createFieldAccess(
          target: target,
          fieldName: fieldName,
        ),
      ),
    InterpolationExpression(:final parts) => _interpolation(parts),
    ComparisonExpression(:final operator, :final left, :final right) =>
      combineResults(
        encode(left),
        encode(right),
        (left, right) => wire.Expression.createComparison(
          operator_: operator._encodeWire,
          left: left,
          right: right,
        ),
      ),
    BooleanExpression(:final operator, :final operands) =>
      _operands(operands).mapValue(
        (operands) => wire.Expression.createBooleanOperation(
          operator_: operator._encodeWire,
          operands: operands,
        ),
      ),
    ArithmeticExpression(:final operator, :final operands) =>
      _operands(operands).mapValue(
        (operands) => wire.Expression.createArithmetic(
          operator_: operator._encodeWire,
          operands: operands,
        ),
      ),
    ConditionalExpression(
      :final condition,
      :final whenTrue,
      :final whenFalse,
    ) =>
      _conditional(condition, whenTrue, whenFalse),
    CollectionProjectionExpression(
      :final source,
      :final itemBindingId,
      :final projection,
    ) =>
      combineResults(
        encode(source),
        encode(projection),
        (source, projection) => wire.Expression.createCollectionProjection(
          source: source,
          itemBindingId: wire_binding.BindingId(value: itemBindingId.value),
          projection: projection,
        ),
      ),
    ConversionExpression(:final conversionId, :final input) =>
      conversionId.encodeWire().mapValue(
        (id) => wire.Expression.createConversion(
          conversionId: id,
          input: encode(input).valueOrNull!,
        ),
      ),
  };

  TypeResult<wire.Expression> _interpolation(List<InterpolationPart> parts) {
    final values = <wire.InterpolationPart>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final part in parts) {
      switch (part) {
        case InterpolationText(:final value):
          values.add(wire.InterpolationPart.wrapText(value));
        case InterpolationValue(:final value):
          final encoded = encode(value);
          diagnostics.addAll(encoded.diagnostics);
          if (encoded.valueOrNull case final item?) {
            values.add(wire.InterpolationPart.wrapExpression(item));
          }
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(wire.Expression.createInterpolation(parts: values))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<List<wire.TypedExpression>> _operands(
    List<TypedExpression> values,
  ) {
    final items = <wire.TypedExpression>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final encoded = encode(value);
      diagnostics.addAll(encoded.diagnostics);
      if (encoded.valueOrNull case final item?) items.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(items)
        : TypeResult.failure(diagnostics);
  }

  TypeResult<wire.Expression> _conditional(
    TypedExpression condition,
    TypedExpression whenTrue,
    TypedExpression whenFalse,
  ) {
    final encodedCondition = encode(condition);
    final encodedTrue = encode(whenTrue);
    final encodedFalse = encode(whenFalse);
    final diagnostics = [
      ...encodedCondition.diagnostics,
      ...encodedTrue.diagnostics,
      ...encodedFalse.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            wire.Expression.createConditional(
              condition: encodedCondition.valueOrNull!,
              whenTrue: encodedTrue.valueOrNull!,
              whenFalse: encodedFalse.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }
}

extension on ComparisonOperator {
  wire.ComparisonOperator get _encodeWire => switch (this) {
    ComparisonOperator.equal => wire.ComparisonOperator.equal,
    ComparisonOperator.notEqual => wire.ComparisonOperator.notEqual,
    ComparisonOperator.lessThan => wire.ComparisonOperator.lessThan,
    ComparisonOperator.lessThanOrEqual =>
      wire.ComparisonOperator.lessThanOrEqual,
    ComparisonOperator.greaterThan => wire.ComparisonOperator.greaterThan,
    ComparisonOperator.greaterThanOrEqual =>
      wire.ComparisonOperator.greaterThanOrEqual,
  };
}

extension on BooleanOperator {
  wire.BooleanOperator get _encodeWire => switch (this) {
    BooleanOperator.and => wire.BooleanOperator.and,
    BooleanOperator.or => wire.BooleanOperator.or,
    BooleanOperator.not => wire.BooleanOperator.not,
  };
}

extension on ArithmeticOperator {
  wire.ArithmeticOperator get _encodeWire => switch (this) {
    ArithmeticOperator.add => wire.ArithmeticOperator.add,
    ArithmeticOperator.subtract => wire.ArithmeticOperator.subtract,
    ArithmeticOperator.multiply => wire.ArithmeticOperator.multiply,
    ArithmeticOperator.divide => wire.ArithmeticOperator.divide,
    ArithmeticOperator.remainder => wire.ArithmeticOperator.remainder,
    ArithmeticOperator.negate => wire.ArithmeticOperator.negate,
  };
}
