import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's numeric operations. Every call uses one numeric family:
/// integers are exact and unbounded, decimals exact except division and
/// square roots (34 significant digits, half even), and floats follow IEEE 754
/// with every non finite result failing `non_finite_number`.
final class PanelNumberKernel implements skir.NumberKernel {
  const PanelNumberKernel();

  @override
  skir.PortableNumber add(
    skir.PortableNumber first,
    skir.PortableNumber second,
    List<skir.PortableNumber> rest,
  ) => [second, ...rest].fold(
    first,
    (sum, value) => _arithmetic(
      sum,
      value,
      integer: (left, right) => left + right,
      decimal: (left, right) => left + right,
      float: (left, right) => left + right,
    ),
  );

  @override
  skir.PortableNumber convert(skir.PortableNumber value, skir.TypeUse mType) =>
      switch (mType) {
        skir.TypeUse_scalarWrapper(value: final kind) => switch (kind) {
          skir.ScalarKind_integerWrapper(value: final scalar) => _toInteger(
            value,
            scalar.width,
          ),
          skir.ScalarKind_floatWrapper(value: final scalar) => _toFloat(
            value,
            single: scalar.width == skir.FloatWidth.thirtyTwo,
          ),
          _ when kind == skir.ScalarKind.decimal => skir.PortableDecimalNumber(
            _exactDecimal(value),
          ),
          _ => _illTyped("number.convert needs a numeric target type."),
        },
        _ => _illTyped("number.convert needs a numeric target type."),
      };

  @override
  skir.PortableNumber divide(
    skir.PortableNumber dividend,
    skir.PortableNumber divisor,
  ) {
    _requireNonzero(divisor);
    return _arithmetic(
      dividend,
      divisor,
      integer: (left, right) => left ~/ right,
      decimal: (left, right) => left.divide(right),
      float: (left, right) => left / right,
    );
  }

  @override
  String format(skir.PortableNumber value, int fractionDigits, String locale) {
    if (fractionDigits < 0) {
      _illTyped("The fraction digits $fractionDigits are negative.");
    }
    final resolved = resolvePortableLocale(locale, NumberFormat.localeExists);
    // A float formats from its shortest round trip decimal, as people read it.
    final exact = switch (value) {
      skir.PortableFloat(:final value) => skir.PortableDecimal.parse(
        portableFloatText(value),
      ),
      _ => _exactDecimal(value),
    };
    final coefficient = skir.roundQuotient(
      exact.unscaled * _ten.pow(fractionDigits),
      _ten.pow(exact.scale),
      skir.RoundingMode.nearestTiesToEven,
    );
    final digits = coefficient.abs().toString().padLeft(
      fractionDigits + 1,
      "0",
    );
    var whole = digits.substring(0, digits.length - fractionDigits);
    final fraction = digits.substring(digits.length - fractionDigits);
    if (resolved == null) {
      return "${coefficient.isNegative ? "-" : ""}$whole"
          "${fraction.isEmpty ? "" : ".$fraction"}";
    }
    final symbols = NumberFormat.decimalPattern(resolved).symbols;
    final pattern = symbols.DECIMAL_PATTERN.split(";").first.split(".").first;
    final groups = pattern.split(",");
    if (groups.length > 1) {
      final primary = groups.last.replaceAll(RegExp("[^0#]"), "").length;
      final secondary = groups.length > 2
          ? groups[groups.length - 2].replaceAll(RegExp("[^0#]"), "").length
          : primary;
      final chunks = <String>[];
      var end = whole.length;
      var size = primary;
      while (end > size) {
        chunks.insert(0, whole.substring(end - size, end));
        end -= size;
        size = secondary;
      }
      chunks.insert(0, whole.substring(0, end));
      whole = chunks.join(symbols.GROUP_SEP);
    }
    final text =
        "${coefficient.isNegative ? symbols.MINUS_SIGN : ""}$whole"
        "${fraction.isEmpty ? "" : "${symbols.DECIMAL_SEP}$fraction"}";
    final zero = symbols.ZERO_DIGIT.runes.first;
    if (zero == 0x30) return text;
    return String.fromCharCodes(
      text.runes.map(
        (rune) => rune >= 0x30 && rune <= 0x39 ? zero + rune - 0x30 : rune,
      ),
    );
  }

  @override
  skir.PortableNumber multiply(
    skir.PortableNumber first,
    skir.PortableNumber second,
    List<skir.PortableNumber> rest,
  ) => [second, ...rest].fold(
    first,
    (product, value) => _arithmetic(
      product,
      value,
      integer: (left, right) => left * right,
      decimal: (left, right) => left * right,
      float: (left, right) => left * right,
    ),
  );

