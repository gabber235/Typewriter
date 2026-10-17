import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "portable_expression.freezed.dart";
part "portable_expression_queries.dart";
part "portable_expression_model.dart";
part "portable_expression_scalars.dart";
part "canonical_read_models.dart";
part "canonical_read_models.generated.dart";

/// Evaluation outcome together with the lexical and resource paths observed.
/// Unavailable input remains distinct from an invalid expression or exhausted
/// budget so presentation can choose a fallback without hiding a failure.
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

/// Evaluates portable expression trees against captured lexical bindings.
///
/// Each [evaluate] call resets step, collection and read tracking. Boolean
/// operations, conditionals and fallbacks short circuit, so only executed reads
/// become witnesses. Missing bindings and unfilled paths produce unavailable
/// results; invalid operations and budget exhaustion produce typed failures.
/// Canonical resource queries require the checked contracts supplied by
/// [CheckedEditorCatalog.evaluateExpression].
final class PortableExpressionEvaluator {
  PortableExpressionEvaluator(
    Map<skir.ExpressionBindingId, skir.DataValue> bindings, {
    required this.budget,
    this.queries,
    this.queryContracts = const {},
  }) : _bindings = Map.unmodifiable({
         for (final entry in bindings.entries)
           entry.key: PortableExpressionBinding(value: entry.value),
       });

