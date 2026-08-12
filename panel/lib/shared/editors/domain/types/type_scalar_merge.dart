import "dart:math" as math;

import "package:typewriter_panel/typewriter_panel.dart";

TypeResult<TypeExpression> intersectDecimals(
  DecimalType left,
  DecimalType right,
) {
  final minimum = _maximumDecimal(left.minimum, right.minimum);
  final maximum = _minimumDecimal(left.maximum, right.maximum);
  if (minimum != null &&
      maximum != null &&
      compareDecimalStrings(minimum, maximum) > 0) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    DecimalType(
      minimum: minimum,
      maximum: maximum,
      scale: _minimumInt(left.scale, right.scale),
    ),
  );
}

TypeResult<TypeExpression> intersectTimestamps(
  TimestampType left,
  TimestampType right,
) {
  final minimum = _maximumComparable(left.minimum, right.minimum);
  final maximum = _minimumComparable(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum.isAfter(maximum)) {
    return _conflict(left, right);
  }
  return TypeResult.success(TimestampType(minimum: minimum, maximum: maximum));
}

TypeResult<TypeExpression> intersectDurations(
  DurationType left,
  DurationType right,
) {
  final minimum = _maximumComparable(left.minimum, right.minimum);
  final maximum = _minimumComparable(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(DurationType(minimum: minimum, maximum: maximum));
}

String? _maximumDecimal(String? left, String? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => compareDecimalStrings(a, b) >= 0 ? a : b,
};

String? _minimumDecimal(String? left, String? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => compareDecimalStrings(a, b) <= 0 ? a : b,
};

int? _minimumInt(int? left, int? right) => switch ((left, right)) {
  (null, _) => right,
  (_, null) => left,
  (final a?, final b?) => math.min(a, b),
};

T? _maximumComparable<T extends Comparable<T>>(T? left, T? right) =>
    switch ((left, right)) {
      (null, _) => right,
      (_, null) => left,
      (final a?, final b?) => a.compareTo(b) >= 0 ? a : b,
    };

T? _minimumComparable<T extends Comparable<T>>(T? left, T? right) =>
    switch ((left, right)) {
      (null, _) => right,
      (_, null) => left,
      (final a?, final b?) => a.compareTo(b) <= 0 ? a : b,
    };

TypeFailure<TypeExpression> _conflict(
  TypeExpression left,
  TypeExpression right,
) => TypeFailure([
  TypeDiagnostic(
    code: TypeDiagnosticCode.conflictingInheritance,
    message: "${left.runtimeType} conflicts with ${right.runtimeType}",
  ),
]);
