import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const authoredPortableOperationIds = <String>{
  "typewriter.boolean.not",
  "typewriter.collection.access",
  "typewriter.collection.contains",
  "typewriter.collection.size",
  "typewriter.color.with_alpha",
  "typewriter.number.add",
  "typewriter.number.divide",
  "typewriter.number.gt",
  "typewriter.number.gte",
  "typewriter.number.lt",
  "typewriter.number.lte",
  "typewriter.number.multiply",
  "typewriter.number.negate",
  "typewriter.number.remainder",
  "typewriter.number.subtract",
  "typewriter.link.target",
  "typewriter.record.field",
  "typewriter.regex.capture",
  "typewriter.regex.matches",
  "typewriter.regex.replace",
  "typewriter.rule.between",
  "typewriter.rule.endsWith",
  "typewriter.rule.itemsBetween",
  "typewriter.rule.lengthBetween",
  "typewriter.rule.maximum",
  "typewriter.rule.maximumItems",
  "typewriter.rule.maximumLength",
  "typewriter.rule.maximumLines",
  "typewriter.rule.maximumScale",
  "typewriter.rule.minimum",
  "typewriter.rule.minimumItems",
  "typewriter.rule.minimumLength",
  "typewriter.rule.minimumLines",
  "typewriter.rule.multipleOf",
  "typewriter.rule.nonBlank",
  "typewriter.rule.nonEmpty",
  "typewriter.rule.nonNegative",
  "typewriter.rule.notAfter",
  "typewriter.rule.notBefore",
  "typewriter.rule.notNull",
  "typewriter.rule.one_of",
  "typewriter.rule.opaque",
  "typewriter.rule.positive",
  "typewriter.rule.regex",
  "typewriter.rule.singleLine",
  "typewriter.rule.startsWith",
  "typewriter.rule.unique",
  "typewriter.text.contains",
  "typewriter.text.ends_with",
  "typewriter.text.has_line_break",
  "typewriter.text.interpolate",
  "typewriter.text.join",
  "typewriter.text.length",
  "typewriter.text.lower",
  "typewriter.text.replace",
  "typewriter.text.split",
  "typewriter.text.starts_with",
  "typewriter.text.substring",
  "typewriter.text.title",
  "typewriter.text.trim",
  "typewriter.text.upper",
  "typewriter.value.eq",
  "typewriter.value.is_null",
  "typewriter.value.neq",
};

sealed class PortableExpressionResult {
  const PortableExpressionResult(this.reads);

  final List<PortableExpressionRead> reads;
}

final class PortableExpressionAvailable extends PortableExpressionResult {
  const PortableExpressionAvailable(this.value, super.reads);

  final skir.DataValue value;
}

final class PortableExpressionUnavailable extends PortableExpressionResult {
  const PortableExpressionUnavailable(super.reads);
}

final class PortableExpressionFailed extends PortableExpressionResult {
  const PortableExpressionFailed(this.code, this.message, super.reads);

  final String code;
  final String message;
}

final class PortableExpressionRead {
  const PortableExpressionRead(this.binding, this.path, {this.location});

  final skir.ExpressionBindingId binding;
  final skir.ValuePath path;
  final skir.ValueLocation? location;

  String get key {
    final suffix = path.segments
        .map(
          (segment) => switch (segment) {
            skir.PathSegment_fieldWrapper(:final value) => value.name,
            skir.PathSegment_itemWrapper(:final value) => value.id.value,
            _ => "?",
          },
        )
        .join(":");
    return suffix.isEmpty ? binding.value : "${binding.value}:$suffix";
  }

  @override
  bool operator ==(Object other) =>
      other is PortableExpressionRead &&
      other.binding == binding &&
      other.path == path &&
      other.location == location;

  @override
  int get hashCode => Object.hash(binding, path, location);
}

final class PortableExpressionBinding {
  const PortableExpressionBinding({
    required this.value,
    this.location,
    this.schema,
  });

  final skir.DataValue value;
  final skir.ValueLocation? location;
  final PortablePresentationBindingSchema? schema;
}

final class PortableExpressionEvaluator {
  PortableExpressionEvaluator(
    Map<skir.ExpressionBindingId, skir.DataValue> bindings, {
    required this.budget,
  }) : _bindings = Map.unmodifiable({
         for (final entry in bindings.entries)
           entry.key: PortableExpressionBinding(value: entry.value),
       });

  PortableExpressionEvaluator.located(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, {
    required this.budget,
  }) : _bindings = Map.unmodifiable(bindings);

  factory PortableExpressionEvaluator.configuredValue({
    required skir.DataValue value,
    required skir.ValueLocation location,
    required skir.EvaluationBudget budget,
    Map<skir.ExpressionBindingId, PortableExpressionBinding> additional =
        const {},
  }) => PortableExpressionEvaluator.located({
    ...additional,
    skir.ExpressionBindingId(value: "configured_value"):
        PortableExpressionBinding(value: value, location: location),
  }, budget: budget);

  final skir.EvaluationBudget budget;
  final Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
  final Map<skir.ExpressionBindingId, PortableExpressionBinding> _locals = {};
  final Set<PortableExpressionRead> _reads = {};
  var _steps = 0;
  var _collectionItems = 0;
  var _depth = 0;

  PortableExpressionResult evaluate(skir.ExpressionNode node) {
    _reads.clear();
    _locals.clear();
    _steps = 0;
    _collectionItems = 0;
    _depth = 0;
    try {
      final result = _evaluate(node);
      return switch (result) {
        _Available(:final value) => PortableExpressionAvailable(
          value,
          List.unmodifiable(_reads),
        ),
        _Unavailable() => PortableExpressionUnavailable(
          List.unmodifiable(_reads),
        ),
      };
    } on _ExpressionFailure catch (failure) {
      return PortableExpressionFailed(
        failure.code,
        failure.message,
        List.unmodifiable(_reads),
      );
    } on RangeError {
      return PortableExpressionFailed(
        "invalid_operation_arguments",
        "The expression operation received the wrong number of arguments",
        List.unmodifiable(_reads),
      );
    }
  }

  _Evaluation _evaluate(skir.ExpressionNode node) {
    _depth++;
    try {
      if (_depth > 512) {
        throw const _ExpressionFailure(
          "expression_depth_limit",
          "The expression exceeded its depth limit",
        );
      }
      _consumeStep();
      return switch (node) {
        skir.ExpressionNode_literalWrapper(:final value) => _Available(value),
        skir.ExpressionNode_readWrapper(:final value) => _read(value),
        skir.ExpressionNode_callWrapper(:final value) => _call(value),
        skir.ExpressionNode_andWrapper(:final value) => _boolean(
          value.left,
          value.right,
          conjunction: true,
        ),
        skir.ExpressionNode_orWrapper(:final value) => _boolean(
          value.left,
          value.right,
          conjunction: false,
        ),
        skir.ExpressionNode_conditionalWrapper(:final value) => _conditional(
          value,
        ),
        skir.ExpressionNode_orElseWrapper(:final value) => _orElse(value),
        skir.ExpressionNode_collectionWrapper(:final value) => _collection(
          value,
        ),
        skir.ExpressionNode_unknown() => throw const _ExpressionFailure(
          "unknown_expression",
          "The expression variant is unknown",
        ),
      };
    } finally {
      _depth--;
    }
  }

  _Evaluation _read(skir.ExpressionRead read) {
    final binding = _locals[read.binding] ?? _bindings[read.binding];
    _reads.add(
      PortableExpressionRead(
        read.binding,
        read.path,
        location: binding?.location == null
            ? null
            : skir.ValueLocation(
                resource: binding!.location!.resource,
                path: skir.ValuePath(
                  segments: [
                    ...binding.location!.path.segments,
                    ...read.path.segments,
                  ],
                ),
              ),
      ),
    );
    if (binding == null) return const _Unavailable();
    final root = binding.value;
    if (read.path.segments.isEmpty) {
      return root == skir.DataValue.unfilled
          ? const _Unavailable()
          : _Available(root);
    }
    return switch (root.readAt(read.path)) {
      PortablePathValue(:final value) when value != skir.DataValue.unfilled =>
        _Available(value),
      _ => const _Unavailable(),
    };
  }

  _Evaluation _boolean(
    skir.ExpressionNode left,
    skir.ExpressionNode right, {
    required bool conjunction,
  }) {
    final first = _evaluate(left);
    if (first is _Unavailable) return first;
    final firstValue = _booleanValue((first as _Available).value);
    if (conjunction ? !firstValue : firstValue) {
      return _Available(skir.DataValue.wrapBoolean(firstValue));
    }
    final second = _evaluate(right);
    if (second is _Unavailable) return second;
    return _Available(
      skir.DataValue.wrapBoolean(_booleanValue((second as _Available).value)),
    );
  }

