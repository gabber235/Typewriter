part of "portable_expression.dart";

extension _ScalarExpressionEvaluation on PortableExpressionEvaluator {
  _Evaluation _scalar(skir.ExpressionNode node) {
    final operands = node.scalarOperands;
    if (operands == null) throw const ExpressionProblem("unknown_expression");
    final values = <skir.DataValue>[];
    for (final (index, operand) in operands.indexed) {
      final result = _child(operand, index);
      if (result is _Unavailable) return result;
      values.add((result as _Available).value);
    }
    if (node case skir.ExpressionNode_ruleUnaryWrapper(value: final rule)
        when rule.operation == skir.RuleUnaryOperation.unique) {
      return _unique(values.single);
    }
    final result = switch (node) {
      skir.ExpressionNode_textUnaryWrapper(:final value) => _string(
        switch (value.operation) {
          skir.TextUnaryOperation.value => _text(values.single),
          skir.TextUnaryOperation.trim => _portableTrim(_text(values.single)),
          skir.TextUnaryOperation.lower => _text(values.single).toLowerCase(),
          skir.TextUnaryOperation.upper => _text(values.single).toUpperCase(),
          skir.TextUnaryOperation.title => _titleCase(_text(values.single)),
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_textCompareWrapper(:final value) => _bool(
        switch (value.operation) {
          skir.TextCompareOperation.contains => _text(
            values[0],
          ).contains(_text(values[1])),
          skir.TextCompareOperation.startsWith => _text(
            values[0],
          ).startsWith(_text(values[1])),
          skir.TextCompareOperation.endsWith => _text(
            values[0],
          ).endsWith(_text(values[1])),
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_textLengthWrapper() => _integerValue(
        _text(values.single).runes.length,
      ),
      skir.ExpressionNode_textHasLineBreakWrapper() => _bool(
        _hasLineBreak(_text(values.single)),
      ),
      skir.ExpressionNode_textReplaceWrapper() => _string(
        _boundedLiteralReplace(
          _text(values[0]),
          _text(values[1]),
          _text(values[2]),
          _consumeStep,
        ),
      ),
      skir.ExpressionNode_textSplitWrapper() => _split(
        values,
        _consumeCollectionItems,
      ),
      skir.ExpressionNode_textJoinWrapper() => _string(
        _boundedJoin(
          _collectionValues(values[0]).map(_text),
          _text(values[1]),
          _consumeStep,
        ),
      ),
      skir.ExpressionNode_textSubstringWrapper() => _substring(values),
      skir.ExpressionNode_textInterpolateWrapper() => _string(
        _boundedInterpolate(values, _consumeStep),
      ),
      skir.ExpressionNode_regexTestWrapper(:final value) => _bool(
        switch (value.mode) {
          skir.RegexMatchMode.search => _regex(
            values,
          ).containsMatchIn(_text(values[0]), _consumeStep),
          skir.RegexMatchMode.fullMatch => _regex(
            values,
          ).matches(_text(values[0]), _consumeStep),
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_regexCaptureWrapper() => _capture(values),
      skir.ExpressionNode_regexReplaceWrapper() => _replaceRegex(values),
      skir.ExpressionNode_valueCompareWrapper(:final value) => _bool(
        switch (value.operation) {
          skir.ValueCompareOperation.equal =>
            _canonical(values[0]) == _canonical(values[1]),
          skir.ValueCompareOperation.notEqual =>
            _canonical(values[0]) != _canonical(values[1]),
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_isNullWrapper() => _bool(
        values.single == skir.DataValue.null_,
      ),
      skir.ExpressionNode_linkTargetWrapper() => _linkTarget(values.single),
      skir.ExpressionNode_booleanNotWrapper() => _bool(
        !_booleanValue(values.single),
      ),
      skir.ExpressionNode_numberArithmeticWrapper(:final value) => _arithmetic(
        values,
        switch (value.operation) {
          skir.NumberArithmeticOperation.add => _Arithmetic.add,
          skir.NumberArithmeticOperation.subtract => _Arithmetic.subtract,
          skir.NumberArithmeticOperation.multiply => _Arithmetic.multiply,
          skir.NumberArithmeticOperation.divide => _Arithmetic.divide,
          skir.NumberArithmeticOperation.remainder => _Arithmetic.remainder,
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_numberCompareWrapper(:final value) => _bool(
        switch (value.operation) {
          skir.NumberCompareOperation.greater => _compareNumbers(values) > 0,
          skir.NumberCompareOperation.greaterEqual =>
            _compareNumbers(values) >= 0,
          skir.NumberCompareOperation.less => _compareNumbers(values) < 0,
          skir.NumberCompareOperation.lessEqual => _compareNumbers(values) <= 0,
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_numberNegateWrapper() => _arithmetic(
        values,
        _Arithmetic.negate,
      ),
      skir.ExpressionNode_numberRoundWrapper() => _roundPortableNumber(values),
      skir.ExpressionNode_numberFormatWrapper() => _chargeFormattedValue(
        _formatPortableNumber(values),
        _consumeStep,
      ),
      skir.ExpressionNode_durationFormatWrapper() => _chargeFormattedValue(
        _formatPortableDuration(values),
        _consumeStep,
      ),
      skir.ExpressionNode_timestampFormatWrapper() => _chargeFormattedValue(
        _formatPortableTimestamp(values),
        _consumeStep,
      ),
      skir.ExpressionNode_collectionSizeWrapper() => _integerValue(
        _size(values.single),
      ),
      skir.ExpressionNode_collectionAccessWrapper() => _collectionAccess(
        values,
      ),
      skir.ExpressionNode_collectionContainsWrapper() => _bool(
        _collectionContains(values),
      ),
      skir.ExpressionNode_colorWithAlphaWrapper() => _withAlpha(values),
      skir.ExpressionNode_ruleUnaryWrapper(:final value) => _bool(
        switch (value.operation) {
          skir.RuleUnaryOperation.nonEmpty => _size(values.single) > 0,
          skir.RuleUnaryOperation.nonBlank => _portableTrim(
            _text(values.single),
          ).isNotEmpty,
          skir.RuleUnaryOperation.singleLine => !_hasLineBreak(
            _text(values.single),
          ),
          skir.RuleUnaryOperation.positive =>
            _number(values.single).compareTo(_Decimal.zero) > 0,
          skir.RuleUnaryOperation.nonNegative =>
            _number(values.single).compareTo(_Decimal.zero) >= 0,
          skir.RuleUnaryOperation.notNull =>
            values.single != skir.DataValue.null_,
          skir.RuleUnaryOperation.opaque =>
            ((_integer(values.single) >> 24) & BigInt.from(255)) ==
                BigInt.from(255),
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_ruleOneOfWrapper() => _bool(
        values.skip(1).any((v) => _canonical(v) == _canonical(values[0])),
      ),
      skir.ExpressionNode_ruleSizeBoundWrapper(:final value) => _sizeBound(
        value,
        values,
      ),
      skir.ExpressionNode_ruleSizeRangeWrapper(:final value) => _bool(
        _betweenInt(
          switch (value.metric) {
            skir.SizeRangeMetric.textLength ||
            skir.SizeRangeMetric.collectionItems => _size(values[0]),
            _ => throw const ExpressionProblem("unknown_expression_operation"),
          },
          _integer(values[1]).toInt(),
          _integer(values[2]).toInt(),
        ),
      ),
      skir.ExpressionNode_ruleNumericBoundWrapper(:final value) => _bool(
        switch (value.direction) {
          skir.BoundDirection.minimum =>
            _booleanValue(values[2])
                ? _compareNumbers(values) >= 0
                : _compareNumbers(values) > 0,
          skir.BoundDirection.maximum =>
            _booleanValue(values[2])
                ? _compareNumbers(values) <= 0
                : _compareNumbers(values) < 0,
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      skir.ExpressionNode_ruleNumericRangeWrapper() => _bool(
        _compareNumber(values[0], values[1]) >= 0 &&
            _compareNumber(values[0], values[2]) <= 0,
      ),
      skir.ExpressionNode_ruleMultipleOfWrapper() => _multipleOf(values),
      skir.ExpressionNode_ruleMaximumScaleWrapper() => _bool(
        _number(values[0]).normalizedScale <= _integer(values[1]).toInt(),
      ),
      skir.ExpressionNode_ruleTimestampBoundWrapper(:final value) => _bool(
        switch (value.direction) {
          skir.TimestampBoundDirection.notBefore =>
            _timestamp(values[0]).compareTo(_timestamp(values[1])) >= 0,
          skir.TimestampBoundDirection.notAfter =>
            _timestamp(values[0]).compareTo(_timestamp(values[1])) <= 0,
          _ => throw const ExpressionProblem("unknown_expression_operation"),
        },
      ),
      _ => throw const ExpressionProblem("unknown_expression"),
    };
    return result == skir.DataValue.unfilled
        ? const _Unavailable()
        : _Available(result);
  }

  skir.DataValue _sizeBound(
    skir.RuleSizeBoundExpression expression,
    List<skir.DataValue> values,
  ) {
    final size = switch (expression.metric) {
      skir.SizeBoundMetric.textLength ||
      skir.SizeBoundMetric.collectionItems => _size(values[0]),
      skir.SizeBoundMetric.textLines => _lineCount(_text(values[0])),
      _ => throw const ExpressionProblem("unknown_expression_operation"),
    };
    final bound = _integer(values[1]).toInt();
    return _bool(switch (expression.direction) {
      skir.BoundDirection.minimum => size >= bound,
      skir.BoundDirection.maximum => size <= bound,
      _ => throw const ExpressionProblem("unknown_expression_operation"),
    });
  }
}