  @override
  skir.PluralCategory pluralCategory(skir.PortableNumber value, String locale) {
    // intl itself falls back from region to language to the root rules.
    final resolved = resolvePortableLocale(locale, (_) => true);
    if (resolved == null) return skir.PluralCategory.other;
    final (amount, precision) = switch (value) {
      skir.PortableInteger(:final value) => (value.toDouble(), 0),
      skir.PortableDecimalNumber(:final value) => (
        value.toDouble(),
        value.normalized().scale,
      ),
      skir.PortableFloat(:final value) => (
        value,
        _fractionDigits(portableFloatText(value)),
      ),
    };
    return Intl.pluralLogic(
      amount,
      zero: skir.PluralCategory.zero,
      one: skir.PluralCategory.one,
      two: skir.PluralCategory.two,
      few: skir.PluralCategory.few,
      many: skir.PluralCategory.many,
      other: skir.PluralCategory.other,
      locale: resolved,
      precision: precision,
      useExplicitNumberCases: false,
    );
  }

  @override
  skir.PortableNumber power(skir.PortableNumber value, int exponent) {
    if (exponent < 0) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.negativeExponent,
        "The exponent $exponent is negative.",
      );
    }
    return switch (value) {
      skir.PortableInteger(:final value) => skir.PortableInteger(
        value.pow(exponent),
      ),
      skir.PortableDecimalNumber(:final value) => skir.PortableDecimalNumber(
        value.power(exponent),
      ),
      skir.PortableFloat(:final value) => skir.PortableFloat(
        _finite(_floatPower(value, exponent)),
      ),
    };
  }

  @override
  skir.PortableNumber remainder(
    skir.PortableNumber dividend,
    skir.PortableNumber divisor,
  ) {
    _requireNonzero(divisor);
    return _arithmetic(
      dividend,
      divisor,
      integer: (left, right) => left.remainder(right),
      decimal: (left, right) => left.remainder(right),
      float: (left, right) => left.remainder(right),
    );
  }

  @override
  skir.PortableNumber round(
    skir.PortableNumber value,
    skir.PortableNumber increment,
    skir.RoundingMode mode,
  ) {
    final step = _exactDecimal(increment);
    if (step.unscaled <= BigInt.zero) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.invalidRoundingIncrement,
      );
    }
    final source = _exactDecimal(value);
    final multiple = skir.roundQuotient(
      source.unscaled * _ten.pow(step.scale),
      step.unscaled * _ten.pow(source.scale),
      mode,
    );
    final rounded = skir.PortableDecimal.integer(multiple) * step;
    return switch ((value, increment)) {
      (skir.PortableInteger(), skir.PortableInteger()) => skir.PortableInteger(
        rounded.unscaled,
      ),
      (skir.PortableDecimalNumber(), skir.PortableDecimalNumber()) =>
        skir.PortableDecimalNumber(rounded),
      (skir.PortableFloat(), skir.PortableFloat()) => skir.PortableFloat(
        _finite(rounded.toDouble()),
      ),
      _ => _familyMismatch(),
    };
  }

  @override
  skir.PortableNumber sqrt(skir.PortableNumber value) {
    if (switch (value) {
      skir.PortableInteger(:final value) => value.isNegative,
      skir.PortableDecimalNumber(:final value) => value.isNegative,
      skir.PortableFloat(:final value) => value < 0,
    }) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.negativeSquareRoot,
      );
    }
    return switch (value) {
      skir.PortableInteger(:final value) => skir.PortableInteger(
        skir.integerSquareRoot(value),
      ),
      skir.PortableDecimalNumber(:final value) => skir.PortableDecimalNumber(
        value.sqrt(),
      ),
      skir.PortableFloat(:final value) => skir.PortableFloat(
        _squareRoot(value),
      ),
    };
  }

  @override
  skir.PortableNumber subtract(
    skir.PortableNumber first,
    skir.PortableNumber second,
  ) => _arithmetic(
    first,
    second,
    integer: (left, right) => left - right,
    decimal: (left, right) => left - right,
    float: (left, right) => left - right,
  );
}

final _ten = BigInt.from(10);

/// IEEE 754 square root, correctly rounded on every platform.
double _squareRoot(double value) => sqrt(value);