  _Evaluation _conditional(skir.ConditionalExpression value) {
    final test = _evaluate(value.test);
    if (test is _Unavailable) return test;
    return _evaluate(
      _booleanValue((test as _Available).value) ? value.yes : value.no,
    );
  }

  _Evaluation _orElse(skir.OrElseExpression value) {
    final input = _evaluate(value.input);
    if (input is _Unavailable) return _evaluate(value.fallback);
    final actual = (input as _Available).value;
    return actual == skir.DataValue.null_ || actual == skir.DataValue.unfilled
        ? _evaluate(value.fallback)
        : input;
  }

  _Evaluation _call(skir.ExpressionCall call) {
    final arguments = <skir.DataValue>[];
    for (final argument in call.arguments) {
      final evaluated = _evaluate(argument);
      if (evaluated is _Unavailable) return evaluated;
      arguments.add((evaluated as _Available).value);
    }
    _validateOperationArity(call.operation.value, arguments.length);
    if (call.operation.value == "typewriter.rule.unique") {
      return _unique(arguments.single);
    }
    return _Available(_operation(call.operation.value, arguments));
  }

  _Evaluation _collection(skir.CollectionExpression expression) {
    final input = _evaluate(expression.input);
    if (input is _Unavailable) return input;
    final inputValue = (input as _Available).value;
    final entries = _collectionEntries(inputValue);
    final sourceLocation = _sourceLocation(expression.input);
    final arguments = <skir.DataValue>[];
    for (final argument in expression.arguments) {
      final result = _evaluate(argument);
      if (result is _Unavailable) return result;
      final value = (result as _Available).value;
      if (_containsUnfilled(value)) return const _Unavailable();
      arguments.add(value);
    }
    return switch (expression.operation.value) {
      "typewriter.collection.take" => _takeOrSkip(
        expression,
        inputValue,
        entries,
        arguments,
        take: true,
      ),
      "typewriter.collection.skip" => _takeOrSkip(
        expression,
        inputValue,
        entries,
        arguments,
        take: false,
      ),
      "typewriter.collection.reverse" => _reverse(
        expression,
        inputValue,
        entries,
      ),
      "typewriter.collection.distinct" => _distinct(
        expression,
        inputValue,
        entries,
      ),
      "typewriter.collection.reduce" || "typewriter.collection.fold" => _fold(
        expression,
        entries,
        arguments,
        sourceLocation,
      ),
      "typewriter.collection.sort_with" => _sortWith(
        expression,
        inputValue,
        entries,
        sourceLocation,
      ),
      _ => _collectionWithUnaryBody(
        expression,
        inputValue,
        entries,
        arguments,
        sourceLocation,
      ),
    };
  }

  _Evaluation _takeOrSkip(
    skir.CollectionExpression expression,
    skir.DataValue input,
    List<_CollectionEntry> entries,
    List<skir.DataValue> arguments, {
    required bool take,
  }) {
    _requireCollectionShape(expression, bindings: 0, arguments: 1, body: false);
    final count = _nonnegativeCount(arguments.single);
    _consumeCollectionItems(count < entries.length ? count : entries.length);
    return _Available(
      _reorderCollection(
        input,
        take ? entries.take(count).toList() : entries.skip(count).toList(),
      ),
    );
  }

  _Evaluation _reverse(
    skir.CollectionExpression expression,
    skir.DataValue input,
    List<_CollectionEntry> entries,
  ) {
    _requireCollectionShape(expression, bindings: 0, arguments: 0, body: false);
    _consumeCollectionItems(entries.length);
    return _Available(_reorderCollection(input, entries.reversed.toList()));
  }

  _Evaluation _distinct(
    skir.CollectionExpression expression,
    skir.DataValue input,
    List<_CollectionEntry> entries,
  ) {
    _requireCollectionShape(expression, bindings: 0, arguments: 0, body: false);
    _consumeCollectionItems(entries.length);
    if (entries.any((entry) => _containsUnfilled(entry.value))) {
      return const _Unavailable();
    }
    final seen = <String>{};
    return _Available(
      _reorderCollection(
        input,
        entries.where((entry) => seen.add(_canonical(entry.value))).toList(),
      ),
    );
  }

  _Evaluation _collectionWithUnaryBody(
    skir.CollectionExpression expression,
    skir.DataValue input,
    List<_CollectionEntry> entries,
    List<skir.DataValue> arguments,
    skir.ValueLocation? sourceLocation,
  ) {
    final operation = expression.operation.value;
    _requireCollectionShape(
      expression,
      bindings: 1,
      minimumArguments: 0,
      maximumArguments: operation == "typewriter.collection.sort_by" ? 1 : 0,
      body: true,
    );
    final binding = expression.bindings.single;
    final body = expression.body!;
    final results = <(_CollectionEntry, skir.DataValue)>[];
    var unavailable = false;
    for (final entry in entries) {
      _consumeCollectionItems(1);
      final result = _evaluateWithLocals({
        binding: PortableExpressionBinding(
          value: entry.value,
          location: sourceLocation == null
              ? null
              : _entryLocation(sourceLocation, entry.id),
        ),
      }, body);
      if (result is _Unavailable) {
        unavailable = true;
        continue;
      }
      final value = (result as _Available).value;
      if (_containsUnfilled(value)) {
        unavailable = true;
        continue;
      }
      results.add((entry, value));
      if (operation == "typewriter.collection.any" && _booleanValue(value)) {
        return _Available(_bool(true));
      }
      if (operation == "typewriter.collection.all" && !_booleanValue(value)) {
        return _Available(_bool(false));
      }
      if (operation == "typewriter.collection.none" && _booleanValue(value)) {
        return _Available(_bool(false));
      }
      if (operation == "typewriter.collection.find" && _booleanValue(value)) {
        return unavailable ? const _Unavailable() : _Available(entry.value);
      }
    }
    if (operation == "typewriter.collection.unique_by") {
      final seen = <String>{};
      for (final result in results) {
        if (!seen.add(_canonical(result.$2))) return _Available(_bool(false));
      }
    }
    if (unavailable) return const _Unavailable();
    return switch (operation) {
      "typewriter.collection.any" => _Available(_bool(false)),
      "typewriter.collection.all" ||
      "typewriter.collection.none" => _Available(_bool(true)),
      "typewriter.collection.unique_by" => _Available(_bool(true)),
      "typewriter.collection.map" => _Available(
        skir.DataValue.createListValue(
          items: [
            for (final result in results)
              skir.ListItem(id: result.$1.id, value: result.$2),
          ],
        ),
      ),
      "typewriter.collection.filter" => _Available(
        _reorderCollection(
          input,
          results
              .where((result) => _booleanValue(result.$2))
              .map((result) => result.$1)
              .toList(),
        ),
      ),
      "typewriter.collection.find" => _Available(skir.DataValue.null_),
      "typewriter.collection.find_last" => _Available(
        results
                .where((result) => _booleanValue(result.$2))
                .lastOrNull
                ?.$1
                .value ??
            skir.DataValue.null_,
      ),
      "typewriter.collection.count" => _Available(
        _integerValue(
          results.where((result) => _booleanValue(result.$2)).length,
        ),
      ),
      "typewriter.collection.distinct_by" => _Available(
        _reorderCollection(input, _distinctEntriesByResult(results)),
      ),
      "typewriter.collection.sort_by" => _Available(
        _reorderCollection(
          input,
          _sortEntriesByResult(
            results,
            descending:
                arguments.singleOrNull != null &&
                _booleanValue(arguments.single),
          ),
        ),
      ),
      "typewriter.collection.group_by" => _Available(_groupByKey(results)),
      "typewriter.collection.flat_map" => _Available(_flatMap(results)),
      _ => throw _ExpressionFailure(
        "unknown_collection_operation",
        "Unknown collection operation $operation",
      ),
    };
  }

  _Evaluation _fold(
    skir.CollectionExpression expression,
    List<_CollectionEntry> entries,
    List<skir.DataValue> arguments,
    skir.ValueLocation? sourceLocation,
  ) {
    final fold = expression.operation.value == "typewriter.collection.fold";
    _requireCollectionShape(
      expression,
      bindings: 2,
      arguments: fold ? 1 : 0,
      body: true,
    );
    if (!fold && entries.isEmpty) return _Available(skir.DataValue.null_);
    var accumulator = fold ? arguments.single : entries.first.value;
    var accumulatorLocation = fold
        ? _sourceLocation(expression.arguments.single)
        : sourceLocation == null
        ? null
        : _entryLocation(sourceLocation, entries.first.id);
    final remaining = fold ? entries : entries.skip(1);
    for (final entry in remaining) {
      _consumeCollectionItems(1);
      final result = _evaluateWithLocals({
        expression.bindings.first: PortableExpressionBinding(
          value: accumulator,
          location: accumulatorLocation,
        ),
        expression.bindings.last: PortableExpressionBinding(
          value: entry.value,
          location: sourceLocation == null
              ? null
              : _entryLocation(sourceLocation, entry.id),
        ),
      }, expression.body!);
      if (result is _Unavailable) return result;
      final value = (result as _Available).value;
      if (_containsUnfilled(value)) return const _Unavailable();
      accumulator = value;
      accumulatorLocation = null;
    }
    return _Available(accumulator);
  }

