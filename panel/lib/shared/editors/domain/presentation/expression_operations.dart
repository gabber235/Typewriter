import "package:typewriter_panel/typewriter_panel.dart";

extension ArithmeticOperatorEvaluation on ArithmeticOperator {
  TypeResult<DataValue> evaluateIntegers(List<IntegerValue> values) {
    if (values.isEmpty) return _failure("Arithmetic operands are empty");
    if (this == ArithmeticOperator.negate) {
      return values.length == 1
          ? TypeResult.success(IntegerValue(-values.single.value))
          : _failure("Negation requires one operand");
    }
    if (values.length < 2) return _failure("Arithmetic requires two operands");
    var value = values.first.value;
    for (final operand in values.skip(1)) {
      if ((this == ArithmeticOperator.divide ||
              this == ArithmeticOperator.remainder) &&
          operand.value == BigInt.zero) {
        return _failure("Division by zero");
      }
      value = switch (this) {
        ArithmeticOperator.add => value + operand.value,
        ArithmeticOperator.subtract => value - operand.value,
        ArithmeticOperator.multiply => value * operand.value,
        ArithmeticOperator.divide => value ~/ operand.value,
        ArithmeticOperator.remainder => value.remainder(operand.value),
        ArithmeticOperator.negate => value,
      };
    }
    return TypeResult.success(IntegerValue(value));
  }

  TypeResult<DataValue> evaluateFloats(List<FloatValue> values) {
    if (values.isEmpty) return _failure("Arithmetic operands are empty");
    if (this == ArithmeticOperator.negate) {
      return values.length == 1
          ? TypeResult.success(FloatValue(-values.single.value))
          : _failure("Negation requires one operand");
    }
    if (values.length < 2) return _failure("Arithmetic requires two operands");
    var value = values.first.value;
    for (final operand in values.skip(1)) {
      value = switch (this) {
        ArithmeticOperator.add => value + operand.value,
        ArithmeticOperator.subtract => value - operand.value,
        ArithmeticOperator.multiply => value * operand.value,
        ArithmeticOperator.divide => value / operand.value,
        ArithmeticOperator.remainder => value.remainder(operand.value),
        ArithmeticOperator.negate => value,
      };
    }
    return value.isFinite
        ? TypeResult.success(FloatValue(value))
        : _failure("Float arithmetic produced a nonfinite value");
  }
}

int? compareExpressionValues(DataValue left, DataValue right) => switch ((
  left,
  right,
)) {
  (
    IntegerValue(value: final leftValue),
    IntegerValue(value: final rightValue),
  ) =>
    leftValue.compareTo(rightValue),
  (FloatValue(value: final leftValue), FloatValue(value: final rightValue)) =>
    leftValue.compareTo(rightValue),
  (
    DecimalValue(value: final leftValue),
    DecimalValue(value: final rightValue),
  ) =>
    compareDecimalStrings(leftValue, rightValue),
  (StringValue(value: final leftValue), StringValue(value: final rightValue)) =>
    leftValue.compareTo(rightValue),
  (
    TimestampValue(value: final leftValue),
    TimestampValue(value: final rightValue),
  ) =>
    leftValue.compareTo(rightValue),
  (
    DurationValue(value: final leftValue),
    DurationValue(value: final rightValue),
  ) =>
    leftValue.compareTo(rightValue),
  _ => null,
};

extension DataValueExpressionDisplay on DataValue {
  String get expressionDisplayText => switch (this) {
    UnitValue() => "",
    BooleanValue(:final value) => value.toString(),
    IntegerValue(:final value) => value.toString(),
    FloatValue(:final value) => value.toString(),
    DecimalValue(:final value) => value,
    StringValue(:final value) => value,
    TimestampValue(:final value) => value.toIso8601String(),
    DurationValue(:final value) => value.toString(),
    BytesValue(:final value) => "${value.length} bytes",
    ListValue(:final values) => "${values.length} items",
    MapValue(:final entries) => "${entries.length} entries",
    RecordValue() => "record",
    PolymorphicValue(:final concreteType) => concreteType.toString(),
  };
}

TypeFailure<DataValue> _failure(String message) => TypeFailure([
  TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message),
]);
