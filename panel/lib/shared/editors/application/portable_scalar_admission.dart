import "dart:typed_data";

import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;

bool admitsPortableScalarValue(
  types.ScalarKind expected,
  types.DataValue value,
) {
  if (expected == types.ScalarKind.unit) return value == types.DataValue.unit;
  if (expected == types.ScalarKind.boolean) {
    return value is types.DataValue_booleanWrapper;
  }
  if (expected == types.ScalarKind.text) {
    return value is types.DataValue_stringValueWrapper;
  }
  if (expected == types.ScalarKind.bytes) {
    return value is types.DataValue_bytesWrapper;
  }
  if (expected == types.ScalarKind.decimal) {
    return switch (value) {
      types.DataValue_decimalWrapper(:final value) => switch (_decimalValue(
        value,
      )) {
        types.DataValue_decimalWrapper(value: final canonical) =>
          canonical == value,
        _ => false,
      },
      _ => false,
    };
  }
  if (expected == types.ScalarKind.timestamp) {
    return value is types.DataValue_timestampWrapper;
  }
  if (expected == types.ScalarKind.duration) {
    return value is types.DataValue_durationWrapper;
  }
  if (expected case types.ScalarKind_integerWrapper(value: final integer)) {
    return value is types.DataValue_integerWrapper &&
        _integerValue(value.value, integer.width) != null;
  }
  if (expected case types.ScalarKind_floatWrapper(value: final float)) {
    if (value is! types.DataValue_floatWrapper || !value.value.isFinite) {
      return false;
    }
    if (float.width == types.FloatWidth.thirtyTwo) {
      final narrowed = Float32List.fromList([value.value]).single;
      return narrowed.isFinite && narrowed == value.value;
    }
    return float.width == types.FloatWidth.sixtyFour;
  }
  return false;
}

types.DataValue? admitPortableNumericInput({
  required types.DataValue? current,
  required types.TypeUse? expected,
  required String text,
}) {
  final scalar = _numericScalar(current, expected);
  return switch (scalar) {
    types.ScalarKind_integerWrapper(:final value) => _integerValue(
      text,
      value.width,
    ),
    types.ScalarKind_floatWrapper(:final value) => _floatValue(
      text,
      value.width,
    ),
    _ when scalar == types.ScalarKind.decimal => _decimalValue(text),
    _ => null,
  };
}

bool acceptsPortableNumericInput({
  required types.DataValue? current,
  required types.TypeUse? expected,
  required String text,
}) {
  final scalar = _numericScalar(current, expected);
  final partial = switch (scalar) {
    types.ScalarKind_integerWrapper(:final value) =>
      value.width.kind.name.startsWith("unsigned")
          ? RegExp(r"^\d*$").hasMatch(text)
          : RegExp(r"^-?\d*$").hasMatch(text),
    types.ScalarKind_floatWrapper() => RegExp(
      r"^[+-]?(?:(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d*)?)?$",
    ).hasMatch(text),
    _ when scalar == types.ScalarKind.decimal => RegExp(
      r"^-?(?:\d*(?:\.\d*)?)?$",
    ).hasMatch(text),
    _ => false,
  };
  if (!partial) return false;
  if (text.isEmpty || text == "-" || text == "+") return true;
  if (text.endsWith(".") ||
      text.endsWith("e") ||
      text.endsWith("E") ||
      text.endsWith("e+") ||
      text.endsWith("e-") ||
      text.endsWith("E+") ||
      text.endsWith("E-")) {
    return true;
  }
  return admitPortableNumericInput(
        current: current,
        expected: expected,
        text: text,
      ) !=
      null;
}

String? portableNumericInputText({
  required types.DataValue? current,
  required types.TypeUse? expected,
}) {
  final scalar = _numericScalar(current, expected);
  return switch (current) {
    types.DataValue_integerWrapper(:final value) => value,
    types.DataValue_floatWrapper(value: final numeric) => switch (scalar) {
      types.ScalarKind_floatWrapper(value: final float) =>
        float.width == types.FloatWidth.thirtyTwo
            ? _shortestFloat32(numeric)
            : numeric.toString(),
      _ => numeric.toString(),
    },
    types.DataValue_decimalWrapper(:final value) => value,
    _ when current == types.DataValue.unfilled => "",
    _ => null,
  };
}