  _Evaluation _sortWith(
    skir.CollectionExpression expression,
    skir.DataValue input,
    List<_CollectionEntry> entries,
    skir.ValueLocation? sourceLocation,
  ) {
    _requireCollectionShape(expression, bindings: 2, arguments: 0, body: true);
    final sorted = <_CollectionEntry>[];
    for (final entry in entries) {
      var insertion = sorted.length;
      while (insertion > 0) {
        _consumeCollectionItems(2);
        final left = sorted[insertion - 1];
        final result = _evaluateWithLocals({
          expression.bindings.first: PortableExpressionBinding(
            value: left.value,
            location: sourceLocation == null
                ? null
                : _entryLocation(sourceLocation, left.id),
          ),
          expression.bindings.last: PortableExpressionBinding(
            value: entry.value,
            location: sourceLocation == null
                ? null
                : _entryLocation(sourceLocation, entry.id),
          ),
        }, expression.body!);
        if (result is _Unavailable) return result;
        final value = (result as _Available).value;
        if (_containsUnfilled(value)) return const _Unavailable();
        if (_number(value).compareTo(_Decimal.zero) <= 0) break;
        insertion--;
      }
      sorted.insert(insertion, entry);
    }
    return _Available(_reorderCollection(input, sorted));
  }

  _Evaluation _evaluateWithLocals(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> values,
    skir.ExpressionNode body,
  ) {
    final previous =
        <
          skir.ExpressionBindingId,
          ({bool present, PortableExpressionBinding? value})
        >{};
    for (final entry in values.entries) {
      previous[entry.key] = (
        present: _locals.containsKey(entry.key),
        value: _locals[entry.key],
      );
      _locals[entry.key] = entry.value;
    }
    try {
      return _evaluate(body);
    } finally {
      for (final entry in previous.entries) {
        if (entry.value.present) {
          _locals[entry.key] = entry.value.value!;
        } else {
          _locals.remove(entry.key);
        }
      }
    }
  }

  skir.ValueLocation? _sourceLocation(skir.ExpressionNode node) {
    if (node case skir.ExpressionNode_readWrapper(:final value)) {
      final binding = _locals[value.binding] ?? _bindings[value.binding];
      final base = binding?.location;
      if (base == null) return null;
      return _appendLocation(base, value.path);
    }
    return null;
  }

  void _requireCollectionShape(
    skir.CollectionExpression expression, {
    required int bindings,
    required bool body,
    int? arguments,
    int? minimumArguments,
    int? maximumArguments,
  }) {
    final minimum = arguments ?? minimumArguments!;
    final maximum = arguments ?? maximumArguments!;
    if (expression.bindings.length != bindings ||
        expression.arguments.length < minimum ||
        expression.arguments.length > maximum ||
        (expression.body != null) != body) {
      throw _ExpressionFailure(
        "collection_operation_shape",
        "Collection operation ${expression.operation.value} has an invalid binding, argument, or body shape",
      );
    }
    if (expression.bindings.toSet().length != expression.bindings.length) {
      throw const _ExpressionFailure(
        "duplicate_collection_binding",
        "Collection expression bindings must be distinct",
      );
    }
  }

  void _consumeCollectionItems(int count) {
    _collectionItems += count;
    if (_collectionItems > budget.maxCollectionItems) {
      throw const _ExpressionFailure(
        "expression_collection_limit",
        "The expression exceeded its collection item limit",
      );
    }
  }

  void _consumeStep() {
    _steps++;
    if (_steps > budget.maxSteps) {
      throw const _ExpressionFailure(
        "expression_step_limit",
        "The expression exceeded its step limit",
      );
    }
  }

  skir.DataValue _operation(String id, List<skir.DataValue> values) {
    if (!authoredPortableOperationIds.contains(id)) {
      throw _ExpressionFailure(
        "unknown_operation",
        "Unknown expression operation $id",
      );
    }
    return switch (id) {
      "typewriter.value.eq" => _bool(
        _canonical(values[0]) == _canonical(values[1]),
      ),
      "typewriter.value.neq" => _bool(
        _canonical(values[0]) != _canonical(values[1]),
      ),
      "typewriter.value.is_null" => _bool(
        values.single == skir.DataValue.null_,
      ),
      "typewriter.link.target" => _linkTarget(values.single),
      "typewriter.record.field" => _recordField(values),
      "typewriter.boolean.not" => _bool(!_booleanValue(values.single)),
      "typewriter.number.gt" => _bool(_compareNumbers(values) > 0),
      "typewriter.number.gte" => _bool(_compareNumbers(values) >= 0),
      "typewriter.number.lt" => _bool(_compareNumbers(values) < 0),
      "typewriter.number.lte" => _bool(_compareNumbers(values) <= 0),
      "typewriter.number.add" => _arithmetic(values, _Arithmetic.add),
      "typewriter.number.subtract" => _arithmetic(values, _Arithmetic.subtract),
      "typewriter.number.multiply" => _arithmetic(values, _Arithmetic.multiply),
      "typewriter.number.divide" => _arithmetic(values, _Arithmetic.divide),
      "typewriter.number.remainder" => _arithmetic(
        values,
        _Arithmetic.remainder,
      ),
      "typewriter.number.negate" => _arithmetic(values, _Arithmetic.negate),
      "typewriter.text.length" => skir.DataValue.wrapInteger(
        _text(values.single).runes.length.toString(),
      ),
      "typewriter.text.has_line_break" => _bool(
        _hasLineBreak(_text(values.single)),
      ),
      "typewriter.text.trim" => _string(_portableTrim(_text(values.single))),
      "typewriter.text.lower" => _string(_text(values.single).toLowerCase()),
      "typewriter.text.upper" => _string(_text(values.single).toUpperCase()),
      "typewriter.text.title" => _string(_titleCase(_text(values.single))),
      "typewriter.text.replace" => _string(
        _boundedLiteralReplace(
          _text(values[0]),
          _text(values[1]),
          _text(values[2]),
          _consumeStep,
        ),
      ),
      "typewriter.text.split" => _split(values, _consumeCollectionItems),
      "typewriter.text.join" => _string(
        _boundedJoin(
          _collectionValues(values[0]).map(_text),
          _text(values[1]),
          _consumeStep,
        ),
      ),
      "typewriter.text.substring" => _substring(values),
      "typewriter.text.contains" => _bool(
        _text(values[0]).contains(_text(values[1])),
      ),
      "typewriter.text.starts_with" => _bool(
        _text(values[0]).startsWith(_text(values[1])),
      ),
      "typewriter.text.ends_with" => _bool(
        _text(values[0]).endsWith(_text(values[1])),
      ),
      "typewriter.text.interpolate" => _string(
        _boundedInterpolate(values, _consumeStep),
      ),
      "typewriter.regex.matches" => _bool(
        _regex(values).containsMatchIn(_text(values.first), _consumeStep),
      ),
      "typewriter.regex.capture" => _capture(values),
      "typewriter.regex.replace" => _replaceRegex(values),
      "typewriter.collection.size" => _integerValue(_size(values.single)),
      "typewriter.collection.access" => _collectionAccess(values),
      "typewriter.collection.contains" => _bool(_collectionContains(values)),
      "typewriter.color.with_alpha" => _withAlpha(values),
      "typewriter.rule.one_of" => _bool(
        values
            .skip(1)
            .any((value) => _canonical(value) == _canonical(values.first)),
      ),
      "typewriter.rule.nonEmpty" => _bool(_size(values.single) > 0),
      "typewriter.rule.nonBlank" => _bool(
        _portableTrim(_text(values.single)).isNotEmpty,
      ),
      "typewriter.rule.minimumLength" => _bool(
        _size(values[0]) >= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.maximumLength" => _bool(
        _size(values[0]) <= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.lengthBetween" => _bool(
        _betweenInt(
          _size(values[0]),
          _integer(values[1]).toInt(),
          _integer(values[2]).toInt(),
        ),
      ),
      "typewriter.rule.minimumLines" => _bool(
        _lineCount(_text(values.first)) >= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.maximumLines" => _bool(
        _lineCount(_text(values.first)) <= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.singleLine" => _bool(
        !_hasLineBreak(_text(values.single)),
      ),
      "typewriter.rule.regex" => _bool(
        _regex(values).matches(_text(values.first), _consumeStep),
      ),
      "typewriter.rule.startsWith" => _bool(
        _text(values[0]).startsWith(_text(values[1])),
      ),
      "typewriter.rule.endsWith" => _bool(
        _text(values[0]).endsWith(_text(values[1])),
      ),
      "typewriter.rule.minimum" => _bool(
        _booleanValue(values[2])
            ? _compareNumbers(values) >= 0
            : _compareNumbers(values) > 0,
      ),
      "typewriter.rule.maximum" => _bool(
        _booleanValue(values[2])
            ? _compareNumbers(values) <= 0
            : _compareNumbers(values) < 0,
      ),
      "typewriter.rule.between" => _bool(
        _compareNumber(values[0], values[1]) >= 0 &&
            _compareNumber(values[0], values[2]) <= 0,
      ),
      "typewriter.rule.positive" => _bool(
        _number(values[0]).compareTo(_Decimal.zero) > 0,
      ),
      "typewriter.rule.nonNegative" => _bool(
        _number(values[0]).compareTo(_Decimal.zero) >= 0,
      ),
      "typewriter.rule.multipleOf" => _multipleOf(values),
      "typewriter.rule.maximumScale" => _bool(
        _number(values[0]).normalizedScale <= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.minimumItems" => _bool(
        _size(values[0]) >= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.maximumItems" => _bool(
        _size(values[0]) <= _integer(values[1]).toInt(),
      ),
      "typewriter.rule.itemsBetween" => _bool(
        _betweenInt(
          _size(values[0]),
          _integer(values[1]).toInt(),
          _integer(values[2]).toInt(),
        ),
      ),
      "typewriter.rule.unique" => throw StateError(
        "Unique availability is evaluated before operations",
      ),
      "typewriter.rule.notNull" => _bool(values.single != skir.DataValue.null_),
      "typewriter.rule.notBefore" => _bool(
        _timestamp(values[0]).compareTo(_timestamp(values[1])) >= 0,
      ),
      "typewriter.rule.notAfter" => _bool(
        _timestamp(values[0]).compareTo(_timestamp(values[1])) <= 0,
      ),
      "typewriter.rule.opaque" => _bool(
        ((_integer(values.single) >> 24) & BigInt.from(255)) ==
            BigInt.from(255),
      ),
      _ => throw StateError("Registered operation $id is not implemented"),
    };
  }

