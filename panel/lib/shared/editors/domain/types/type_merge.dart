import "dart:math" as math;

import "package:typewriter_panel/typewriter_panel.dart";

TypeResult<TypeExpression> intersectTypes(
  TypeExpression left,
  TypeExpression right,
) {
  if (left is AnyType) return TypeResult.success(right);
  if (right is AnyType) return TypeResult.success(left);
  if (typeExpressionsEqual(left, right)) return TypeResult.success(left);

  if (left is StringType && right is StringType) {
    return _intersectStrings(left, right);
  }
  if (left is BytesType && right is BytesType) {
    return _intersectBytes(left, right);
  }
  if (left is IntegerType && right is IntegerType) {
    return _intersectIntegers(left, right);
  }
  if (left is FloatType && right is FloatType) {
    return _intersectFloats(left, right);
  }
  if (left is DecimalType && right is DecimalType) {
    return intersectDecimals(left, right);
  }
  if (left is TimestampType && right is TimestampType) {
    return intersectTimestamps(left, right);
  }
  if (left is DurationType && right is DurationType) {
    return intersectDurations(left, right);
  }
  if (left is EnumType && right is EnumType) {
    final valueType = intersectTypes(left.valueType, right.valueType);
    if (valueType case TypeFailure(:final diagnostics)) {
      return TypeResult.failure(diagnostics);
    }
    final values = left.values.where(right.values.contains).toList();
    return values.isEmpty
        ? _conflict(left, right)
        : TypeResult.success(
            EnumType(valueType: valueType.valueOrNull!, values: values),
          );
  }
  if (left is ListType && right is ListType) {
    return _intersectLists(left, right);
  }
  if (left is MapType && right is MapType) {
    return _intersectMaps(left, right);
  }
  if (left is RecordType && right is RecordType) {
    return _intersectRecords(left, right);
  }
  return _conflict(left, right);
}

TypeResult<TypeExpression> _intersectStrings(
  StringType left,
  StringType right,
) {
  final minimum = _maximumInt(left.minimumLength, right.minimumLength);
  final maximum = _minimumInt(left.maximumLength, right.maximumLength);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    StringType(
      minimumLength: minimum,
      maximumLength: maximum,
      patterns: {...left.patterns, ...right.patterns}.toList(),
    ),
  );
}

TypeResult<TypeExpression> _intersectBytes(BytesType left, BytesType right) {
  final minimum = _maximumInt(left.minimumLength, right.minimumLength);
  final maximum = _minimumInt(left.maximumLength, right.maximumLength);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    BytesType(minimumLength: minimum, maximumLength: maximum),
  );
}

TypeResult<TypeExpression> _intersectIntegers(
  IntegerType left,
  IntegerType right,
) {
  if (left.width != right.width) return _conflict(left, right);
  final minimum = _maximumBigInt(left.minimum, right.minimum);
  final maximum = _minimumBigInt(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    IntegerType(width: left.width, minimum: minimum, maximum: maximum),
  );
}

TypeResult<TypeExpression> _intersectFloats(FloatType left, FloatType right) {
  if (left.width != right.width) return _conflict(left, right);
  final minimum = _maximumDouble(left.minimum, right.minimum);
  final maximum = _minimumDouble(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    FloatType(width: left.width, minimum: minimum, maximum: maximum),
  );
}

TypeResult<TypeExpression> _intersectLists(ListType left, ListType right) {
  final element = intersectTypes(left.element, right.element);
  if (element case TypeFailure(:final diagnostics)) {
    return TypeResult.failure(diagnostics);
  }
  final minimum = _maximumInt(left.minimumLength, right.minimumLength);
  final maximum = _minimumInt(left.maximumLength, right.maximumLength);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    ListType(
      element: (element as TypeSuccess<TypeExpression>).value,
      minimumLength: minimum,
      maximumLength: maximum,
      unique: left.unique || right.unique,
    ),
  );
}

TypeResult<TypeExpression> _intersectMaps(MapType left, MapType right) {
  final key = intersectTypes(left.key, right.key);
  final value = intersectTypes(left.value, right.value);
  final diagnostics = [...key.diagnostics, ...value.diagnostics];
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
  final minimum = _maximumInt(left.minimumLength, right.minimumLength);
  final maximum = _minimumInt(left.maximumLength, right.maximumLength);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    MapType(
      key: key.valueOrNull!,
      value: value.valueOrNull!,
      minimumLength: minimum,
      maximumLength: maximum,
    ),
  );
}

TypeResult<TypeExpression> _intersectRecords(
  RecordType left,
  RecordType right,
) {
  final fields = <String, TypeField>{...left.fields};
  final diagnostics = <TypeDiagnostic>[];
  for (final entry in right.fields.entries) {
    final existing = fields[entry.key];
    if (existing == null) {
      fields[entry.key] = entry.value;
      continue;
    }
    final type = intersectTypes(existing.type, entry.value.type);
    if (type case TypeFailure(diagnostics: final fieldDiagnostics)) {
      diagnostics.addAll(fieldDiagnostics);
      continue;
    }
    fields[entry.key] = TypeField(
      name: entry.key,
      type: type.valueOrNull!,
      initialValue: entry.value.initialValue ?? existing.initialValue,
    );
  }
  if (diagnostics.isNotEmpty) return TypeResult.failure(diagnostics);
  return TypeResult.success(
    RecordType(fields: fields, closed: left.closed || right.closed),
  );
}

TypeFailure<TypeExpression> _conflict(
  TypeExpression left,
  TypeExpression right,
) => TypeFailure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.conflictingInheritance,
    message: "${left.runtimeType} conflicts with ${right.runtimeType}",
  ),
]);

int? _maximumInt(int? left, int? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => math.max(a, b),
};

int? _minimumInt(int? left, int? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => math.min(a, b),
};

BigInt? _maximumBigInt(BigInt? left, BigInt? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => a > b ? a : b,
};

BigInt? _minimumBigInt(BigInt? left, BigInt? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => a < b ? a : b,
};

double? _maximumDouble(double? left, double? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => math.max(a, b),
};

double? _minimumDouble(double? left, double? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => math.min(a, b),
};