/// Applies one operation to two numbers of the same family.
skir.PortableNumber _arithmetic(
  skir.PortableNumber left,
  skir.PortableNumber right, {
  required BigInt Function(BigInt left, BigInt right) integer,
  required skir.PortableDecimal Function(
    skir.PortableDecimal left,
    skir.PortableDecimal right,
  )
  decimal,
  required double Function(double left, double right) float,
}) => switch ((left, right)) {
  (
    skir.PortableInteger(value: final a),
    skir.PortableInteger(value: final b),
  ) =>
    skir.PortableInteger(integer(a, b)),
  (
    skir.PortableDecimalNumber(value: final a),
    skir.PortableDecimalNumber(value: final b),
  ) =>
    skir.PortableDecimalNumber(decimal(a, b)),
  (skir.PortableFloat(value: final a), skir.PortableFloat(value: final b)) =>
    skir.PortableFloat(_finite(float(a, b))),
  _ => _familyMismatch(),
};

void _requireNonzero(skir.PortableNumber divisor) {
  if (switch (divisor) {
    skir.PortableInteger(:final value) => value == BigInt.zero,
    skir.PortableDecimalNumber(:final value) => value.isZero,
    skir.PortableFloat(:final value) => value == 0,
  }) {
    throw skir.PortableOperationFailure(skir.PortableFailures.divisionByZero);
  }
}

double _finite(double value) => value.isFinite
    ? value
    : throw skir.PortableOperationFailure(
        skir.PortableFailures.nonFiniteNumber,
      );

/// Square and multiply over the exponent bits from the least significant,
/// so both hosts round the same intermediate products.
double _floatPower(double base, int exponent) {
  var result = 1.0;
  var factor = base;
  var remaining = exponent;
  while (remaining > 0) {
    if (remaining.isOdd) result *= factor;
    factor *= factor;
    remaining >>= 1;
  }
  return result;
}

/// The exact decimal value of any number; floats through their binary value.
skir.PortableDecimal _exactDecimal(skir.PortableNumber value) =>
    switch (value) {
      skir.PortableInteger(:final value) => skir.PortableDecimal.integer(value),
      skir.PortableDecimalNumber(:final value) => value,
      skir.PortableFloat(:final value) => skir.PortableDecimal.fromDouble(
        value,
      ),
    };

skir.PortableNumber _toInteger(
  skir.PortableNumber value,
  skir.IntegerWidth width,
) {
  final exact = _exactDecimal(value).normalized();
  final (minimum, maximum) = _integerRange(width);
  if (exact.scale != 0 ||
      exact.unscaled < minimum ||
      exact.unscaled > maximum) {
    throw skir.PortableOperationFailure(
      skir.PortableFailures.inexactConversion,
    );
  }
  return skir.PortableInteger(exact.unscaled);
}

(BigInt, BigInt) _integerRange(skir.IntegerWidth width) {
  final (bits, signed) = switch (width) {
    skir.IntegerWidth.signedEight => (8, true),
    skir.IntegerWidth.signedSixteen => (16, true),
    skir.IntegerWidth.signedThirtyTwo => (32, true),
    skir.IntegerWidth.signedSixtyFour => (64, true),
    skir.IntegerWidth.unsignedEight => (8, false),
    skir.IntegerWidth.unsignedSixteen => (16, false),
    skir.IntegerWidth.unsignedThirtyTwo => (32, false),
    skir.IntegerWidth.unsignedSixtyFour => (64, false),
    _ => _illTyped("Unknown integer width."),
  };
  return signed
      ? (-(BigInt.one << (bits - 1)), (BigInt.one << (bits - 1)) - BigInt.one)
      : (BigInt.zero, (BigInt.one << bits) - BigInt.one);
}

skir.PortableNumber _toFloat(
  skir.PortableNumber value, {
  required bool single,
}) {
  final exact = _exactDecimal(value);
  final candidate = switch (value) {
    skir.PortableFloat(:final value) => value,
    _ => exact.toDouble(),
  };
  final representable =
      candidate.isFinite &&
      skir.PortableDecimal.fromDouble(candidate) == exact &&
      (!single || (Float32List(1)..[0] = candidate)[0] == candidate);
  if (!representable) {
    throw skir.PortableOperationFailure(
      skir.PortableFailures.inexactConversion,
    );
  }
  return skir.PortableFloat(candidate);
}

/// The number of digits after the point of [text], before any exponent.
int _fractionDigits(String text) {
  final mantissa = text.split("e").first;
  final point = mantissa.indexOf(".");
  final digits = point < 0 ? 0 : mantissa.length - point - 1;
  final exponent = text.contains("e") ? int.parse(text.split("e").last) : 0;
  return max(0, digits - exponent);
}

Never _familyMismatch() =>
    _illTyped("Numeric operands must use one numeric family.");

Never _illTyped(String message) => throw skir.PortableOperationFailure(
  skir.PortableFailures.illTypedArgument,
  message,
);
