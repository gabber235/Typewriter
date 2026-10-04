part of "type_validation.dart";

/// Scalar checks that require representation specific comparisons.
extension on FloatValue {
  List<TypeDiagnostic> validateFloatAgainst(FloatType type, DataPath path) {
    if (!value.isFinite) return [_invalid(path, "Float must be finite")];
    if (type.minimum case final minimum? when value < minimum) {
      return [_invalid(path, "Float must be at least $minimum")];
    }
    if (type.maximum case final maximum? when value > maximum) {
      return [_invalid(path, "Float must be at most $maximum")];
    }
    return const [];
  }
}

extension on DecimalValue {
  List<TypeDiagnostic> validateDecimalAgainst(DecimalType type, DataPath path) {
    if (type.minimum case final minimum?
        when compareDecimalStrings(value, minimum) < 0) {
      return [_invalid(path, "Decimal must be at least $minimum")];
    }
    if (type.maximum case final maximum?
        when compareDecimalStrings(value, maximum) > 0) {
      return [_invalid(path, "Decimal must be at most $maximum")];
    }
    if (type.scale case final scale? when value.decimalScale > scale) {
      return [_invalid(path, "Decimal scale exceeds $scale")];
    }
    return const [];
  }
}
