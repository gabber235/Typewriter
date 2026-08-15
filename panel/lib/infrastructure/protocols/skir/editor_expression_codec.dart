import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as wire_type;
import "package:typewriter_panel/typewriter_panel.dart";

final class SkirExpressionDecoder {
  SkirExpressionDecoder(this.typeCodec, this.valueCodec)
    : pathCodec = SkirDataPathCodec(valueCodec);

  final SkirTypeCodec typeCodec;
  final SkirDataValueCodec valueCodec;
  final SkirDataPathCodec pathCodec;

  TypeResult<TypedExpression> decode(wire.TypedExpression value) {
    final type = typeCodec.decodeExpression(value.resultType);
    final expression = value.expression == null
        ? invalidWire<Expression>("Typed expression payload is missing")
        : _expression(value.expression!);
    return combineResults(type, expression, (type, expression) {
      return TypedExpression(resultType: type, expression: expression);
    });
  }

  TypeResult<BindingReference> binding(wire_binding.BindingRef value) {
    final path = pathCodec.decode(value.path);
    return path.mapValue(
      (path) => BindingReference(
        bindingId: BindingId(value.bindingId.value),
        path: path,
      ),
    );
  }

  TypeResult<Expression> _expression(wire.Expression value) => switch (value) {
    wire.Expression_literalWrapper(:final value) =>
      valueCodec.decode(value).mapValue(LiteralExpression.new),
    wire.Expression_bindingWrapper(:final value) => binding(
      value,
    ).mapValue(BindingExpression.new),
    wire.Expression_fieldAccessWrapper(:final value) => combineResults(
      decode(value.target),
      value.fieldName.isEmpty
          ? invalidWire<String>("Field name is empty")
          : TypeResult.success(value.fieldName),
      (target, name) => FieldAccessExpression(target: target, fieldName: name),
    ),
    wire.Expression_interpolationWrapper(:final value) => _interpolation(
      value.parts,
    ),
    wire.Expression_comparisonWrapper(:final value) => _comparison(value),
    wire.Expression_booleanOperationWrapper(:final value) => _boolean(value),
    wire.Expression_arithmeticWrapper(:final value) => _arithmetic(value),
    wire.Expression_conditionalWrapper(:final value) => _conditional(value),
    wire.Expression_collectionProjectionWrapper(:final value) => _projection(
      value,
    ),
    wire.Expression_conversionWrapper(:final value) =>
      value.conversionId._decodeDomain == null
          ? invalidWire("Conversion id is empty")
          : decode(value.input).mapValue(
              (input) => ConversionExpression(
                conversionId: value.conversionId._decodeDomain!,
                input: input,
              ),
            ),
    wire.Expression_stringOperationWrapper(:final value) => _string(value),
    wire.Expression_collectionOperationWrapper(:final value) => _collection(
      value,
    ),
    wire.Expression_regexWrapper(:final value) => _regex(value),
    wire.Expression_coalesceWrapper(:final value) => _operands(
      value.operands,
      CoalesceExpression.new,
    ),
    wire.Expression_unknown() => invalidWire("Unknown expression variant"),
  };

  TypeResult<Expression> _interpolation(
    Iterable<wire.InterpolationPart> parts,
  ) {
    final decoded = <InterpolationPart>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final part in parts) {
      switch (part) {
        case wire.InterpolationPart_textWrapper(:final value):
          decoded.add(InterpolationText(value));
        case wire.InterpolationPart_expressionWrapper(:final value):
          final result = decode(value);
          diagnostics.addAll(result.diagnostics);
          if (result.valueOrNull case final item?) {
            decoded.add(InterpolationValue(item));
          }
        case wire.InterpolationPart_unknown():
          diagnostics.add(wireDiagnostic("Unknown interpolation part"));
      }
    }
    return diagnostics.isEmpty
        ? TypeResult.success(InterpolationExpression(decoded))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<Expression> _comparison(wire.ComparisonExpression value) {
    final operator = switch (value.operator_) {
      wire.ComparisonOperator.equal => ComparisonOperator.equal,
      wire.ComparisonOperator.notEqual => ComparisonOperator.notEqual,
      wire.ComparisonOperator.lessThan => ComparisonOperator.lessThan,
      wire.ComparisonOperator.lessThanOrEqual =>
        ComparisonOperator.lessThanOrEqual,
      wire.ComparisonOperator.greaterThan => ComparisonOperator.greaterThan,
      wire.ComparisonOperator.greaterThanOrEqual =>
        ComparisonOperator.greaterThanOrEqual,
      _ => null,
    };
    if (operator == null) return invalidWire("Unknown comparison operator");
    return combineResults(
      decode(value.left),
      decode(value.right),
      (left, right) =>
          ComparisonExpression(operator: operator, left: left, right: right),
    );
  }

  TypeResult<Expression> _boolean(wire.BooleanExpression value) {
    final operator = switch (value.operator_) {
      wire.BooleanOperator.and => BooleanOperator.and,
      wire.BooleanOperator.or => BooleanOperator.or,
      wire.BooleanOperator.not => BooleanOperator.not,
      _ => null,
    };
    return _operands(
      value.operands,
      operator == null
          ? null
          : (items) => BooleanExpression(operator: operator, operands: items),
    );
  }