  skir.DataValue _arithmetic(
    List<skir.DataValue> values,
    _Arithmetic operation,
  ) {
    final unwrapped = values.map(_unwrap).toList(growable: false);
    if (unwrapped.every((value) => value is skir.DataValue_integerWrapper)) {
      final operands = unwrapped
          .cast<skir.DataValue_integerWrapper>()
          .map((value) => BigInt.parse(value.value))
          .toList();
      var result = operands.first;
      if (operation == _Arithmetic.negate) result = -result;
      for (final operand in operands.skip(1)) {
        if ((operation == _Arithmetic.divide ||
                operation == _Arithmetic.remainder) &&
            operand == BigInt.zero) {
          throw const _ExpressionFailure(
            "division_by_zero",
            "Division by zero is not defined",
          );
        }
        result = switch (operation) {
          _Arithmetic.add => result + operand,
          _Arithmetic.subtract => result - operand,
          _Arithmetic.multiply => result * operand,
          _Arithmetic.divide => result ~/ operand,
          _Arithmetic.remainder => result.remainder(operand),
          _Arithmetic.negate => result,
        };
      }
      return skir.DataValue.wrapInteger(result.toString());
    }
    if (unwrapped.every((value) => value is skir.DataValue_decimalWrapper)) {
      final operands = unwrapped
          .cast<skir.DataValue_decimalWrapper>()
          .map((value) => _Decimal.parse(value.value))
          .toList();
      var result = operands.first;
      if (operation == _Arithmetic.negate) result = -result;
      for (final operand in operands.skip(1)) {
        result = switch (operation) {
          _Arithmetic.add => result + operand,
          _Arithmetic.subtract => result - operand,
          _Arithmetic.multiply => result * operand,
          _Arithmetic.divide => result.divide(operand),
          _Arithmetic.remainder => result.remainder(operand),
          _Arithmetic.negate => result,
        };
      }
      return skir.DataValue.wrapDecimal(result.canonical);
    }
    if (unwrapped.every((value) => value is skir.DataValue_floatWrapper)) {
      final operands = unwrapped
          .cast<skir.DataValue_floatWrapper>()
          .map((value) => value.value)
          .toList();
      var result = operands.first;
      if (operation == _Arithmetic.negate) result = -result;
      for (final operand in operands.skip(1)) {
        result = switch (operation) {
          _Arithmetic.add => result + operand,
          _Arithmetic.subtract => result - operand,
          _Arithmetic.multiply => result * operand,
          _Arithmetic.divide => result / operand,
          _Arithmetic.remainder => result.remainder(operand),
          _Arithmetic.negate => result,
        };
      }
      if (!result.isFinite) {
        throw const _ExpressionFailure(
          "nonfinite_number",
          "Floating point arithmetic produced a nonfinite value",
        );
      }
      return skir.DataValue.wrapFloat(result);
    }
    throw const _ExpressionFailure(
      "numeric_family_mismatch",
      "Arithmetic operands must use one numeric representation",
    );
  }

  skir.DataValue _substring(List<skir.DataValue> values) {
    final runes = _text(values.first).runes.toList(growable: false);
    final start = _integer(values[1]).toInt();
    final end = values.length == 2 ? runes.length : _integer(values[2]).toInt();
    if (start < 0 || end < start || end > runes.length) {
      throw const _ExpressionFailure(
        "substring_range",
        "The substring range is invalid",
      );
    }
    return skir.DataValue.wrapStringValue(
      String.fromCharCodes(runes.sublist(start, end)),
    );
  }

  skir.DataValue _capture(List<skir.DataValue> values) {
    final input = _text(values.first);
    final matcher = _regex(values);
    final match = matcher.find(input, _consumeStep);
    if (match == null) {
      throw const _ExpressionFailure(
        "regex_no_match",
        "The regular expression did not match",
      );
    }
    final group = _integer(values[2]).toInt();
    if (group < 0 || group > matcher.groupCount) {
      throw const _ExpressionFailure(
        "regex_group_absent",
        "The regular expression capture group is absent",
      );
    }
    final captured = match.group(input, group);
    if (captured == null) {
      throw const _ExpressionFailure(
        "regex_group_absent",
        "The regular expression capture group is absent",
      );
    }
    return skir.DataValue.wrapStringValue(captured);
  }

  skir.DataValue _replaceRegex(List<skir.DataValue> values) {
    try {
      return skir.DataValue.wrapStringValue(
        _regex(values)
            .replace(_text(values[0]), _text(values[2]), _consumeStep),
      );
    } on PortableRegexCompileFailure {
      throw const _ExpressionFailure(
        "invalid_regex_replacement",
        "The regular expression replacement is invalid",
      );
    }
  }

  skir.DataValue _withAlpha(List<skir.DataValue> values) {
    final color = _integer(values[0]);
    final alpha = _integer(values[1]).toInt();
    if (alpha < 0 || alpha > 255) {
      throw const _ExpressionFailure(
        "color_alpha_range",
        "Color alpha must be between zero and 255",
      );
    }
    final replaced =
        (color & BigInt.from(0x00ffffff)) | (BigInt.from(alpha) << 24);
    return skir.DataValue.wrapInteger(replaced.toString());
  }

  PortableRegexMatcher _regex(List<skir.DataValue> values) {
    final input = _text(values.first);
    final pattern = _text(values[1]);
    if (input.length > 16384) {
      throw const _ExpressionFailure(
        "regex_limit",
        "The regular expression input exceeds its limit",
      );
    }
    final normalization = pattern.normalizePortableRegex();
    final normalized = switch (normalization) {
      PortableRegexReady(:final pattern) => pattern,
      PortableRegexInvalid(:final reason) => throw _ExpressionFailure(
        "invalid_regex",
        reason,
      ),
      PortableRegexUnsupported(:final reason) => throw _ExpressionFailure(
        "unsupported_regex_pattern",
        reason,
      ),
    };
    try {
      return PortableRegexMatcher.compile(normalized);
    } on PortableRegexCompileFailure {
      throw const _ExpressionFailure(
        "invalid_regex",
        "The regular expression pattern is invalid",
      );
    }
  }

