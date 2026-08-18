import "package:typewriter_panel/typewriter_panel.dart";

TypeResult<TypeExpression> intersectDecimals(
  DecimalType left,
  DecimalType right,
) {
  final minimum = maximumNullable(
    left.minimum,
    right.minimum,
    compare: compareDecimalStrings,
  );
  final maximum = minimumNullable(
    left.maximum,
    right.maximum,
    compare: compareDecimalStrings,
  );
  if (minimum != null &&
      maximum != null &&
      compareDecimalStrings(minimum, maximum) > 0) {
    return _conflict(left, right);
  }
  return TypeResult.success(
    DecimalType(
      minimum: minimum,
      maximum: maximum,
      scale: minimumNullableComparable(left.scale, right.scale),
    ),
  );
}

TypeResult<TypeExpression> intersectTimestamps(
  TimestampType left,
  TimestampType right,
) {
  final minimum = maximumNullableComparable(left.minimum, right.minimum);
  final maximum = minimumNullableComparable(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum.isAfter(maximum)) {
    return _conflict(left, right);
  }
  return TypeResult.success(TimestampType(minimum: minimum, maximum: maximum));
}

TypeResult<TypeExpression> intersectDurations(
  DurationType left,
  DurationType right,
) {
  final minimum = maximumNullableComparable(left.minimum, right.minimum);
  final maximum = minimumNullableComparable(left.maximum, right.maximum);
  if (minimum != null && maximum != null && minimum > maximum) {
    return _conflict(left, right);
  }
  return TypeResult.success(DurationType(minimum: minimum, maximum: maximum));
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