  TypeResult<Expression> _arithmetic(wire.ArithmeticExpression value) {
    final operator = switch (value.operator_) {
      wire.ArithmeticOperator.add => ArithmeticOperator.add,
      wire.ArithmeticOperator.subtract => ArithmeticOperator.subtract,
      wire.ArithmeticOperator.multiply => ArithmeticOperator.multiply,
      wire.ArithmeticOperator.divide => ArithmeticOperator.divide,
      wire.ArithmeticOperator.remainder => ArithmeticOperator.remainder,
      wire.ArithmeticOperator.negate => ArithmeticOperator.negate,
      _ => null,
    };
    return _operands(
      value.operands,
      operator == null
          ? null
          : (items) =>
                ArithmeticExpression(operator: operator, operands: items),
    );
  }

  TypeResult<Expression> _string(wire.StringOperationExpression value) {
    final operation = switch (value.operation) {
      wire.StringOperation.trim => StringOperation.trim,
      wire.StringOperation.lowerCase => StringOperation.lowerCase,
      wire.StringOperation.upperCase => StringOperation.upperCase,
      wire.StringOperation.titleCase => StringOperation.titleCase,
      wire.StringOperation.replace => StringOperation.replace,
      wire.StringOperation.split => StringOperation.split,
      wire.StringOperation.join => StringOperation.join,
      wire.StringOperation.substring => StringOperation.substring,
      wire.StringOperation.contains => StringOperation.contains,
      wire.StringOperation.startsWith => StringOperation.startsWith,
      wire.StringOperation.endsWith => StringOperation.endsWith,
      _ => null,
    };
    return _operands(
      value.operands,
      operation == null
          ? null
          : (operands) => StringOperationExpression(
              operation: operation,
              operands: operands,
            ),
    );
  }

  TypeResult<Expression> _collection(wire.CollectionOperationExpression value) {
    final operation = switch (value.operation) {
      wire.CollectionOperation.access => CollectionOperation.access,
      wire.CollectionOperation.length => CollectionOperation.length,
      wire.CollectionOperation.contains => CollectionOperation.contains,
      _ => null,
    };
    return _operands(
      value.operands,
      operation == null
          ? null
          : (operands) => CollectionOperationExpression(
              operation: operation,
              operands: operands,
            ),
    );
  }

  TypeResult<Expression> _regex(wire.RegexExpression value) {
    final operation = switch (value.operation) {
      wire.RegexOperation.matches => RegexOperation.matches,
      wire.RegexOperation.capture => RegexOperation.capture,
      wire.RegexOperation.replace => RegexOperation.replace,
      _ => null,
    };
    if (operation == null) return invalidWire("Unknown regex operation");
    if (value.group case final group? when group < 0) {
      return invalidWire("Regex capture group is negative");
    }
    return decode(value.source).mapValue(
      (source) => RegexExpression(
        operation: operation,
        source: source,
        pattern: value.pattern,
        group: value.group,
        replacement: value.replacement,
      ),
    );
  }

  TypeResult<Expression> _operands(
    Iterable<wire.TypedExpression> values,
    Expression Function(List<TypedExpression>)? create,
  ) {
    if (create == null) return invalidWire("Unknown expression operator");
    final items = <TypedExpression>[];
    final diagnostics = <TypeDiagnostic>[];
    for (final value in values) {
      final result = decode(value);
      diagnostics.addAll(result.diagnostics);
      if (result.valueOrNull case final item?) items.add(item);
    }
    return diagnostics.isEmpty
        ? TypeResult.success(create(items))
        : TypeResult.failure(diagnostics);
  }

  TypeResult<Expression> _conditional(wire.ConditionalExpression value) {
    final condition = decode(value.condition);
    final whenTrue = decode(value.whenTrue);
    final whenFalse = decode(value.whenFalse);
    final diagnostics = [
      ...condition.diagnostics,
      ...whenTrue.diagnostics,
      ...whenFalse.diagnostics,
    ];
    return diagnostics.isEmpty
        ? TypeResult.success(
            ConditionalExpression(
              condition: condition.valueOrNull!,
              whenTrue: whenTrue.valueOrNull!,
              whenFalse: whenFalse.valueOrNull!,
            ),
          )
        : TypeResult.failure(diagnostics);
  }

  TypeResult<Expression> _projection(
    wire.CollectionProjectionExpression value,
  ) {
    return combineResults(
      decode(value.source),
      decode(value.projection),
      (source, projection) => CollectionProjectionExpression(
        source: source,
        itemBindingId: BindingId(value.itemBindingId.value),
        projection: projection,
      ),
    );
  }
}

extension on wire_type.ConversionId {
  ConversionId? get _decodeDomain => namespace.isEmpty || name.isEmpty
      ? null
      : ConversionId(namespace: namespace, name: name);
}