  _Evaluation _unique(skir.DataValue value) {
    final keys = <String>{};
    var unfinished = false;
    for (final item in _collectionValues(value)) {
      if (_containsUnfilled(item)) {
        unfinished = true;
        continue;
      }
      if (!keys.add(_canonical(item))) {
        return _Available(skir.DataValue.wrapBoolean(false));
      }
    }
    return unfinished
        ? const _Unavailable()
        : _Available(skir.DataValue.wrapBoolean(true));
  }
}

final class _CollectionEntry {
  const _CollectionEntry(this.id, this.value);

  final skir.ItemId id;
  final skir.DataValue value;
}

List<_CollectionEntry> _collectionEntries(skir.DataValue value) =>
    switch (_unwrap(value)) {
      skir.DataValue_listValueWrapper(:final value) ||
      skir.DataValue_setValueWrapper(:final value) => [
        for (final item in value.items) _CollectionEntry(item.id, item.value),
      ],
      skir.DataValue_mapValueWrapper(:final value) => [
        for (final row in value.rows)
          _CollectionEntry(
            row.id,
            skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(name: "key", value: row.key),
                skir.FieldValue(name: "value", value: row.value),
              ],
            ),
          ),
      ],
      _ => throw const _ExpressionFailure(
        "expected_collection",
        "The expression value is not a collection",
      ),
    };

skir.DataValue _reorderCollection(
  skir.DataValue value,
  List<_CollectionEntry> entries,
) => switch (value) {
  skir.DataValue_namedWrapper(value: final named) => skir.DataValue.createNamed(
    actualType: named.actualType,
    payload: _reorderCollection(named.payload, entries),
  ),
  skir.DataValue_listValueWrapper(value: final list) =>
    skir.DataValue.createListValue(items: _orderedItems(list.items, entries)),
  skir.DataValue_setValueWrapper(value: final set) =>
    skir.DataValue.createSetValue(items: _orderedItems(set.items, entries)),
  skir.DataValue_mapValueWrapper(value: final map) =>
    skir.DataValue.createMapValue(rows: _orderedRows(map.rows, entries)),
  _ => throw const _ExpressionFailure(
    "expected_collection",
    "The expression value is not a collection",
  ),
};

List<skir.ListItem> _orderedItems(
  Iterable<skir.ListItem> source,
  List<_CollectionEntry> entries,
) {
  final byId = {for (final item in source) item.id: item};
  return [
    for (final entry in entries)
      byId[entry.id] ??
          (throw const _ExpressionFailure(
            "collection_identity_absent",
            "The collection item identity is absent",
          )),
  ];
}

List<skir.MapRow> _orderedRows(
  Iterable<skir.MapRow> source,
  List<_CollectionEntry> entries,
) {
  final byId = {for (final row in source) row.id: row};
  return [
    for (final entry in entries)
      byId[entry.id] ??
          (throw const _ExpressionFailure(
            "collection_identity_absent",
            "The collection row identity is absent",
          )),
  ];
}

skir.ValueLocation _entryLocation(skir.ValueLocation base, skir.ItemId id) =>
    _appendLocation(
      base,
      skir.ValuePath(segments: [skir.PathSegment.createItem(id: id)]),
    );

skir.ValueLocation _appendLocation(
  skir.ValueLocation base,
  skir.ValuePath suffix,
) => skir.ValueLocation(
  resource: base.resource,
  path: skir.ValuePath(segments: [...base.path.segments, ...suffix.segments]),
);

int _nonnegativeCount(skir.DataValue value) {
  final count = _integer(value);
  if (count.isNegative) {
    throw const _ExpressionFailure(
      "negative_collection_count",
      "A collection count cannot be negative",
    );
  }
  return count.toInt();
}

List<_CollectionEntry> _distinctEntriesByResult(
  List<(_CollectionEntry, skir.DataValue)> results,
) {
  final seen = <String>{};
  return [
    for (final result in results)
      if (seen.add(_canonical(result.$2))) result.$1,
  ];
}

List<_CollectionEntry> _sortEntriesByResult(
  List<(_CollectionEntry, skir.DataValue)> results, {
  required bool descending,
}) {
  final sorted = [...results]
    ..sort((left, right) {
      final comparison = _comparePortable(left.$2, right.$2);
      return descending ? -comparison : comparison;
    });
  return sorted.map((result) => result.$1).toList();
}

skir.DataValue _groupByKey(List<(_CollectionEntry, skir.DataValue)> results) {
  final groups = <String, (skir.DataValue, List<_CollectionEntry>)>{};
  for (final result in results) {
    final key = _canonical(result.$2);
    final group = groups[key];
    if (group == null) {
      groups[key] = (result.$2, [result.$1]);
    } else {
      group.$2.add(result.$1);
    }
  }
  return skir.DataValue.createMapValue(
    rows: [
      for (final group in groups.values)
        skir.MapRow(
          id: group.$2.first.id,
          key: group.$1,
          value: skir.DataValue.createListValue(
            items: [
              for (final entry in group.$2)
                skir.ListItem(id: entry.id, value: entry.value),
            ],
          ),
        ),
    ],
  );
}

skir.DataValue _flatMap(
  List<(_CollectionEntry, skir.DataValue)> results,
) => skir.DataValue.createListValue(
  items: [
    for (final result in results)
      for (final inner in _collectionEntries(result.$2))
        skir.ListItem(
          id: skir.ItemId(
            value:
                "${result.$1.id.value.length}:${result.$1.id.value}${inner.id.value.length}:${inner.id.value}",
          ),
          value: inner.value,
        ),
  ],
);

int _comparePortable(skir.DataValue left, skir.DataValue right) {
  final first = _unwrap(left);
  final second = _unwrap(right);
  if (first is skir.DataValue_integerWrapper ||
      first is skir.DataValue_floatWrapper ||
      first is skir.DataValue_decimalWrapper) {
    return _compareNumber(first, second);
  }
  return switch ((first, second)) {
    (
      skir.DataValue_stringValueWrapper(value: final left),
      skir.DataValue_stringValueWrapper(value: final right),
    ) =>
      _compareCodePoints(left, right),
    (
      skir.DataValue_booleanWrapper(value: final left),
      skir.DataValue_booleanWrapper(value: final right),
    ) =>
      left == right ? 0 : (left ? 1 : -1),
    (
      skir.DataValue_timestampWrapper(value: final left),
      skir.DataValue_timestampWrapper(value: final right),
    ) =>
      left.compareTo(right),
    (
      skir.DataValue_durationWrapper(value: final left),
      skir.DataValue_durationWrapper(value: final right),
    ) =>
      left.value.milliseconds.compareTo(right.value.milliseconds),
    _ => throw const _ExpressionFailure(
      "collection_value_not_ordered",
      "The collection key does not have portable ordering semantics",
    ),
  };
}

int _compareCodePoints(String left, String right) {
  final first = left.runes.iterator;
  final second = right.runes.iterator;
  while (first.moveNext() && second.moveNext()) {
    final comparison = first.current.compareTo(second.current);
    if (comparison != 0) return comparison;
  }
  return left.runes.length.compareTo(right.runes.length);
}

void _validateOperationArity(String id, int count) {
  if (!authoredPortableOperationIds.contains(id)) {
    throw _ExpressionFailure(
      "unknown_operation",
      "Unknown expression operation $id",
    );
  }
  final (minimum, maximum) = switch (id) {
    "typewriter.value.is_null" ||
    "typewriter.boolean.not" ||
    "typewriter.number.negate" ||
    "typewriter.text.length" ||
    "typewriter.text.has_line_break" ||
    "typewriter.text.trim" ||
    "typewriter.text.lower" ||
    "typewriter.text.upper" ||
    "typewriter.text.title" ||
    "typewriter.collection.size" ||
    "typewriter.rule.nonEmpty" ||
    "typewriter.link.target" ||
    "typewriter.rule.nonBlank" ||
    "typewriter.rule.singleLine" ||
    "typewriter.rule.positive" ||
    "typewriter.rule.nonNegative" ||
    "typewriter.rule.unique" ||
    "typewriter.rule.notNull" ||
    "typewriter.rule.opaque" => (1, 1),
    "typewriter.value.eq" ||
    "typewriter.value.neq" ||
    "typewriter.record.field" ||
    "typewriter.number.gt" ||
    "typewriter.number.gte" ||
    "typewriter.number.lt" ||
    "typewriter.number.lte" ||
    "typewriter.text.split" ||
    "typewriter.text.join" ||
    "typewriter.text.contains" ||
    "typewriter.text.starts_with" ||
    "typewriter.text.ends_with" ||
    "typewriter.regex.matches" ||
    "typewriter.collection.access" ||
    "typewriter.collection.contains" ||
    "typewriter.color.with_alpha" ||
    "typewriter.rule.minimumLength" ||
    "typewriter.rule.maximumLength" ||
    "typewriter.rule.minimumLines" ||
    "typewriter.rule.maximumLines" ||
    "typewriter.rule.regex" ||
    "typewriter.rule.startsWith" ||
    "typewriter.rule.endsWith" ||
    "typewriter.rule.multipleOf" ||
    "typewriter.rule.maximumScale" ||
    "typewriter.rule.minimumItems" ||
    "typewriter.rule.maximumItems" ||
    "typewriter.rule.notBefore" ||
    "typewriter.rule.notAfter" => (2, 2),
    "typewriter.text.replace" ||
    "typewriter.regex.capture" ||
    "typewriter.regex.replace" ||
    "typewriter.rule.lengthBetween" ||
    "typewriter.rule.minimum" ||
    "typewriter.rule.maximum" ||
    "typewriter.rule.between" ||
    "typewriter.rule.itemsBetween" => (3, 3),
    "typewriter.text.substring" => (2, 3),
    "typewriter.number.add" ||
    "typewriter.number.subtract" ||
    "typewriter.number.multiply" ||
    "typewriter.number.divide" ||
    "typewriter.number.remainder" ||
    "typewriter.rule.one_of" => (2, null),
    "typewriter.text.interpolate" => (0, null),
    _ => throw StateError("Registered operation $id has no arity"),
  };
  if (count < minimum || (maximum != null && count > maximum)) {
    throw _ExpressionFailure(
      "operation_arity",
      "Expression operation $id received $count arguments",
    );
  }
}

