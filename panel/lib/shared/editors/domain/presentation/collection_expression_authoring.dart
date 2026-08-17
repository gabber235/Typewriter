import "package:typewriter_panel/typewriter_panel.dart";

extension CollectionExpressionAuthoring on TypedExpression {
  TypedExpression collectionMap({
    required BindingId itemBindingId,
    required TypedExpression transform,
  }) => TypedExpression(
    resultType: ListType(element: transform.resultType),
    expression: CollectionMapExpression(
      source: this,
      itemBindingId: itemBindingId,
      transform: transform,
    ),
  );

  TypedExpression filter({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => TypedExpression(
    resultType: ListType(element: _collectionElementType),
    expression: CollectionFilterExpression(
      source: this,
      itemBindingId: itemBindingId,
      predicate: predicate,
    ),
  );

  TypedExpression any({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => _quantify(CollectionQuantifier.any, itemBindingId, predicate);

  TypedExpression all({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => _quantify(CollectionQuantifier.all, itemBindingId, predicate);

  TypedExpression none({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => _quantify(CollectionQuantifier.none, itemBindingId, predicate);

  TypedExpression findFirst({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => _find(CollectionSelection.first, itemBindingId, predicate);

  TypedExpression findLast({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => _find(CollectionSelection.last, itemBindingId, predicate);

  TypedExpression countWhere({
    required BindingId itemBindingId,
    required TypedExpression predicate,
  }) => TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: CollectionCountExpression(
      source: this,
      itemBindingId: itemBindingId,
      predicate: predicate,
    ),
  );

  TypedExpression distinct() => TypedExpression(
    resultType: ListType(element: _collectionElementType),
    expression: CollectionDistinctExpression(source: this),
  );

  TypedExpression distinctBy({
    required BindingId itemBindingId,
    required TypedExpression key,
  }) => TypedExpression(
    resultType: ListType(element: _collectionElementType),
    expression: CollectionDistinctExpression(
      source: this,
      itemBindingId: itemBindingId,
      key: key,
    ),
  );

  TypedExpression sortBy({
    required BindingId itemBindingId,
    required TypedExpression key,
    CollectionSortDirection direction = CollectionSortDirection.ascending,
    CollectionComparator? comparator,
  }) => TypedExpression(
    resultType: ListType(element: _collectionElementType),
    expression: CollectionSortExpression(
      source: this,
      itemBindingId: itemBindingId,
      key: key,
      direction: direction,
      comparator: comparator,
    ),
  );

  TypedExpression groupBy({
    required BindingId itemBindingId,
    required TypedExpression key,
    TypedExpression? value,
  }) => TypedExpression(
    resultType: MapType(
      key: key.resultType,
      value: ListType(element: value?.resultType ?? _collectionElementType),
    ),
    expression: CollectionGroupExpression(
      source: this,
      itemBindingId: itemBindingId,
      key: key,
      value: value,
    ),
  );

  TypedExpression reduce({
    required BindingId accumulatorBindingId,
    required BindingId itemBindingId,
    required TypedExpression reduction,
  }) => TypedExpression(
    resultType: NamedType(standardTypeRefs.optionOf(_collectionElementType)),
    expression: CollectionReduceExpression(
      source: this,
      accumulatorBindingId: accumulatorBindingId,
      itemBindingId: itemBindingId,
      reduction: reduction,
    ),
  );

  TypedExpression fold({
    required TypedExpression initial,
    required BindingId accumulatorBindingId,
    required BindingId itemBindingId,
    required TypedExpression reduction,
  }) => TypedExpression(
    resultType: initial.resultType,
    expression: CollectionFoldExpression(
      source: this,
      initial: initial,
      accumulatorBindingId: accumulatorBindingId,
      itemBindingId: itemBindingId,
      reduction: reduction,
    ),
  );

  TypedExpression flatMap({
    required BindingId itemBindingId,
    required TypedExpression transform,
  }) => TypedExpression(
    resultType: ListType(element: transform.resultType._listElementType),
    expression: CollectionTransformExpression(
      source: this,
      operation: CollectionTransformOperation.flatMap,
      itemBindingId: itemBindingId,
      transform: transform,
    ),
  );

  TypedExpression take(TypedExpression count) =>
      _collectionTransform(CollectionTransformOperation.take, count: count);

  TypedExpression skip(TypedExpression count) =>
      _collectionTransform(CollectionTransformOperation.skip, count: count);

  TypedExpression reverse() =>
      _collectionTransform(CollectionTransformOperation.reverse);

  TypedExpression _quantify(
    CollectionQuantifier quantifier,
    BindingId itemBindingId,
    TypedExpression predicate,
  ) => TypedExpression(
    resultType: const BooleanType(),
    expression: CollectionQuantifierExpression(
      source: this,
      quantifier: quantifier,
      itemBindingId: itemBindingId,
      predicate: predicate,
    ),
  );

  TypedExpression _find(
    CollectionSelection selection,
    BindingId itemBindingId,
    TypedExpression predicate,
  ) => TypedExpression(
    resultType: NamedType(standardTypeRefs.optionOf(_collectionElementType)),
    expression: CollectionFindExpression(
      source: this,
      selection: selection,
      itemBindingId: itemBindingId,
      predicate: predicate,
    ),
  );

  TypedExpression _collectionTransform(
    CollectionTransformOperation operation, {
    TypedExpression? count,
  }) => TypedExpression(
    resultType: ListType(element: _collectionElementType),
    expression: CollectionTransformExpression(
      source: this,
      operation: operation,
      count: count,
    ),
  );

  TypeExpression get _collectionElementType =>
      resultType._collectionElementType;
}

extension on TypeExpression {
  TypeExpression get _collectionElementType => switch (this) {
    ListType(:final element) => element,
    MapType(:final value) => value,
    _ => throw ArgumentError.value(this, "resultType", "Must be a list or map"),
  };

  TypeExpression get _listElementType => switch (this) {
    ListType(:final element) => element,
    _ => throw ArgumentError.value(this, "resultType", "Must be a list"),
  };
}
