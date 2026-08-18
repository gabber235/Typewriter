part of "expression_evaluator.dart";

extension on _ExpressionEvaluator {
  TypeResult<DataValue> _filter(
    CollectionFilterExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final filtered = <DataValue>[];
    for (final item in collection.valueOrNull!.items) {
      final result = _evaluateBound(
        expression.predicate,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (result case TypeFailure()) return result;
      if (result.valueOrNull case BooleanValue(value: true)) filtered.add(item);
      if (result.valueOrNull is! BooleanValue) {
        return _failure("Collection predicate must be boolean");
      }
    }
    return TypeResult.success(ListValue(filtered));
  }

  TypeResult<DataValue> _quantify(
    CollectionQuantifierExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    var matched = 0;
    for (final item in collection.valueOrNull!.items) {
      final result = _evaluateBound(
        expression.predicate,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (result case TypeFailure()) return result;
      if (result.valueOrNull is! BooleanValue) {
        return _failure("Collection predicate must be boolean");
      }
      if ((result.valueOrNull! as BooleanValue).value) matched++;
    }
    final count = collection.valueOrNull!.items.length;
    return TypeResult.success(
      BooleanValue(switch (expression.quantifier) {
        CollectionQuantifier.any => matched > 0,
        CollectionQuantifier.all => matched == count,
        CollectionQuantifier.none => matched == 0,
      }),
    );
  }

  TypeResult<DataValue> _find(CollectionFindExpression expression, int depth) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final items = expression.selection == CollectionSelection.first
        ? collection.valueOrNull!.items
        : collection.valueOrNull!.items.reversed;
    for (final item in items) {
      final result = _evaluateBound(
        expression.predicate,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (result case TypeFailure()) return result;
      if (result.valueOrNull is! BooleanValue) {
        return _failure("Collection predicate must be boolean");
      }
      if ((result.valueOrNull! as BooleanValue).value) {
        return _some(item, collection.valueOrNull!.itemType);
      }
    }
    return _none(collection.valueOrNull!.itemType);
  }

  TypeResult<DataValue> _count(
    CollectionCountExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    var count = 0;
    for (final item in collection.valueOrNull!.items) {
      final result = _evaluateBound(
        expression.predicate,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (result case TypeFailure()) return result;
      if (result.valueOrNull is! BooleanValue) {
        return _failure("Collection predicate must be boolean");
      }
      if ((result.valueOrNull! as BooleanValue).value) count++;
    }
    return TypeResult.success(IntegerValue(BigInt.from(count)));
  }

  TypeResult<DataValue> _distinct(
    CollectionDistinctExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    if ((expression.key == null) != (expression.itemBindingId == null)) {
      return _failure(
        "Distinct key and item binding must be provided together",
      );
    }
    final seen = <DataValue>{};
    final output = <DataValue>[];
    for (final item in collection.valueOrNull!.items) {
      final key = expression.key == null
          ? TypeResult.success(item)
          : _evaluateBound(
              expression.key!,
              expression.itemBindingId!,
              collection.valueOrNull!.itemType,
              item,
              depth,
            );
      if (key case TypeFailure()) return key;
      if (seen.add(key.valueOrNull!)) output.add(item);
    }
    return TypeResult.success(ListValue(output));
  }

  TypeResult<DataValue> _sort(CollectionSortExpression expression, int depth) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final keyed = <({DataValue item, DataValue key, int index})>[];
    for (final entry in collection.valueOrNull!.items.indexed) {
      final key = _evaluateBound(
        expression.key,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        entry.$2,
        depth,
      );
      if (key case TypeFailure()) return key;
      keyed.add((item: entry.$2, key: key.valueOrNull!, index: entry.$1));
    }
    TypeResult<int> compare(
      ({DataValue item, DataValue key, int index}) left,
      ({DataValue item, DataValue key, int index}) right,
    ) {
      if (expression.comparator == null) {
        final value = compareExpressionValues(left.key, right.key);
        return value == null
            ? TypeResult.failure([
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
                  message: "Sort key is not naturally comparable",
                ),
              ])
            : TypeResult.success(value);
      }
      final comparator = expression.comparator!;
      final context = this.context
          .withBinding(
            comparator.leftBindingId,
            BindingSnapshot(
              type: expression.key.resultType,
              value: left.key,
              revision: 0,
              writable: false,
            ),
          )
          .withBinding(
            comparator.rightBindingId,
            BindingSnapshot(
              type: expression.key.resultType,
              value: right.key,
              revision: 0,
              writable: false,
            ),
          );
      final child = _ExpressionEvaluator(context, budget, registry);
      final result = child.evaluate(comparator.comparison, depth + 1);
      nodes += child.nodes;
      evaluations += child.evaluations;
      if (result case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      final value = result.valueOrNull;
      if (value is! IntegerValue) {
        return TypeResult.failure([
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Sort comparator must return an integer",
          ),
        ]);
      }
      return TypeResult.success(value.value.sign);
    }

    TypeFailure<DataValue>? failure;
    keyed.sort((left, right) {
      if (failure != null) return 0;
      final result = compare(left, right);
      if (result case TypeFailure(:final diagnostics)) {
        failure = TypeFailure<DataValue>(diagnostics);
        return 0;
      }
      final direction =
          expression.direction == CollectionSortDirection.ascending ? 1 : -1;
      final compared = result.valueOrNull! * direction;
      return compared == 0 ? left.index.compareTo(right.index) : compared;
    });
    if (failure != null) return failure!;
    return TypeResult.success(
      ListValue(keyed.map((entry) => entry.item).toList()),
    );
  }

  TypeResult<DataValue> _group(
    CollectionGroupExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final groups = <DataValue, List<DataValue>>{};
    for (final item in collection.valueOrNull!.items) {
      final key = _evaluateBound(
        expression.key,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (key case TypeFailure()) return key;
      final value = expression.value == null
          ? TypeResult.success(item)
          : _evaluateBound(
              expression.value!,
              expression.itemBindingId,
              collection.valueOrNull!.itemType,
              item,
              depth,
            );
      if (value case TypeFailure()) return value;
      groups.putIfAbsent(key.valueOrNull!, () => []).add(value.valueOrNull!);
    }
    return TypeResult.success(
      MapValue([
        for (final group in groups.entries)
          DataMapEntry(key: group.key, value: ListValue(group.value)),
      ]),
    );
  }

  TypeResult<DataValue> _reduce(
    CollectionReduceExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final items = collection.valueOrNull!.items;
    if (items.isEmpty) return _none(collection.valueOrNull!.itemType);
    var accumulator = items.first;
    for (final item in items.skip(1)) {
      final next = _evaluateReduction(
        expression.reduction,
        expression.accumulatorBindingId,
        collection.valueOrNull!.itemType,
        accumulator,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (next case TypeFailure()) return next;
      accumulator = next.valueOrNull!;
    }
    return _some(accumulator, collection.valueOrNull!.itemType);
  }

  TypeResult<DataValue> _fold(CollectionFoldExpression expression, int depth) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final initial = evaluate(expression.initial, depth + 1);
    if (initial case TypeFailure()) return initial;
    var accumulator = initial.valueOrNull!;
    for (final item in collection.valueOrNull!.items) {
      final next = _evaluateReduction(
        expression.reduction,
        expression.accumulatorBindingId,
        expression.initial.resultType,
        accumulator,
        expression.itemBindingId,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (next case TypeFailure()) return next;
      accumulator = next.valueOrNull!;
    }
    return TypeResult.success(accumulator);
  }

  TypeResult<DataValue> _transformCollection(
    CollectionTransformExpression expression,
    int depth,
  ) {
    final collection = _collection(expression.source, depth);
    if (collection case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final items = collection.valueOrNull!.items;
    return switch (expression.operation) {
      CollectionTransformOperation.reverse =>
        expression.transform != null ||
                expression.itemBindingId != null ||
                expression.count != null
            ? _failure("Reverse does not accept transform or count")
            : TypeResult.success(ListValue(items.reversed.toList())),
      CollectionTransformOperation.take || CollectionTransformOperation.skip =>
        _takeOrSkip(expression, items, depth),
      CollectionTransformOperation.flatMap => _flatMap(
        expression,
        collection,
        depth,
      ),
    };
  }

  TypeResult<DataValue> _takeOrSkip(
    CollectionTransformExpression expression,
    List<DataValue> items,
    int depth,
  ) {
    if (expression.count == null ||
        expression.transform != null ||
        expression.itemBindingId != null) {
      return _failure("Take and skip require only a count");
    }
    final count = evaluate(expression.count!, depth + 1);
    if (count case TypeFailure()) return count;
    final countValue = count.valueOrNull;
    if (countValue is! IntegerValue || countValue.value < BigInt.zero) {
      return _failure("Collection count must be a nonnegative integer");
    }
    final amount = countValue.value.toInt();
    return TypeResult.success(
      ListValue(
        expression.operation == CollectionTransformOperation.take
            ? items.take(amount).toList()
            : items.skip(amount).toList(),
      ),
    );
  }

  TypeResult<DataValue> _flatMap(
    CollectionTransformExpression expression,
    TypeResult<_CollectionItems> collection,
    int depth,
  ) {
    if (expression.transform == null ||
        expression.itemBindingId == null ||
        expression.count != null) {
      return _failure("Flat map requires an item binding and transform");
    }
    final output = <DataValue>[];
    for (final item in collection.valueOrNull!.items) {
      final mapped = _evaluateBound(
        expression.transform!,
        expression.itemBindingId!,
        collection.valueOrNull!.itemType,
        item,
        depth,
      );
      if (mapped case TypeFailure()) return mapped;
      final mappedValue = mapped.valueOrNull;
      if (mappedValue is! ListValue) {
        return _failure("Flat map transform must return a list");
      }
      output.addAll(mappedValue.values);
    }
    return TypeResult.success(ListValue(output));
  }

  TypeResult<_CollectionItems> _collection(TypedExpression source, int depth) {
    final result = evaluate(source, depth + 1);
    if (result case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    return switch ((result.valueOrNull!, source.resultType)) {
      (ListValue(:final values), ListType(:final element)) =>
        TypeResult.success(_CollectionItems(values, element)),
      (MapValue(:final entries), MapType(value: final valueType)) =>
        TypeResult.success(
          _CollectionItems(
            entries.map((entry) => entry.value).toList(),
            valueType,
          ),
        ),
      _ => TypeResult.failure([
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "Collection source must be a list or map",
        ),
      ]),
    };
  }

  TypeResult<DataValue> _evaluateBound(
    TypedExpression expression,
    BindingId bindingId,
    TypeExpression type,
    DataValue value,
    int depth,
  ) => _evaluateReduction(
    expression,
    bindingId,
    type,
    value,
    null,
    null,
    null,
    depth,
  );

  TypeResult<DataValue> _evaluateReduction(
    TypedExpression expression,
    BindingId firstBindingId,
    TypeExpression firstType,
    DataValue firstValue,
    BindingId? secondBindingId,
    TypeExpression? secondType,
    DataValue? secondValue,
    int depth,
  ) {
    var childContext = context.withBinding(
      firstBindingId,
      BindingSnapshot(
        type: firstType,
        value: firstValue,
        revision: 0,
        writable: false,
      ),
    );
    if (secondBindingId != null) {
      childContext = childContext.withBinding(
        secondBindingId,
        BindingSnapshot(
          type: secondType!,
          value: secondValue!,
          revision: 0,
          writable: false,
        ),
      );
    }
    final child = _ExpressionEvaluator(childContext, budget, registry);
    final result = child.evaluate(expression, depth + 1);
    nodes += child.nodes;
    evaluations += child.evaluations;
    return result;
  }

  TypeResult<DataValue> _some(DataValue value, TypeExpression type) =>
      TypeResult.success(
        PolymorphicValue(
          concreteType: standardTypeRefs.someOf(type),
          value: RecordValue({"value": value}),
        ),
      );

  TypeResult<DataValue> _none(TypeExpression type) => TypeResult.success(
    PolymorphicValue(
      concreteType: standardTypeRefs.noneOf(type),
      value: const UnitValue(),
    ),
  );
}

final class _CollectionItems {
  const _CollectionItems(this.items, this.itemType);

  final List<DataValue> items;
  final TypeExpression itemType;
}