enum _Arithmetic { add, subtract, multiply, divide, remainder, negate }

skir.DataValue _bool(bool value) => skir.DataValue.wrapBoolean(value);

skir.DataValue _string(String value) => skir.DataValue.wrapStringValue(value);

skir.DataValue _integerValue(int value) =>
    skir.DataValue.wrapInteger(value.toString());

skir.DataValue _recordField(List<skir.DataValue> values) {
  final record = switch (_unwrap(values[0])) {
    skir.DataValue_recordWrapper(:final value) => value,
    _ => null,
  };
  if (record == null) {
    throw const _ExpressionFailure(
      "expected_record",
      "The expression value is not a record",
    );
  }
  final name = _text(values[1]);
  final field = record.fields.where((field) => field.name == name).firstOrNull;
  if (field == null) {
    throw const _ExpressionFailure(
      "record_field_absent",
      "The record field is absent",
    );
  }
  return field.value;
}

int _compareNumbers(List<skir.DataValue> values) =>
    _compareNumber(values[0], values[1]);

int _compareNumber(skir.DataValue left, skir.DataValue right) =>
    _number(left).compareTo(_number(right));

_Decimal _number(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_integerWrapper(:final value) => _Decimal.parse(value),
  skir.DataValue_decimalWrapper(:final value) => _Decimal.parse(value),
  skir.DataValue_floatWrapper(:final value) => _Decimal.parse(value.toString()),
  _ => throw const _ExpressionFailure(
    "expected_number",
    "The expression value is not numeric",
  ),
};

skir.DataValue _split(
  List<skir.DataValue> values,
  void Function(int) consumeItems,
) {
  final source = _text(values[0]);
  final separator = _text(values[1]);
  consumeItems(_literalSplitItemCount(source, separator));
  final parts = separator.isEmpty
      ? [for (final codePoint in source.runes) String.fromCharCode(codePoint)]
      : source.split(separator);
  return skir.DataValue.createListValue(
    items: [
      for (var index = 0; index < parts.length; index++)
        skir.ListItem(
          id: skir.ItemId(value: "split.$index"),
          value: _string(parts[index]),
        ),
    ],
  );
}

String _boundedLiteralReplace(
  String source,
  String target,
  String replacement,
  void Function() consumeStep,
) {
  if (target.isEmpty) {
    final sourceCodePoints = source.runes.length;
    for (var index = 0; index <= sourceCodePoints; index++) {
      _chargeCodePoints(replacement, consumeStep);
    }
    for (var index = 0; index < sourceCodePoints; index++) {
      consumeStep();
    }
    final result = StringBuffer(replacement);
    for (final codePoint in source.runes) {
      result
        ..writeCharCode(codePoint)
        ..write(replacement);
    }
    return result.toString();
  }
  var copiedUntil = 0;
  while (true) {
    final match = source.indexOf(target, copiedUntil);
    if (match < 0) {
      _chargeCodePointRange(source, copiedUntil, source.length, consumeStep);
      break;
    }
    _chargeCodePointRange(source, copiedUntil, match, consumeStep);
    _chargeCodePoints(replacement, consumeStep);
    copiedUntil = match + target.length;
  }
  return source.replaceAll(target, replacement);
}

String _boundedJoin(
  Iterable<String> values,
  String separator,
  void Function() consumeStep,
) {
  var index = 0;
  for (final value in values) {
    if (index > 0) _chargeCodePoints(separator, consumeStep);
    _chargeCodePoints(value, consumeStep);
    index++;
  }
  return values.join(separator);
}

String _boundedInterpolate(
  List<skir.DataValue> values,
  void Function() consumeStep,
) {
  final rendered = values
      .map(portableExpressionDisplayText)
      .toList(growable: false);
  for (final value in rendered) {
    _chargeCodePoints(value, consumeStep);
  }
  return rendered.join();
}

int _literalSplitItemCount(String source, String separator) {
  if (separator.isEmpty) return source.runes.length;
  var count = 1;
  var from = 0;
  while (true) {
    final match = source.indexOf(separator, from);
    if (match < 0) return count;
    count++;
    from = match + separator.length;
  }
}

void _chargeCodePoints(String value, void Function() consumeStep) {
  for (final _ in value.runes) {
    consumeStep();
  }
}

void _chargeCodePointRange(
  String value,
  int start,
  int end,
  void Function() consumeStep,
) {
  var offset = start;
  while (offset < end) {
    final first = value.codeUnitAt(offset++);
    if (first >= 0xD800 &&
        first <= 0xDBFF &&
        offset < end &&
        value.codeUnitAt(offset) >= 0xDC00 &&
        value.codeUnitAt(offset) <= 0xDFFF) {
      offset++;
    }
    consumeStep();
  }
}

List<skir.DataValue> _collectionValues(skir.DataValue value) =>
    switch (_unwrap(value)) {
      skir.DataValue_listValueWrapper(:final value) => [
        for (final item in value.items) item.value,
      ],
      skir.DataValue_setValueWrapper(:final value) => [
        for (final item in value.items) item.value,
      ],
      skir.DataValue_mapValueWrapper(:final value) => [
        for (final row in value.rows) row.value,
      ],
      _ => throw const _ExpressionFailure(
        "expected_collection",
        "The expression value is not a collection",
      ),
    };

skir.DataValue _collectionAccess(List<skir.DataValue> values) {
  final collection = _unwrap(values[0]);
  final key = _unwrap(values[1]);
  final result = switch ((collection, key)) {
    (
      skir.DataValue_listValueWrapper(value: final list),
      skir.DataValue_integerWrapper(value: final index),
    ) =>
      list.items.elementAtOrNull(int.parse(index))?.value,
    (skir.DataValue_mapValueWrapper(value: final map), _) =>
      map.rows
          .where((row) => _canonical(row.key) == _canonical(key))
          .firstOrNull
          ?.value,
    (
      skir.DataValue_recordWrapper(value: final record),
      skir.DataValue_stringValueWrapper(value: final field),
    ) =>
      record.fields.where((entry) => entry.name == field).firstOrNull?.value,
    (
      skir.DataValue_stringValueWrapper(value: final text),
      skir.DataValue_integerWrapper(value: final index),
    ) =>
      text.runes.elementAtOrNull(int.parse(index)) == null
          ? null
          : _string(
              String.fromCharCode(text.runes.elementAt(int.parse(index))),
            ),
    _ => null,
  };
  if (result == null) {
    throw const _ExpressionFailure(
      "collection_key_absent",
      "The collection key or index is absent",
    );
  }
  return result;
}

bool _collectionContains(List<skir.DataValue> values) {
  final collection = _unwrap(values[0]);
  final expected = _unwrap(values[1]);
  final key = _canonical(expected);
  return switch (collection) {
    skir.DataValue_listValueWrapper(:final value) => value.items.any(
      (item) => _canonical(item.value) == key,
    ),
    skir.DataValue_setValueWrapper(:final value) => value.items.any(
      (item) => _canonical(item.value) == key,
    ),
    skir.DataValue_mapValueWrapper(:final value) => value.rows.any(
      (row) => _canonical(row.key) == key,
    ),
    skir.DataValue_recordWrapper(:final value)
        when expected is skir.DataValue_stringValueWrapper =>
      value.fields.any((field) => field.name == expected.value),
    _ => throw const _ExpressionFailure(
      "expected_collection",
      "The expression value is not a collection",
    ),
  };
}

