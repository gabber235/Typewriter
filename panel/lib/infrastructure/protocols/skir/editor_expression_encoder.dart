import "package:typewriter_panel/infrastructure/protocols/skir/editor_codec_support.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as wire_binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as wire;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_expression_encoder_operations.dart";

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
    CollectionMapExpression(
      :final source,
      :final itemBindingId,
      :final transform,
    ) =>
      combineResults(
        encode(source),
        encode(transform),
        (source, transform) => wire.Expression.createCollectionMap(
          source: source,
          itemBindingId: wire_binding.BindingId(value: itemBindingId.value),
          transform: transform,
        ),
      ),
    CollectionFilterExpression() => _filter(value),
    CollectionQuantifierExpression() => _quantifier(value),
    CollectionFindExpression() => _find(value),
    CollectionCountExpression() => _count(value),
    CollectionDistinctExpression() => _distinct(value),
    CollectionSortExpression() => _sort(value),
    CollectionGroupExpression() => _group(value),
    CollectionReduceExpression() => _reduce(value),
    CollectionFoldExpression() => _fold(value),
    CollectionTransformExpression() => _transform(value),
    IsTypeExpression(:final source, :final type) => combineResults(
      encode(source),
      types.encodeExpression(type),
      (source, type) =>
          wire.Expression.createIsType(source: source, type: type),
    ),
    ConversionExpression(:final conversionId, :final input) =>
      conversionId.encodeWire().mapValue(
        (id) => wire.Expression.createConversion(
          conversionId: id,
          input: encode(input).valueOrNull!,
        ),
      ),
    StringOperationExpression(:final operation, :final operands) =>
      _operands(operands).mapValue(
        (operands) => wire.Expression.createStringOperation(
          operation: operation._encodeWire,
          operands: operands,
        ),
      ),
    CollectionOperationExpression(:final operation, :final operands) =>
      _operands(operands).mapValue(
        (operands) => wire.Expression.createCollectionOperation(
          operation: operation._encodeWire,
          operands: operands,
        ),
      ),
    RegexExpression(
      :final operation,
      :final source,
      :final pattern,
      :final group,
      :final replacement,
    ) =>
      encode(source).mapValue(
        (source) => wire.Expression.createRegex(
          operation: operation._encodeWire,
          source: source,
          pattern: pattern,
          group: group,
          replacement: replacement,
        ),
      ),
    CoalesceExpression(:final operands) => _operands(operands).mapValue(
      (operands) => wire.Expression.createCoalesce(operands: operands),
    ),
    ColorOperationExpression(:final operation, :final color, :final alpha) =>
      combineResults(
        encode(color),
        encode(alpha),
        (color, alpha) => wire.Expression.createColorOperation(
          operation: switch (operation) {
            ColorOperation.withAlpha => wire.ColorOperation.withAlpha,
          },
          color: color,
          alpha: alpha,
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

  TypeResult<wire.Expression> _filter(CollectionFilterExpression value) =>
      combineResults(
        encode(value.source),
        encode(value.predicate),
        (source, predicate) => wire.Expression.createCollectionFilter(
          source: source,
          predicate: predicate,
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
        ),
      );

  TypeResult<wire.Expression> _quantifier(
    CollectionQuantifierExpression value,
  ) => combineResults(
    encode(value.source),
    encode(value.predicate),
    (source, predicate) => wire.Expression.createCollectionQuantifier(
      source: source,
      quantifier: switch (value.quantifier) {
        CollectionQuantifier.any => wire.CollectionQuantifier.any,
        CollectionQuantifier.all => wire.CollectionQuantifier.all,
        CollectionQuantifier.none => wire.CollectionQuantifier.none,
      },
      predicate: predicate,
      itemBindingId: wire_binding.BindingId(value: value.itemBindingId.value),
    ),
  );

  TypeResult<wire.Expression> _find(CollectionFindExpression value) =>
      combineResults(
        encode(value.source),
        encode(value.predicate),
        (source, predicate) => wire.Expression.createCollectionFind(
          source: source,
          selection: switch (value.selection) {
            CollectionSelection.first => wire.CollectionSelection.first,
            CollectionSelection.last => wire.CollectionSelection.last,
          },
          predicate: predicate,
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
        ),
      );

  TypeResult<wire.Expression> _count(CollectionCountExpression value) =>
      combineResults(
        encode(value.source),
        encode(value.predicate),
        (source, predicate) => wire.Expression.createCollectionCount(
          source: source,
          predicate: predicate,
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
        ),
      );

  TypeResult<wire.Expression> _distinct(CollectionDistinctExpression value) =>
      combineResults(
        encode(value.source),
        _optional(value.key),
        (source, key) => wire.Expression.createCollectionDistinct(
          source: source,
          key: key,
          itemBindingId: value.itemBindingId == null
              ? null
              : wire_binding.BindingId(value: value.itemBindingId!.value),
        ),
      );

  TypeResult<wire.Expression> _sort(CollectionSortExpression value) =>
      combineThreeResults(
        encode(value.source),
        encode(value.key),
        _comparator(value.comparator),
        (source, key, comparator) => wire.Expression.createCollectionSort(
          source: source,
          key: key,
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
          direction: switch (value.direction) {
            CollectionSortDirection.ascending =>
              wire.CollectionSortDirection.ascending,
            CollectionSortDirection.descending =>
              wire.CollectionSortDirection.descending,
          },
          comparator: comparator,
        ),
      );

  TypeResult<wire.Expression> _group(CollectionGroupExpression value) =>
      combineThreeResults(
        encode(value.source),
        encode(value.key),
        _optional(value.value),
        (source, key, groupedValue) => wire.Expression.createCollectionGroup(
          source: source,
          key: key,
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
          value: groupedValue,
        ),
      );

  TypeResult<wire.Expression> _reduce(CollectionReduceExpression value) =>
      combineResults(
        encode(value.source),
        encode(value.reduction),
        (source, reduction) => wire.Expression.createCollectionReduce(
          source: source,
          accumulatorBindingId: wire_binding.BindingId(
            value: value.accumulatorBindingId.value,
          ),
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
          reduction: reduction,
        ),
      );

  TypeResult<wire.Expression> _fold(CollectionFoldExpression value) =>
      combineThreeResults(
        encode(value.source),
        encode(value.initial),
        encode(value.reduction),
        (source, initial, reduction) => wire.Expression.createCollectionFold(
          source: source,
          initial: initial,
          accumulatorBindingId: wire_binding.BindingId(
            value: value.accumulatorBindingId.value,
          ),
          itemBindingId: wire_binding.BindingId(
            value: value.itemBindingId.value,
          ),
          reduction: reduction,
        ),
      );

  TypeResult<wire.Expression> _transform(CollectionTransformExpression value) =>
      combineThreeResults(
        encode(value.source),
        _optional(value.transform),
        _optional(value.count),
        (source, transform, count) => wire.Expression.createCollectionTransform(
          source: source,
          operation: switch (value.operation) {
            CollectionTransformOperation.flatMap =>
              wire.CollectionTransformOperation.flatMap,
            CollectionTransformOperation.take =>
              wire.CollectionTransformOperation.take,
            CollectionTransformOperation.skip =>
              wire.CollectionTransformOperation.skip,
            CollectionTransformOperation.reverse =>
              wire.CollectionTransformOperation.reverse,
          },
          transform: transform,
          itemBindingId: value.itemBindingId == null
              ? null
              : wire_binding.BindingId(value: value.itemBindingId!.value),
          count: count,
        ),
      );

  TypeResult<wire.CollectionComparator?> _comparator(
    CollectionComparator? value,
  ) {
    if (value == null) return TypeResult.success(null);
    return encode(value.comparison).mapValue(
      (comparison) => wire.CollectionComparator(
        leftBindingId: wire_binding.BindingId(value: value.leftBindingId.value),
        rightBindingId: wire_binding.BindingId(
          value: value.rightBindingId.value,
        ),
        comparison: comparison,
      ),
    );
  }

  TypeResult<wire.TypedExpression?> _optional(TypedExpression? value) =>
      value == null
      ? TypeResult.success(null)
      : encode(value).mapValue((value) => value);

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