  PortableExpressionEvaluator.located(
    Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings, {
    required this.budget,
    this.queries,
    this.queryContracts = const {},
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
  final PortableExpressionQueries? queries;
  final Map<ExpressionOccurrence, CheckedQueryCall> queryContracts;
  List<int> _occurrence = const [];
  final Map<skir.ExpressionBindingId, PortableExpressionBinding> _bindings;
  final _frames = <List<PortableExpressionBinding>>[];
  final Set<PortableExpressionRead> _reads = {};
  var _steps = 0;
  var _collectionItems = 0;
  var _depth = 0;

  PortableExpressionResult evaluate(skir.ExpressionNode node) {
    _reads.clear();
    _frames.clear();
    _steps = 0;
    _collectionItems = 0;
    _depth = 0;
    _occurrence = const [];
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
    } on ExpressionProblem catch (failure) {
      return PortableExpressionFailed(
        failure.code,
        "Invalid expression",
        List.unmodifiable(_reads),
      );
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
      final projection = node.readProjection(remainingDepth: 512 - _depth);
      if (projection != null) return _project(projection);
      return switch (node) {
        skir.ExpressionNode_literalWrapper(:final value) => _Available(value),
        skir.ExpressionNode_fieldWrapper(:final value) => _field(
          value.source,
          skir.PathSegment.createField(name: value.name),
        ),
        skir.ExpressionNode_entryProjectionWrapper(:final value) => _field(
          value.source,
          switch (value.branch) {
            skir.EntryBranch.key => skir.PathSegment.mapKey,
            skir.EntryBranch.value => skir.PathSegment.mapValue,
            _ => throw const ExpressionProblem("invalid_entry_projection"),
          },
        ),
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
        skir.ExpressionNode_anyWrapper(:final value) ||
        skir.ExpressionNode_allWrapper(:final value) ||
        skir.ExpressionNode_noneWrapper(:final value) ||
        skir.ExpressionNode_mapWrapper(:final value) ||
        skir.ExpressionNode_filterWrapper(:final value) ||
        skir.ExpressionNode_findWrapper(:final value) ||
        skir.ExpressionNode_findLastWrapper(:final value) ||
        skir.ExpressionNode_countWrapper(:final value) ||
        skir.ExpressionNode_distinctByWrapper(:final value) ||
        skir.ExpressionNode_groupByWrapper(:final value) ||
        skir.ExpressionNode_flatMapWrapper(:final value) ||
        skir.ExpressionNode_uniqueByWrapper(
          :final value,
        ) => _unaryCollection(node, value.source, value.body),
        skir.ExpressionNode_sortByWrapper(:final value) => _unaryCollection(
          node,
          value.source,
          value.key,
          descending: value.descending,
          bodyIndex: 2,
        ),
        skir.ExpressionNode_foldWrapper(:final value) => _fold(
          value.source,
          value.initial,
          value.body,
        ),
        skir.ExpressionNode_reduceWrapper(:final value) => _fold(
          value.source,
          null,
          value.body,
        ),
        skir.ExpressionNode_sortWithWrapper(:final value) => _sortWith(value),
        skir.ExpressionNode_takeWrapper(:final value) => _slice(
          value,
          take: true,
        ),
        skir.ExpressionNode_skipWrapper(:final value) => _slice(
          value,
          take: false,
        ),
        skir.ExpressionNode_reverseWrapper(:final value) => _reorder(
          value,
          distinct: false,
        ),
        skir.ExpressionNode_distinctWrapper(:final value) => _reorder(
          value,
          distinct: true,
        ),
        skir.ExpressionNode_unknown() => throw const ExpressionProblem(
          "unknown_expression",
        ),
        _ => _scalar(node),
      };
    } finally {
      _depth--;
    }
  }

  _Evaluation _child(skir.ExpressionNode node, int index) {
    final previous = _occurrence;
    _occurrence = [...previous, index];
    try {
      return _evaluate(node);
    } finally {
      _occurrence = previous;
    }
  }

  PortableExpressionBinding _local(skir.ExpressionLocal ref) {
    if (ref.depth < 0 || ref.slot < 0 || ref.depth >= _frames.length) {
      throw const ExpressionProblem("invalid_expression_local");
    }
    final frame = _frames[_frames.length - 1 - ref.depth];
    if (ref.slot >= frame.length) {
      throw const ExpressionProblem("invalid_expression_local");
    }
    return frame[ref.slot];
  }

  _Evaluation _project(ExpressionProjection projection) {
    for (var i = 0; i < projection.descents; i++) {
      _consumeStep();
    }
    switch (projection.root) {
      case skir.ExpressionNode_inputWrapper(:final value):
        final path = skir.ValuePath(
          segments: [...value.path.segments, ...projection.suffix.segments],
        );
        return _readBinding(
          _bindings[value.binding],
          path,
          PortableExpressionReadSource.input(value.binding),
        );
      case skir.ExpressionNode_localWrapper(:final value):
        return _readBinding(
          _local(value),
          skir.ValuePath(
            segments: [...value.path.segments, ...projection.suffix.segments],
          ),
          PortableExpressionReadSource.local(value.depth, value.slot),
        );
      case skir.ExpressionNode_queryWrapper(:final value):
        return _query(
          value,
          projection.suffix,
          ExpressionOccurrence(
            path: [
              ..._occurrence,
              for (var i = 0; i < projection.descents; i++) 0,
            ],
          ),
        );
      default:
        throw const ExpressionProblem("invalid_projection");
    }
  }

  _Evaluation _readBinding(
    PortableExpressionBinding? binding,
    skir.ValuePath path,
    PortableExpressionReadSource source,
  ) {
    final origin = binding?.location;
    _reads.add(
      PortableExpressionRead(
        source: source,
        path: path,
        location: origin == null ? null : _appendLocation(origin, path),
      ),
    );
    if (binding == null) return const _Unavailable();
    return switch (binding.value.readExpressionAt(path)) {
      PortablePathValue(:final value) when value != skir.DataValue.unfilled =>
        _Available(value),
      _ => const _Unavailable(),
    };
  }

  _Evaluation _field(skir.ExpressionNode source, skir.PathSegment segment) {
    final evaluated = _child(source, 0);
    if (evaluated is _Unavailable) return evaluated;
    return switch ((evaluated as _Available).value.readExpressionAt(
      skir.ValuePath(segments: [segment]),
    )) {
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
    final first = _child(left, 0);
    if (first is _Unavailable) return first;
    final firstValue = _booleanValue((first as _Available).value);
    if (conjunction ? !firstValue : firstValue) {
      return _Available(skir.DataValue.wrapBoolean(firstValue));
    }
    final second = _child(right, 1);
    if (second is _Unavailable) return second;
    return _Available(
      skir.DataValue.wrapBoolean(_booleanValue((second as _Available).value)),
    );
  }

  _Evaluation _conditional(skir.ConditionalExpression value) {
    final test = _child(value.test, 0);
    if (test is _Unavailable) return test;
    final yes = _booleanValue((test as _Available).value);
    return _child(yes ? value.yes : value.no, yes ? 1 : 2);
  }

  _Evaluation _orElse(skir.OrElseExpression value) {
    final input = _child(value.input, 0);
    if (input is _Unavailable) return _child(value.fallback, 1);
    final actual = (input as _Available).value;
    return actual == skir.DataValue.null_ || actual == skir.DataValue.unfilled
        ? _child(value.fallback, 1)
        : input;
  }

  _Evaluation _inFrame(
    List<PortableExpressionBinding> values,
    skir.ExpressionNode body,
    int index,
  ) {
    _frames.add(List.unmodifiable(values));
    try {
      return _child(body, index);
    } finally {
      _frames.removeLast();
    }
  }

  _Evaluation _slice(
    skir.CollectionSliceExpression expression, {
    required bool take,
  }) {
    final source = _child(expression.source, 0);
    if (source is _Unavailable) return source;
    final count = _child(expression.count, 1);
    if (count is _Unavailable) return count;
    final size = _nonnegativeCount((count as _Available).value);
    final value = (source as _Available).value;
    final entries = _collectionEntries(value);
    _consumeCollectionItems(size < entries.length ? size : entries.length);
    return _Available(
      _reorderCollection(
        value,
        take ? entries.take(size).toList() : entries.skip(size).toList(),
      ),
    );
  }

  _Evaluation _reorder(skir.ExpressionNode source, {required bool distinct}) {
    final input = _child(source, 0);
    if (input is _Unavailable) return input;
    final value = (input as _Available).value;
    final entries = _collectionEntries(value);
    _consumeCollectionItems(entries.length);
    if (!distinct) {
      return _Available(_reorderCollection(value, entries.reversed.toList()));
    }
    if (entries.any((entry) => _containsUnfilled(entry.value))) {
      return const _Unavailable();
    }
    final seen = <String>{};
    return _Available(
      _reorderCollection(
        value,
        entries.where((entry) => seen.add(_canonical(entry.value))).toList(),
      ),
    );
  }

  _Evaluation _unaryCollection(
    skir.ExpressionNode node,
    skir.ExpressionNode source,
    skir.ExpressionNode body, {
    skir.ExpressionNode? descending,
    int bodyIndex = 1,
  }) {
    final input = _child(source, 0);
    if (input is _Unavailable) return input;
    final value = (input as _Available).value;
    final entries = _collectionEntries(value);
    var reverse = false;
    if (descending != null) {
      final result = _child(descending, 1);
      if (result is _Unavailable) return result;
      reverse = _booleanValue((result as _Available).value);
    }
    final origin = _sourceLocation(source);
    final results = <(_CollectionEntry, skir.DataValue)>[];
    var missing = false;
    for (final entry in entries) {
      _consumeCollectionItems(1);
      final result = _inFrame(
        [
          PortableExpressionBinding(
            value: entry.value,
            location: origin == null ? null : _entryLocation(origin, entry.id),
          ),
        ],
        body,
        bodyIndex,
      );
      if (result is _Unavailable) {
        missing = true;
        continue;
      }
      final computed = (result as _Available).value;
      if (_containsUnfilled(computed)) {
        missing = true;
        continue;
      }
      results.add((entry, computed));
      if (node is skir.ExpressionNode_anyWrapper && _booleanValue(computed)) {
        return _Available(_bool(true));
      }
      if (node is skir.ExpressionNode_allWrapper && !_booleanValue(computed)) {
        return _Available(_bool(false));
      }
      if (node is skir.ExpressionNode_noneWrapper && _booleanValue(computed)) {
        return _Available(_bool(false));
      }
      if (node is skir.ExpressionNode_findWrapper && _booleanValue(computed)) {
        return missing ? const _Unavailable() : _Available(entry.value);
      }
    }
    if (node is skir.ExpressionNode_uniqueByWrapper) {
      final seen = <String>{};
      for (final result in results) {
        if (!seen.add(_canonical(result.$2))) return _Available(_bool(false));
      }
    }
    if (missing) return const _Unavailable();
    return _Available(switch (node) {
      skir.ExpressionNode_anyWrapper() => _bool(false),
      skir.ExpressionNode_allWrapper() ||
      skir.ExpressionNode_noneWrapper() ||
      skir.ExpressionNode_uniqueByWrapper() => _bool(true),
      skir.ExpressionNode_mapWrapper() => skir.DataValue.createListValue(
        items: [
          for (final result in results)
            skir.ListItem(id: result.$1.id, value: result.$2),
        ],
      ),
      skir.ExpressionNode_filterWrapper() => _reorderCollection(
        value,
        results
            .where((result) => _booleanValue(result.$2))
            .map((result) => result.$1)
            .toList(),
      ),
      skir.ExpressionNode_findWrapper() => skir.DataValue.null_,
      skir.ExpressionNode_findLastWrapper() =>
        results
                .where((result) => _booleanValue(result.$2))
                .lastOrNull
                ?.$1
                .value ??
            skir.DataValue.null_,
      skir.ExpressionNode_countWrapper() => _integerValue(
        results.where((result) => _booleanValue(result.$2)).length,
      ),
      skir.ExpressionNode_distinctByWrapper() => _reorderCollection(
        value,
        _distinctEntriesByResult(results),
      ),
      skir.ExpressionNode_sortByWrapper() => _reorderCollection(
        value,
        _sortEntriesByResult(results, descending: reverse),
      ),
      skir.ExpressionNode_groupByWrapper() => _groupByKey(results),
      skir.ExpressionNode_flatMapWrapper() => _flatMap(results),
      _ => throw const ExpressionProblem("unknown_expression"),
    });
  }

  _Evaluation _fold(
    skir.ExpressionNode source,
    skir.ExpressionNode? initial,
    skir.ExpressionNode body,
  ) {
    final input = _child(source, 0);
    if (input is _Unavailable) return input;
    final entries = _collectionEntries((input as _Available).value);
    final origin = _sourceLocation(source);
    skir.DataValue accumulator;
    skir.ValueLocation? accumulatorLocation;
    if (initial == null) {
      if (entries.isEmpty) return _Available(skir.DataValue.null_);
      accumulator = entries.first.value;
      accumulatorLocation = origin == null
          ? null
          : _entryLocation(origin, entries.first.id);
    } else {
      final result = _child(initial, 1);
      if (result is _Unavailable) return result;
      accumulator = (result as _Available).value;
      accumulatorLocation = _sourceLocation(initial);
    }
    if (_containsUnfilled(accumulator)) return const _Unavailable();
    for (final entry in initial == null ? entries.skip(1) : entries) {
      _consumeCollectionItems(1);
      final result = _inFrame(
        [
          PortableExpressionBinding(
            value: accumulator,
            location: accumulatorLocation,
          ),
          PortableExpressionBinding(
            value: entry.value,
            location: origin == null ? null : _entryLocation(origin, entry.id),
          ),
        ],
        body,
        initial == null ? 1 : 2,
      );
      if (result is _Unavailable) return result;
      accumulator = (result as _Available).value;
      if (_containsUnfilled(accumulator)) return const _Unavailable();
      accumulatorLocation = null;
    }
    return _Available(accumulator);
  }

  _Evaluation _sortWith(skir.SortWithExpression expression) {
    final input = _child(expression.source, 0);
    if (input is _Unavailable) return input;
    final value = (input as _Available).value;
    final origin = _sourceLocation(expression.source);
    final sorted = <_CollectionEntry>[];
    for (final entry in _collectionEntries(value)) {
      var insertion = sorted.length;
      while (insertion > 0) {
        _consumeCollectionItems(2);
        final left = sorted[insertion - 1];
        final result = _inFrame(
          [
            for (final item in [left, entry])
              PortableExpressionBinding(
                value: item.value,
                location: origin == null
                    ? null
                    : _entryLocation(origin, item.id),
              ),
          ],
          expression.comparator,
          1,
        );
        if (result is _Unavailable) return result;
        final computed = (result as _Available).value;
        if (_containsUnfilled(computed)) return const _Unavailable();
        if (_number(computed).compareTo(_Decimal.zero) <= 0) break;
        insertion--;
      }
      sorted.insert(insertion, entry);
    }
    return _Available(_reorderCollection(value, sorted));
  }

  skir.ValueLocation? _sourceLocation(skir.ExpressionNode node) {
    final projection = node.readProjection();
    if (projection == null) return null;
    return switch (projection.root) {
      skir.ExpressionNode_inputWrapper(:final value) =>
        switch (_bindings[value.binding]?.location) {
          final origin? => _appendLocation(
            origin,
            skir.ValuePath(
              segments: [...value.path.segments, ...projection.suffix.segments],
            ),
          ),
          _ => null,
        },
      skir.ExpressionNode_localWrapper(:final value) => switch (_local(value)
          .location) {
        final origin? => _appendLocation(
          origin,
          skir.ValuePath(
            segments: [...value.path.segments, ...projection.suffix.segments],
          ),
        ),
        _ => null,
      },
      _ => null,
    };
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

enum _Arithmetic { add, subtract, multiply, divide, remainder, negate }

skir.DataValue _bool(bool value) => skir.DataValue.wrapBoolean(value);

skir.DataValue _string(String value) => skir.DataValue.wrapStringValue(value);

skir.DataValue _integerValue(int value) =>
    skir.DataValue.wrapInteger(value.toString());

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

/// Builds the semantic key used by portable equality and collection identity.
/// Named type identity remains significant; record field and set or map order
/// are normalized, list order is preserved, and collection item IDs are ignored.
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
    return value.target.resource.toExpressionValue();
  }
  throw const _ExpressionFailure(
    "expected_link",
    "The expression value is not a relationship link",
  );
}

BigInt _roundQuotient(BigInt numerator, BigInt denominator, String mode) {
  final quotient = numerator ~/ denominator;
  final remainder = numerator.remainder(denominator);
  final direction = numerator.isNegative ? -BigInt.one : BigInt.one;
  return switch (mode) {
    "TowardZero" => quotient,
    "Floor" => quotient - (remainder.isNegative ? BigInt.one : BigInt.zero),
    "Ceiling" =>
      quotient + (remainder > BigInt.zero ? BigInt.one : BigInt.zero),
    "NearestTiesToEven" =>
      remainder.abs() * BigInt.two > denominator ||
              (remainder.abs() * BigInt.two == denominator && quotient.isOdd)
          ? quotient + direction
          : quotient,
    _ => throw const _ExpressionFailure(
      "invalid_rounding_mode",
      "The rounding mode is unavailable",
    ),
  };
}

skir.DataValue _chargeFormattedValue(
  skir.DataValue value,
  void Function() consumeStep,
) {
  if (value case skir.DataValue_stringValueWrapper(:final value)) {
    for (final _ in value.runes) {
      consumeStep();
    }
  }
  return value;
}

_Decimal _formatNumber(skir.DataValue value) {
  if (_unwrap(value) case skir.DataValue_floatWrapper(:final value)) {
    if (!value.isFinite) {
      throw const _ExpressionFailure(
        "non_finite_number",
        "The numeric value must be finite",
      );
    }
  }
  final source = switch (_unwrap(value)) {
    skir.DataValue_integerWrapper(:final value) => value,
    skir.DataValue_decimalWrapper(:final value) => value,
    skir.DataValue_floatWrapper(:final value) => value.toString(),
    _ => throw const _ExpressionFailure(
      "expected_number",
      "The expression value is not numeric",
    ),
  };
  final exponentText = RegExp(r"[eE]([+-]?[0-9]+)$")
      .firstMatch(source)
      ?.group(1);
  final exponent = exponentText == null ? 0 : int.tryParse(exponentText);
  if (source.length > 4096 ||
      exponent == null ||
      exponent.abs() + source.length > 4096) {
    throw const _ExpressionFailure(
      "format_size_limit",
      "The formatted value exceeds its size limit",
    );
  }
  return _number(value);
}

skir.DataValue _roundPortableNumber(List<skir.DataValue> values) {
  final value = _unwrap(values[0]);
  final increment = _unwrap(values[1]);
  if (value.kind != increment.kind) {
    throw const _ExpressionFailure(
      "numeric_family_mismatch",
      "Rounding operands must use one numeric representation",
    );
  }
  final source = _formatNumber(value);
  final step = _formatNumber(increment);
  if (step.compareTo(_Decimal.zero) <= 0) {
    throw const _ExpressionFailure(
      "invalid_rounding_increment",
      "The rounding increment must be positive",
    );
  }
  final numerator = source.unscaled * _tenPow(step.scale);
  final denominator = step.unscaled * _tenPow(source.scale);
  final rounded =
      _Decimal(_roundQuotient(numerator, denominator, _text(values[2])), 0) *
      step;
  return switch (value) {
    skir.DataValue_integerWrapper() => skir.DataValue.wrapInteger(
      rounded.canonical,
    ),
    skir.DataValue_decimalWrapper() => skir.DataValue.wrapDecimal(
      rounded.canonical,
    ),
    skir.DataValue_floatWrapper() => _formatFiniteFloat(
      double.parse(rounded.canonical),
    ),
    _ => throw const _ExpressionFailure(
      "expected_number",
      "The expression value is not numeric",
    ),
  };
}

int _formatPrecision(skir.DataValue value, int maximum) {
  final precision = _integer(value);
  if (precision < BigInt.zero || precision > BigInt.from(maximum)) {
    throw const _ExpressionFailure(
      "invalid_format_precision",
      "Display precision is outside its supported range",
    );
  }
  return precision.toInt();
}

/// Localized grouping uses the host locale data. Locale und remains deterministic.
skir.DataValue _formatPortableNumber(List<skir.DataValue> values) {
  final digits = _formatPrecision(values[1], 20);
  final source = _formatNumber(values[0]);
  if (source.unscaled.abs().toString().length + source.scale > 4096) {
    throw const _ExpressionFailure(
      "format_size_limit",
      "The formatted value exceeds its size limit",
    );
  }
  final coefficient = source.scale <= digits
      ? source.unscaled * _tenPow(digits - source.scale)
      : _roundQuotient(
          source.unscaled,
          _tenPow(source.scale - digits),
          "NearestTiesToEven",
        );
  final magnitude = coefficient.abs().toString().padLeft(digits + 1, "0");
  var whole = digits == 0
      ? magnitude
      : magnitude.substring(0, magnitude.length - digits);
  final fraction = digits == 0
      ? ""
      : magnitude.substring(magnitude.length - digits);
  final locale = _text(values[2]);
  if (locale == "und") {
    return _string(
      "${coefficient.isNegative ? "-" : ""}$whole${digits == 0 ? "" : ".$fraction"}",
    );
  }
  NumberFormat formatter;
  try {
    final canonical = Intl.canonicalizedLocale(locale);
    final resolved = NumberFormat.localeExists(canonical)
        ? canonical
        : canonical.split("_").first;
    if (!NumberFormat.localeExists(resolved)) {
      throw const _ExpressionFailure(
        "invalid_format_locale",
        "The display locale is unavailable",
      );
    }
    formatter = NumberFormat.decimalPattern(resolved);
  } on ArgumentError {
    throw const _ExpressionFailure(
      "invalid_format_locale",
      "The display locale is unavailable",
    );
  }
  final symbols = formatter.symbols;
  final pattern = symbols.DECIMAL_PATTERN.split(";").first.split(".").first;
  final groups = pattern.split(",");
  if (groups.length > 1) {
    final primary = groups.last.replaceAll(RegExp("[^0#]"), "").length;
    final secondary = groups.length > 2
        ? groups[groups.length - 2].replaceAll(RegExp("[^0#]"), "").length
        : primary;
    final chunks = <String>[];
    var end = whole.length;
    var size = primary;
    while (end > size) {
      chunks.insert(0, whole.substring(end - size, end));
      end -= size;
      size = secondary;
    }
    chunks.insert(0, whole.substring(0, end));
    whole = chunks.join(symbols.GROUP_SEP);
  }
  var result =
      "${coefficient.isNegative ? symbols.MINUS_SIGN : ""}$whole${digits == 0 ? "" : "${symbols.DECIMAL_SEP}$fraction"}";
  final zero = symbols.ZERO_DIGIT.runes.first;
  if (zero != 48) {
    result = String.fromCharCodes(
      result.runes.map(
        (rune) => rune >= 48 && rune <= 57 ? zero + rune - 48 : rune,
      ),
    );
  }
  return _string(result);
}

skir.DataValue _formatPortableDuration(List<skir.DataValue> values) {
  final value = _unwrap(values[0]);
  if (value is! skir.DataValue_durationWrapper) {
    throw const _ExpressionFailure(
      "expected_duration",
      "The expression value is not a duration",
    );
  }
  if (!value.value.value.isPortable) {
    throw const _ExpressionFailure(
      "duration_range",
      "Duration millisecond count exceeds the finite portable range",
    );
  }
  final units = _text(values[1]);
  if (units != "MinutesAndSeconds" && units != "HoursMinutesAndSeconds") {
    throw const _ExpressionFailure(
      "invalid_duration_units",
      "The duration display units are unavailable",
    );
  }
  final digits = _formatPrecision(values[2], 3);
  final milliseconds = BigInt.from(value.value.value.milliseconds);
  final magnitude = milliseconds.abs();
  final seconds = magnitude ~/ BigInt.from(1000);
  final minutes = seconds ~/ BigInt.from(60);
  final secondsPart = seconds
      .remainder(BigInt.from(60))
      .toString()
      .padLeft(2, "0");
  final whole = units == "MinutesAndSeconds"
      ? "$minutes:$secondsPart"
      : "${minutes ~/ BigInt.from(60)}:${minutes.remainder(BigInt.from(60)).toString().padLeft(2, "0")}:$secondsPart";
  final fraction = digits == 0
      ? ""
      : ".${magnitude.remainder(BigInt.from(1000)).toString().padLeft(3, "0").substring(0, digits)}";
  return _string("${milliseconds.isNegative ? "-" : ""}$whole$fraction");
}

skir.DataValue _formatPortableTimestamp(List<skir.DataValue> values) {
  final value = _unwrap(values[0]);
  if (value is! skir.DataValue_timestampWrapper) {
    throw const _ExpressionFailure(
      "expected_timestamp",
      "The expression value is not a timestamp",
    );
  }
  final pattern = _text(values[1]);
  if (pattern.length > 128 ||
      !RegExp(r"^(?:yyyy|MM|dd|HH|mm|ss|SSS|[^A-Za-z])+$").hasMatch(pattern)) {
    throw const _ExpressionFailure(
      "invalid_timestamp_pattern",
      "The timestamp pattern is not portable",
    );
  }
  final timestamp = switch (_text(values[2])) {
    "UTC" || "utc" => value.value.toUtc(),
    "local" => value.value.toLocal(),
    _ => throw const _ExpressionFailure(
      "invalid_timestamp_zone",
      "The timestamp zone is unavailable",
    ),
  };
  final locale = _text(values[3]);
  final canonical = locale == "und"
      ? "en_US"
      : Intl.canonicalizedLocale(locale);
  if (!DateFormat.localeExists(canonical)) {
    throw const _ExpressionFailure(
      "invalid_format_locale",
      "The display locale is unavailable",
    );
  }
  return _string(DateFormat(pattern, canonical).format(timestamp));
}

skir.DataValue _formatFiniteFloat(double value) {
  if (!value.isFinite) {
    throw const _ExpressionFailure(
      "non_finite_number",
      "The numeric result must be finite",
    );
  }
  return skir.DataValue.wrapFloat(value);
}