int _size(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_stringValueWrapper(:final value) => value.runes.length,
  skir.DataValue_bytesWrapper(:final value) => value.length,
  skir.DataValue_listValueWrapper(:final value) => value.items.length,
  skir.DataValue_setValueWrapper(:final value) => value.items.length,
  skir.DataValue_mapValueWrapper(:final value) => value.rows.length,
  skir.DataValue_recordWrapper(:final value) => value.fields.length,
  _ => throw const _ExpressionFailure(
    "expected_sized_value",
    "The expression value has no size",
  ),
};

/// Formats a value for presentation labels and expression interpolation.
///
/// Named values use their payload, and empty values have no display text.
String portableExpressionDisplayText(skir.DataValue value) {
  final unwrapped = _unwrap(value);
  if (unwrapped == skir.DataValue.unfilled ||
      unwrapped == skir.DataValue.null_ ||
      unwrapped == skir.DataValue.unit) {
    return "";
  }
  return switch (unwrapped) {
    skir.DataValue_booleanWrapper(:final value) => value.toString(),
    skir.DataValue_integerWrapper(:final value) => value,
    skir.DataValue_floatWrapper(:final value) => value.toString(),
    skir.DataValue_decimalWrapper(:final value) => value,
    skir.DataValue_stringValueWrapper(:final value) => value,
    skir.DataValue_bytesWrapper(:final value) => "${value.length} bytes",
    skir.DataValue_timestampWrapper(:final value) => value.toIso8601String(),
    skir.DataValue_durationWrapper(:final value) => value.toString(),
    skir.DataValue_enumCaseWrapper(:final value) => value,
    skir.DataValue_listValueWrapper(:final value) =>
      "${value.items.length} items",
    skir.DataValue_setValueWrapper(:final value) =>
      "${value.items.length} items",
    skir.DataValue_mapValueWrapper(:final value) =>
      "${value.rows.length} entries",
    skir.DataValue_recordWrapper() => "record",
    skir.DataValue_linkWrapper(:final value) => value.target.resource.value,
    _ => "",
  };
}

bool _hasLineBreak(String value) => value.runes.any(
  (rune) => rune == 10 || rune == 13 || rune == 0x2028 || rune == 0x2029,
);

String _titleCase(String value) => value
    .split(RegExp(r"\s+"))
    .map(
      (word) => word.isEmpty
          ? word
          : "${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}",
    )
    .join(" ");

String _portableTrim(String value) {
  var start = 0;
  var end = value.length;
  while (start < end && _isPortableWhitespace(value.codeUnitAt(start))) {
    start++;
  }
  while (end > start && _isPortableWhitespace(value.codeUnitAt(end - 1))) {
    end--;
  }
  return value.substring(start, end);
}

bool _isPortableWhitespace(int value) =>
    (value >= 0x0009 && value <= 0x000d) ||
    value == 0x0020 ||
    value == 0x0085 ||
    value == 0x00a0 ||
    value == 0x1680 ||
    (value >= 0x2000 && value <= 0x200a) ||
    value == 0x2028 ||
    value == 0x2029 ||
    value == 0x202f ||
    value == 0x205f ||
    value == 0x3000 ||
    value == 0xfeff;

bool _betweenInt(int value, int minimum, int maximum) =>
    value >= minimum && value <= maximum;

skir.DataValue _multipleOf(List<skir.DataValue> values) {
  final divisor = _number(values[1]);
  if (divisor.compareTo(_Decimal.zero) == 0) return _bool(false);
  return _bool(_number(values[0]).remainder(divisor).isZero);
}

DateTime _timestamp(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_timestampWrapper(:final value) => value,
  _ => throw const _ExpressionFailure(
    "expected_timestamp",
    "The expression value is not a timestamp",
  ),
};

sealed class _Evaluation {
  const _Evaluation();
}

final class _Available extends _Evaluation {
  const _Available(this.value);

  final skir.DataValue value;
}

final class _Unavailable extends _Evaluation {
  const _Unavailable();
}

final class _ExpressionFailure implements Exception {
  const _ExpressionFailure(this.code, this.message);

  final String code;
  final String message;
}

skir.DataValue _unwrap(skir.DataValue value) {
  var current = value;
  var depth = 0;
  while (current is skir.DataValue_namedWrapper) {
    depth++;
    if (depth > _maximumAuthoredValueDepth) {
      throw const _ExpressionFailure(
        "value_depth_limit",
        "The authored value exceeded its depth limit",
      );
    }
    current = current.value.payload;
  }
  return current;
}

bool _booleanValue(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_booleanWrapper(:final value) => value,
  _ => throw const _ExpressionFailure(
    "expected_boolean",
    "The expression value is not Boolean",
  ),
};

BigInt _integer(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_integerWrapper(:final value) => BigInt.parse(value),
  _ => throw const _ExpressionFailure(
    "expected_integer",
    "The expression value is not an integer",
  ),
};

String _text(skir.DataValue value) => switch (_unwrap(value)) {
  skir.DataValue_stringValueWrapper(:final value) => value,
  _ => throw const _ExpressionFailure(
    "expected_text",
    "The expression value is not text",
  ),
};

int _lineCount(String value) {
  if (value.isEmpty) return 0;
  var lines = 1;
  for (var index = 0; index < value.length; index++) {
    final unit = value.codeUnitAt(index);
    if (unit == 13) {
      lines++;
      if (index + 1 < value.length && value.codeUnitAt(index + 1) == 10) {
        index++;
      }
    } else if (unit == 10 || unit == 0x2028 || unit == 0x2029) {
      lines++;
    }
  }
  return lines;
}

String _canonical(skir.DataValue value, [int depth = 0]) {
  if (depth > _maximumAuthoredValueDepth) {
    throw const _ExpressionFailure(
      "value_depth_limit",
      "The authored value exceeded its depth limit",
    );
  }
  if (value == skir.DataValue.unfilled) return "unfilled";
  if (value == skir.DataValue.null_) return "null";
  if (value == skir.DataValue.unit) return "unit";
  return switch (value) {
    skir.DataValue_booleanWrapper(:final value) => "boolean:$value",
    skir.DataValue_integerWrapper(:final value) =>
      "integer:${BigInt.parse(value)}",
    skir.DataValue_floatWrapper(:final value) => "float:${_floatBits(value)}",
    skir.DataValue_decimalWrapper(:final value) =>
      "decimal:${_Decimal.parse(value).canonical}",
    skir.DataValue_stringValueWrapper(:final value) =>
      "text:${value.length}:$value",
    skir.DataValue_bytesWrapper(:final value) => "bytes:${value.toBase16()}",
    skir.DataValue_timestampWrapper(:final value) =>
      "timestamp:${value.toUtc().microsecondsSinceEpoch}",
    skir.DataValue_durationWrapper(:final value) =>
      "duration:${value.value.milliseconds}",
    skir.DataValue_enumCaseWrapper(:final value) =>
      "enum:${value.length}:$value",
    skir.DataValue_recordWrapper(:final value) => _framed(
      "record",
      value.fields
          .map(
            (field) => _framed("field", [
              field.name,
              _canonical(field.value, depth + 1),
            ]),
          )
          .toList()
        ..sort(),
    ),
    skir.DataValue_namedWrapper(:final value) => _framed("named", [
      _namedTypeKey(value.actualType, depth + 1),
      _canonical(value.payload, depth + 1),
    ]),
    skir.DataValue_listValueWrapper(:final value) => _framed(
      "list",
      value.items.map((item) => _canonical(item.value, depth + 1)),
    ),
    skir.DataValue_setValueWrapper(:final value) => _framed(
      "set",
      value.items.map((item) => _canonical(item.value, depth + 1)).toList()
        ..sort(),
    ),
    skir.DataValue_mapValueWrapper(:final value) => _framed(
      "map",
      value.rows
          .map(
            (row) => _framed("row", [
              _canonical(row.key, depth + 1),
              _canonical(row.value, depth + 1),
            ]),
          )
          .toList()
        ..sort(),
    ),
    skir.DataValue_linkWrapper(:final value) => _framed("link", [
      value.endpoint.value,
      value.target.resource.value,
      _pathKey(value.target.opposite),
    ]),
    _ => "unknown",
  };
}

String canonicalAuthoredValue(skir.DataValue value) => _canonical(value);

String _framed(String kind, Iterable<String> parts) {
  final values = parts.toList(growable: false);
  return "$kind:${values.length}:${values.map((part) => "${part.length}:$part").join()}";
}

String _floatBits(double value) {
  final data = ByteData(8)..setFloat64(0, value);
  return data.getUint64(0).toRadixString(16).padLeft(16, "0");
}

