import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

bool admitsPortableScalarValue(skir.ScalarKind expected, skir.DataValue value) {
  if (expected == skir.ScalarKind.unit) return value == skir.DataValue.unit;
  if (expected == skir.ScalarKind.boolean) {
    return value is skir.DataValue_booleanWrapper;
  }
  if (expected == skir.ScalarKind.text) {
    return value is skir.DataValue_stringValueWrapper;
  }
  if (expected == skir.ScalarKind.bytes) {
    return value is skir.DataValue_bytesWrapper;
  }
  if (expected == skir.ScalarKind.decimal) {
    return switch (value) {
      skir.DataValue_decimalWrapper(:final value) => switch (_decimalValue(
        value,
      )) {
        skir.DataValue_decimalWrapper(value: final canonical) =>
          canonical == value,
        _ => false,
      },
      _ => false,
    };
  }
  if (expected == skir.ScalarKind.timestamp) {
    return value is skir.DataValue_timestampWrapper;
  }
  if (expected == skir.ScalarKind.duration) {
    return value is skir.DataValue_durationWrapper;
  }
  if (expected case skir.ScalarKind_integerWrapper(value: final integer)) {
    return value is skir.DataValue_integerWrapper &&
        _integerValue(value.value, integer.width) != null;
  }
  if (expected case skir.ScalarKind_floatWrapper(value: final float)) {
    if (value is! skir.DataValue_floatWrapper || !value.value.isFinite) {
      return false;
    }
    if (float.width == skir.FloatWidth.thirtyTwo) {
      final narrowed = Float32List.fromList([value.value]).single;
      return narrowed.isFinite && narrowed == value.value;
    }
    return float.width == skir.FloatWidth.sixtyFour;
  }
  return false;
}

skir.DataValue? admitPortableNumericInput({
  required skir.DataValue? current,
  required skir.TypeUse? expected,
  required String text,
}) {
  final scalar = _numericScalar(current, expected);
  return switch (scalar) {
    skir.ScalarKind_integerWrapper(:final value) => _integerValue(
      text,
      value.width,
    ),
    skir.ScalarKind_floatWrapper(:final value) => _floatValue(
      text,
      value.width,
    ),
    _ when scalar == skir.ScalarKind.decimal => _decimalValue(text),
    _ => null,
  };
}

bool acceptsPortableNumericInput({
  required skir.DataValue? current,
  required skir.TypeUse? expected,
  required String text,
}) {
  final scalar = _numericScalar(current, expected);
  final partial = switch (scalar) {
    skir.ScalarKind_integerWrapper(:final value) =>
      value.width.kind.name.startsWith("unsigned")
          ? RegExp(r"^\d*$").hasMatch(text)
          : RegExp(r"^-?\d*$").hasMatch(text),
    skir.ScalarKind_floatWrapper() => RegExp(
      r"^[+-]?(?:(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d*)?)?$",
    ).hasMatch(text),
    _ when scalar == skir.ScalarKind.decimal => RegExp(
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
  required skir.DataValue? current,
  required skir.TypeUse? expected,
}) {
  final scalar = _numericScalar(current, expected);
  return switch (current) {
    skir.DataValue_integerWrapper(:final value) => value,
    skir.DataValue_floatWrapper(value: final numeric) => switch (scalar) {
      skir.ScalarKind_floatWrapper(value: final float) =>
        float.width == skir.FloatWidth.thirtyTwo
            ? _shortestFloat32(numeric)
            : numeric.toString(),
      _ => numeric.toString(),
    },
    skir.DataValue_decimalWrapper(:final value) => value,
    _ when current == skir.DataValue.unfilled => "",
    _ => null,
  };
}

skir.ScalarKind? _numericScalar(
  skir.DataValue? current,
  skir.TypeUse? expected,
) {
  var type = expected;
  while (type is skir.TypeUse_nullableWrapper) {
    type = type.value.value;
  }
  if (type case skir.TypeUse_scalarWrapper(:final value)) {
    if (value is skir.ScalarKind_integerWrapper ||
        value is skir.ScalarKind_floatWrapper ||
        value == skir.ScalarKind.decimal) {
      return value;
    }
  }
  return switch (current) {
    skir.DataValue_integerWrapper() => skir.ScalarKind.createInteger(
      width: skir.IntegerWidth.signedSixtyFour,
    ),
    skir.DataValue_floatWrapper() => skir.ScalarKind.createFloat(
      width: skir.FloatWidth.sixtyFour,
    ),
    skir.DataValue_decimalWrapper() => skir.ScalarKind.decimal,
    _ => null,
  };
}

skir.DataValue? _integerValue(String source, skir.IntegerWidth width) {
  final value = BigInt.tryParse(source);
  if (value == null) return null;
  final bounds = switch (width.kind) {
    skir.IntegerWidth_kind.signedEightConst => _signedBounds(8),
    skir.IntegerWidth_kind.signedSixteenConst => _signedBounds(16),
    skir.IntegerWidth_kind.signedThirtyTwoConst => _signedBounds(32),
    skir.IntegerWidth_kind.signedSixtyFourConst => _signedBounds(64),
    skir.IntegerWidth_kind.unsignedEightConst => _unsignedBounds(8),
    skir.IntegerWidth_kind.unsignedSixteenConst => _unsignedBounds(16),
    skir.IntegerWidth_kind.unsignedThirtyTwoConst => _unsignedBounds(32),
    skir.IntegerWidth_kind.unsignedSixtyFourConst => _unsignedBounds(64),
    _ => null,
  };
  if (bounds == null || value < bounds.$1 || value > bounds.$2) return null;
  return skir.DataValue.wrapInteger(value.toString());
}

(BigInt, BigInt) _signedBounds(int bits) {
  final magnitude = BigInt.one << (bits - 1);
  return (-magnitude, magnitude - BigInt.one);
}

(BigInt, BigInt) _unsignedBounds(int bits) =>
    (BigInt.zero, (BigInt.one << bits) - BigInt.one);

skir.DataValue? _floatValue(String source, skir.FloatWidth width) {
  final value = double.tryParse(source);
  if (value == null || !value.isFinite) return null;
  if (width == skir.FloatWidth.thirtyTwo) {
    final narrowed = Float32List.fromList([value]).single;
    if (!narrowed.isFinite) return null;
    return skir.DataValue.wrapFloat(narrowed);
  }
  return skir.DataValue.wrapFloat(value);
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

skir.DataValue? _decimalValue(String source) {
  final matched = RegExp(r"^(-?)(\d*)(?:\.(\d+))?$").firstMatch(source);
  if (matched == null) return null;
  final fraction = matched.group(3);
  var whole = matched.group(2)!;
  if (whole.isEmpty && fraction == null) return null;
  whole = whole.replaceFirst(RegExp(r"^0+(?=\d)"), "");
  if (whole.isEmpty) whole = "0";
  final sign = matched.group(1)!;
  final canonical = "$sign$whole${fraction == null ? "" : ".$fraction"}";
  return skir.DataValue.wrapDecimal(canonical);
}
