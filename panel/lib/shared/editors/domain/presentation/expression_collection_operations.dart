part of "expression_evaluator.dart";

TypeResult<DataValue> _collectionAccess(List<DataValue> values) {
  if (values.length != 2) {
    return _failure("Collection access requires a collection and key");
  }
  final collection = values[0];
  final key = values[1];
  if (collection is ListValue && key is IntegerValue) {
    final index = key.value;
    if (index < BigInt.zero || index >= BigInt.from(collection.values.length)) {
      return _failure("Collection index is out of range");
    }
    return TypeResult.success(collection.values[index.toInt()]);
  }
  if (collection is MapValue) {
    for (final entry in collection.entries) {
      if (entry.key == key) return TypeResult.success(entry.value);
    }
    return _failure("Collection key is absent");
  }
  if (collection is RecordValue && key is StringValue) {
    final value = collection.fields[key.value];
    return value == null
        ? _failure("Collection key is absent")
        : TypeResult.success(value);
  }
  if (collection is StringValue && key is IntegerValue) {
    final index = key.value;
    if (index < BigInt.zero || index >= BigInt.from(collection.value.length)) {
      return _failure("Collection index is out of range");
    }
    return TypeResult.success(
      StringValue(collection.value.substring(index.toInt(), index.toInt() + 1)),
    );
  }
  return _failure("Collection access operands are invalid");
}

TypeResult<DataValue> _collectionLength(List<DataValue> values) {
  if (values.length != 1) {
    return _failure("Collection length requires one operand");
  }
  final length = switch (values.single) {
    ListValue(:final values) => values.length,
    MapValue(:final entries) => entries.length,
    RecordValue(:final fields) => fields.length,
    StringValue(:final value) => value.length,
    _ => null,
  };
  return length == null
      ? _failure("Collection length operand is invalid")
      : TypeResult.success(IntegerValue(BigInt.from(length)));
}

TypeResult<DataValue> _collectionContains(List<DataValue> values) {
  if (values.length != 2) {
    return _failure("Collection contains requires a collection and value");
  }
  final collection = values[0];
  final value = values[1];
  final contains = switch (collection) {
    ListValue(:final values) => values.contains(value),
    MapValue(:final entries) => entries.any((entry) => entry.key == value),
    RecordValue(:final fields) when value is StringValue => fields.containsKey(
      value.value,
    ),
    _ => null,
  };
  return contains == null
      ? _failure("Collection contains operands are invalid")
      : TypeResult.success(BooleanValue(contains));
}

TypeResult<DataValue> _captureRegex(
  RegExp expression,
  String source,
  int group,
) {
  final match = expression.firstMatch(source);
  if (match == null) return _failure("Regular expression did not match");
  if (group > match.groupCount) {
    return _failure("Regular expression capture group is absent");
  }
  final value = match.group(group);
  return value == null
      ? _failure("Regular expression capture group did not participate")
      : TypeResult.success(StringValue(value));
}

RegExp? _compileRegex(String pattern) {
  final cached = _compiledRegexes.remove(pattern);
  if (cached != null) {
    _compiledRegexes[pattern] = cached;
    return cached;
  }
  try {
    final expression = RegExp(pattern);
    if (_compiledRegexes.length >= _maximumCompiledRegexes) {
      _compiledRegexes.remove(_compiledRegexes.keys.first);
    }
    _compiledRegexes[pattern] = expression;
    return expression;
  } on FormatException {
    return null;
  }
}
