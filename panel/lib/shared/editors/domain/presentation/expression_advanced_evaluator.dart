part of "expression_evaluator.dart";

const _maximumRegexPatternLength = 512;
const _maximumRegexInputLength = 16384;
const _maximumRegexCaptureGroup = 32;
const _maximumCompiledRegexes = 128;

final _compiledRegexes = <String, RegExp>{};

extension on _ExpressionEvaluator {
  TypeResult<DataValue> _stringOperation(
    StringOperationExpression expression,
    int depth,
  ) {
    final evaluated = _evaluateOperands(expression.operands, depth);
    if (evaluated case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final values = evaluated.valueOrNull!;

    return switch (expression.operation) {
      StringOperation.trim => _unaryString(values, (value) => value.trim()),
      StringOperation.lowerCase => _unaryString(
        values,
        (value) => value.toLowerCase(),
      ),
      StringOperation.upperCase => _unaryString(
        values,
        (value) => value.toUpperCase(),
      ),
      StringOperation.titleCase => _unaryString(
        values,
        (value) => value.titleCase(),
      ),
      StringOperation.replace => _replaceString(values),
      StringOperation.split => _splitString(values),
      StringOperation.join => _joinStrings(values),
      StringOperation.substring => _substring(values),
      StringOperation.contains => _compareString(
        values,
        (value, search) => value.contains(search),
      ),
      StringOperation.startsWith => _compareString(
        values,
        (value, search) => value.startsWith(search),
      ),
      StringOperation.endsWith => _compareString(
        values,
        (value, search) => value.endsWith(search),
      ),
    };
  }

  TypeResult<DataValue> _collectionOperation(
    CollectionOperationExpression expression,
    int depth,
  ) {
    final evaluated = _evaluateOperands(expression.operands, depth);
    if (evaluated case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final values = evaluated.valueOrNull!;

    return switch (expression.operation) {
      CollectionOperation.access => _collectionAccess(values),
      CollectionOperation.length => _collectionLength(values),
      CollectionOperation.contains => _collectionContains(values),
    };
  }

  TypeResult<DataValue> _regex(RegexExpression expression, int depth) {
    if (expression.pattern.length > _maximumRegexPatternLength) {
      return _failure("Regular expression pattern is too long");
    }
    final group = expression.group ?? 0;
    if (group < 0 || group > _maximumRegexCaptureGroup) {
      return _failure("Regular expression capture group is out of range");
    }
    final source = evaluate(expression.source, depth + 1);
    if (source case TypeFailure()) return source;
    final sourceValue = source.valueOrNull!;
    if (sourceValue is! StringValue) {
      return _failure("Regular expression source must be a string");
    }
    if (sourceValue.value.length > _maximumRegexInputLength) {
      return _failure("Regular expression input is too long");
    }
    final regularExpression = _compileRegex(expression.pattern);
    if (regularExpression == null) {
      return _failure("Regular expression pattern is invalid");
    }

    return switch (expression.operation) {
      RegexOperation.matches => TypeResult.success(
        BooleanValue(regularExpression.hasMatch(sourceValue.value)),
      ),
      RegexOperation.capture => _captureRegex(
        regularExpression,
        sourceValue.value,
        group,
      ),
      RegexOperation.replace =>
        expression.replacement == null
            ? _failure("Regular expression replacement is missing")
            : TypeResult.success(
                StringValue(
                  sourceValue.value.replaceAll(
                    regularExpression,
                    expression.replacement!,
                  ),
                ),
              ),
    };
  }

  TypeResult<DataValue> _coalesce(CoalesceExpression expression, int depth) {
    if (expression.operands.isEmpty) {
      return _failure("Coalesce operands are empty");
    }
    TypeFailure<DataValue>? lastFailure;
    for (final operand in expression.operands) {
      final result = evaluate(operand, depth + 1);
      if (result case TypeSuccess()) return result;
      lastFailure = result as TypeFailure<DataValue>;
    }
    return lastFailure!;
  }

  TypeResult<List<DataValue>> _evaluateOperands(
    List<TypedExpression> operands,
    int depth,
  ) {
    final values = <DataValue>[];
    for (final operand in operands) {
      final result = evaluate(operand, depth + 1);
      if (result case TypeFailure(:final diagnostics)) {
        return TypeResult.failure(diagnostics);
      }
      values.add(result.valueOrNull!);
    }
    return TypeResult.success(values);
  }
}

TypeResult<DataValue> _unaryString(
  List<DataValue> values,
  String Function(String) transform,
) {
  if (values.length != 1 || values.single is! StringValue) {
    return _failure("String operation requires one string operand");
  }
  return TypeResult.success(
    StringValue(transform((values.single as StringValue).value)),
  );
}

TypeResult<DataValue> _replaceString(List<DataValue> values) {
  final strings = _stringOperands(values, 3);
  if (strings == null) {
    return _failure("String replacement requires three string operands");
  }
  return TypeResult.success(
    StringValue(strings[0].replaceAll(strings[1], strings[2])),
  );
}

TypeResult<DataValue> _splitString(List<DataValue> values) {
  final strings = _stringOperands(values, 2);
  if (strings == null) {
    return _failure("String split requires two string operands");
  }
  return TypeResult.success(
    ListValue(strings[0].split(strings[1]).map(StringValue.new).toList()),
  );
}

TypeResult<DataValue> _joinStrings(List<DataValue> values) {
  if (values.length != 2 ||
      values[0] is! ListValue ||
      values[1] is! StringValue) {
    return _failure("String join requires a string list and separator");
  }
  final items = (values[0] as ListValue).values;
  if (items.any((value) => value is! StringValue)) {
    return _failure("String join requires a string list and separator");
  }
  return TypeResult.success(
    StringValue(
      items
          .cast<StringValue>()
          .map((value) => value.value)
          .join((values[1] as StringValue).value),
    ),
  );
}

TypeResult<DataValue> _substring(List<DataValue> values) {
  if (values.length < 2 ||
      values.length > 3 ||
      values[0] is! StringValue ||
      values[1] is! IntegerValue ||
      (values.length == 3 && values[2] is! IntegerValue)) {
    return _failure("Substring operands are invalid");
  }
  final source = (values[0] as StringValue).value;
  final start = (values[1] as IntegerValue).value;
  final end = values.length == 3
      ? (values[2] as IntegerValue).value
      : BigInt.from(source.length);
  if (start < BigInt.zero || end < start || end > BigInt.from(source.length)) {
    return _failure("Substring range is invalid");
  }
  return TypeResult.success(
    StringValue(source.substring(start.toInt(), end.toInt())),
  );
}

TypeResult<DataValue> _compareString(
  List<DataValue> values,
  bool Function(String, String) compare,
) {
  final strings = _stringOperands(values, 2);
  if (strings == null) {
    return _failure("String comparison requires two string operands");
  }
  return TypeResult.success(BooleanValue(compare(strings[0], strings[1])));
}

List<String>? _stringOperands(List<DataValue> values, int count) =>
    values.length == count && values.every((value) => value is StringValue)
    ? values.cast<StringValue>().map((value) => value.value).toList()
    : null;