types.ScalarKind? _numericScalar(
  types.DataValue? current,
  types.TypeUse? expected,
) {
  var type = expected;
  while (type is types.TypeUse_nullableWrapper) {
    type = type.value.value;
  }
  if (type case types.TypeUse_scalarWrapper(:final value)) {
    if (value is types.ScalarKind_integerWrapper ||
        value is types.ScalarKind_floatWrapper ||
        value == types.ScalarKind.decimal) {
      return value;
    }
  }
  return switch (current) {
    types.DataValue_integerWrapper() => types.ScalarKind.createInteger(
      width: types.IntegerWidth.signedSixtyFour,
    ),
    types.DataValue_floatWrapper() => types.ScalarKind.createFloat(
      width: types.FloatWidth.sixtyFour,
    ),
    types.DataValue_decimalWrapper() => types.ScalarKind.decimal,
    _ => null,
  };
}

types.DataValue? _integerValue(String source, types.IntegerWidth width) {
  final value = BigInt.tryParse(source);
  if (value == null) return null;
  final bounds = switch (width.kind) {
    types.IntegerWidth_kind.signedEightConst => _signedBounds(8),
    types.IntegerWidth_kind.signedSixteenConst => _signedBounds(16),
    types.IntegerWidth_kind.signedThirtyTwoConst => _signedBounds(32),
    types.IntegerWidth_kind.signedSixtyFourConst => _signedBounds(64),
    types.IntegerWidth_kind.unsignedEightConst => _unsignedBounds(8),
    types.IntegerWidth_kind.unsignedSixteenConst => _unsignedBounds(16),
    types.IntegerWidth_kind.unsignedThirtyTwoConst => _unsignedBounds(32),
    types.IntegerWidth_kind.unsignedSixtyFourConst => _unsignedBounds(64),
    _ => null,
  };
  if (bounds == null || value < bounds.$1 || value > bounds.$2) return null;
  return types.DataValue.wrapInteger(value.toString());
}

(BigInt, BigInt) _signedBounds(int bits) {
  final magnitude = BigInt.one << (bits - 1);
  return (-magnitude, magnitude - BigInt.one);
}

(BigInt, BigInt) _unsignedBounds(int bits) =>
    (BigInt.zero, (BigInt.one << bits) - BigInt.one);

types.DataValue? _floatValue(String source, types.FloatWidth width) {
  final value = double.tryParse(source);
  if (value == null || !value.isFinite) return null;
  if (width == types.FloatWidth.thirtyTwo) {
    final narrowed = Float32List.fromList([value]).single;
    if (!narrowed.isFinite) return null;
    return types.DataValue.wrapFloat(narrowed);
  }
  return types.DataValue.wrapFloat(value);
}

String _shortestFloat32(double value) {
  final narrowed = Float32List.fromList([value]).single;
  final expectedBits = _float32Bits(narrowed);
  if (narrowed == narrowed.truncateToDouble() && narrowed.abs() < 1e12) {
    final ordinary = narrowed.toInt().toString();
    if (_float32Bits(double.parse(ordinary)) == expectedBits) {
      return ordinary;
    }
  }
  for (var precision = 1; precision <= 9; precision++) {
    final candidate = narrowed.toStringAsPrecision(precision);
    final parsed = double.tryParse(candidate);
    if (parsed != null && _float32Bits(parsed) == expectedBits) {
      return candidate;
    }
  }
  return narrowed.toString();
}

int _float32Bits(double value) {
  final bytes = ByteData(4)..setFloat32(0, value, Endian.little);
  return bytes.getUint32(0, Endian.little);
}

types.DataValue? _decimalValue(String source) {
  final matched = RegExp(r"^(-?)(\d*)(?:\.(\d+))?$").firstMatch(source);
  if (matched == null) return null;
  final fraction = matched.group(3);
  var whole = matched.group(2)!;
  if (whole.isEmpty && fraction == null) return null;
  whole = whole.replaceFirst(RegExp(r"^0+(?=\d)"), "");
  if (whole.isEmpty) whole = "0";
  final sign = matched.group(1)!;
  final canonical = "$sign$whole${fraction == null ? "" : ".$fraction"}";
  return types.DataValue.wrapDecimal(canonical);
}