String _namedTypeKey(skir.NamedTypeUse value, [int depth = 0]) {
  _guardAuthoredValueDepth(depth);
  return _framed("named_type", [
    _definitionKey(value.definition),
    _framed(
      "arguments",
      value.arguments.map((argument) => _typeUseKey(argument, depth + 1)),
    ),
  ]);
}

String _definitionKey(skir.TypeDefinitionId value) => _framed("definition", [
  _typeIdKey(value.typeId),
  value.revision.toString(),
]);

String _typeIdKey(skir.TypeId value) => switch (value) {
  skir.TypeId_declaredWrapper(:final value) => _framed("declared", [
    value.value,
  ]),
  skir.TypeId_qualifiedWrapper(:final value) => _framed("qualified", [
    value.namespace,
    value.name,
  ]),
  _ => "unknown_type_id",
};

String _typeUseKey(skir.TypeUse value, [int depth = 0]) {
  _guardAuthoredValueDepth(depth);
  return switch (value) {
    skir.TypeUse_namedWrapper(:final value) => _namedTypeKey(value, depth + 1),
    skir.TypeUse_nullableWrapper(:final value) => _framed("nullable", [
      _typeUseKey(value.value, depth + 1),
    ]),
    skir.TypeUse_scalarWrapper(:final value) => _framed("scalar", [
      _scalarKindKey(value),
    ]),
    _ => "unknown_type_use",
  };
}

void _guardAuthoredValueDepth(int depth) {
  if (depth > _maximumAuthoredValueDepth) {
    throw const _ExpressionFailure(
      "value_depth_limit",
      "The authored value exceeded its depth limit",
    );
  }
}

String _scalarKindKey(skir.ScalarKind value) => switch (value) {
  skir.ScalarKind_integerWrapper(:final value) =>
    "integer:${value.width.kind.name}",
  skir.ScalarKind_floatWrapper(:final value) =>
    "float:${value.width.kind.name}",
  _ => value.kind.name,
};

String _pathKey(skir.ValuePath? value) {
  if (value == null) return "absent";
  return _framed("path", value.segments.map(_pathSegmentKey));
}

String _pathSegmentKey(skir.PathSegment value) {
  if (value == skir.PathSegment.mapKey) return "map_key";
  if (value == skir.PathSegment.mapValue) return "map_value";
  return switch (value) {
    skir.PathSegment_fieldWrapper(:final value) => _framed("field", [
      value.name,
    ]),
    skir.PathSegment_itemWrapper(:final value) => _framed("item", [
      value.id.value,
    ]),
    _ => "unknown_path_segment",
  };
}

bool _containsUnfilled(skir.DataValue value, [int depth = 0]) {
  if (depth > _maximumAuthoredValueDepth) {
    throw const _ExpressionFailure(
      "value_depth_limit",
      "The authored value exceeded its depth limit",
    );
  }
  if (value == skir.DataValue.unfilled) return true;
  return switch (value) {
    skir.DataValue_namedWrapper(:final value) => _containsUnfilled(
      value.payload,
      depth + 1,
    ),
    skir.DataValue_recordWrapper(:final value) => value.fields.any(
      (field) => _containsUnfilled(field.value, depth + 1),
    ),
    skir.DataValue_listValueWrapper(:final value) ||
    skir.DataValue_setValueWrapper(
      :final value,
    ) => value.items.any((item) => _containsUnfilled(item.value, depth + 1)),
    skir.DataValue_mapValueWrapper(:final value) => value.rows.any(
      (row) =>
          _containsUnfilled(row.key, depth + 1) ||
          _containsUnfilled(row.value, depth + 1),
    ),
    _ => false,
  };
}

const _maximumAuthoredValueDepth = 512;

final class _Decimal {
  const _Decimal(this.unscaled, this.scale);

  factory _Decimal.parse(String source) {
    final match = RegExp(
      r"^([+-]?)([0-9]+)(?:\.([0-9]*))?(?:[eE]([+-]?[0-9]+))?$",
    ).firstMatch(source);
    if (match == null) {
      throw const _ExpressionFailure(
        "expected_number",
        "The expression value is not numeric",
      );
    }
    final fraction = match.group(3) ?? "";
    final exponent = int.tryParse(match.group(4) ?? "0");
    if (exponent == null) {
      throw const _ExpressionFailure(
        "expected_number",
        "The expression value is not numeric",
      );
    }
    var magnitude = BigInt.parse("${match.group(2)}$fraction");
    if (match.group(1) == "-") magnitude = -magnitude;
    final scale = fraction.length - exponent;
    return scale < 0
        ? _Decimal(magnitude * _tenPow(-scale), 0)
        : _Decimal(magnitude, scale);
  }

  static final zero = _Decimal(BigInt.zero, 0);

  final BigInt unscaled;
  final int scale;

  bool get isZero => unscaled == BigInt.zero;

  int get normalizedScale {
    var magnitude = unscaled;
    var current = scale;
    while (current > 0 && magnitude.remainder(BigInt.from(10)) == BigInt.zero) {
      magnitude ~/= BigInt.from(10);
      current--;
    }
    return current;
  }

  _Decimal operator +(_Decimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = unscaled * _tenPow(targetScale - scale);
    final right = other.unscaled * _tenPow(targetScale - other.scale);
    return _Decimal(left + right, targetScale);
  }

  _Decimal operator -(_Decimal other) => this + (-other);

  _Decimal operator -() => _Decimal(-unscaled, scale);

  _Decimal operator *(_Decimal other) =>
      _Decimal(unscaled * other.unscaled, scale + other.scale);

  _Decimal divide(_Decimal other) {
    if (other.isZero) {
      throw const _ExpressionFailure(
        "division_by_zero",
        "Division by zero is not defined",
      );
    }
    const precision = 34;
    final magnitudeExponent = _ratioExponent(
      unscaled.abs(),
      other.unscaled.abs(),
    );
    final valueExponent = magnitudeExponent + other.scale - scale;
    final targetScale = precision - 1 - valueExponent;
    final factor = other.scale - scale + targetScale;
    final numerator = factor >= 0 ? unscaled * _tenPow(factor) : unscaled;
    final denominator = factor >= 0
        ? other.unscaled
        : other.unscaled * _tenPow(-factor);
    var quotient = numerator ~/ denominator;
    final remainder = numerator.remainder(denominator).abs();
    final divisor = denominator.abs();
    final doubled = remainder * BigInt.from(2);
    if (doubled > divisor || (doubled == divisor && quotient.isOdd)) {
      final negative = numerator.isNegative != denominator.isNegative;
      quotient += negative ? -BigInt.one : BigInt.one;
    }
    return targetScale < 0
        ? _Decimal(quotient * _tenPow(-targetScale), 0)
        : _Decimal(quotient, targetScale);
  }

  _Decimal remainder(_Decimal other) {
    if (other.isZero) {
      throw const _ExpressionFailure(
        "division_by_zero",
        "Division by zero is not defined",
      );
    }
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = unscaled * _tenPow(targetScale - scale);
    final right = other.unscaled * _tenPow(targetScale - other.scale);
    return _Decimal(left.remainder(right), targetScale);
  }

  int compareTo(_Decimal other) {
    final targetScale = scale > other.scale ? scale : other.scale;
    final left = unscaled * _tenPow(targetScale - scale);
    final right = other.unscaled * _tenPow(targetScale - other.scale);
    return left.compareTo(right);
  }

  String get canonical {
    var magnitude = unscaled;
    var actualScale = scale;
    while (actualScale > 0 &&
        magnitude.remainder(BigInt.from(10)) == BigInt.zero) {
      magnitude ~/= BigInt.from(10);
      actualScale--;
    }
    final negative = magnitude.isNegative;
    final digits = magnitude.abs().toString().padLeft(actualScale + 1, "0");
    final value = actualScale == 0
        ? digits
        : "${digits.substring(0, digits.length - actualScale)}.${digits.substring(digits.length - actualScale)}";
    return negative ? "-$value" : value;
  }
}

int _ratioExponent(BigInt numerator, BigInt denominator) {
  final digitDifference =
      numerator.toString().length - denominator.toString().length;
  if (digitDifference >= 0) {
    return numerator >= denominator * _tenPow(digitDifference)
        ? digitDifference
        : digitDifference - 1;
  }
  return numerator * _tenPow(-digitDifference) >= denominator
      ? digitDifference
      : digitDifference - 1;
}

BigInt _tenPow(int exponent) {
  var value = BigInt.one;
  for (var index = 0; index < exponent; index++) {
    value *= BigInt.from(10);
  }
  return value;
}

skir.DataValue _linkTarget(skir.DataValue value) {
  if (_unwrap(value) case skir.DataValue_linkWrapper(:final value)) {
    return _string(value.target.resource.value);
  }
  throw const _ExpressionFailure(
    "expected_link",
    "The expression value is not a relationship link",
  );
}
