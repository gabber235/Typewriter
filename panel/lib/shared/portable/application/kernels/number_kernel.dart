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

  /// More than 20000 fraction digits, or a result of more than 20000 digits,
  /// fails `magnitude_limit`.
  @override
  String format(skir.PortableNumber value, int fractionDigits, String locale) {
    if (fractionDigits < 0) {
      _illTyped("The fraction digits $fractionDigits are negative.");
    }
    if (fractionDigits > portableMaximumDigits) portableMagnitudeLimit();
    final resolved = resolvePortableLocale(locale, NumberFormat.localeExists);
    final exact = _visibleDecimal(value);
    // The whole part has at least this many digits, so an oversized result
    // fails before it is rendered.
    final wholeDigits = exact.unscaled.abs().toString().length - exact.scale;
    if (wholeDigits + fractionDigits > portableMaximumDigits) {
      portableMagnitudeLimit();
    }
    final coefficient = skir.roundQuotient(
      exact.unscaled * _ten.pow(fractionDigits),
      _ten.pow(exact.scale),
      skir.RoundingMode.nearestTiesToEven,
    );
    final digits = coefficient.abs().toString().padLeft(
      fractionDigits + 1,
      "0",
    );
    if (digits.length > portableMaximumDigits) portableMagnitudeLimit();
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
      integer: (left, right) => requireIntegerMagnitude(left * right),
      decimal: (left, right) => requireDecimalMagnitude(left * right),
      float: (left, right) => left * right,
    ),
  );

  /// The CLDR operands come exactly from the value's visible decimal (a
  /// float's shortest round trip decimal): `i` its integer digits, `v` its
  /// fraction digit count and `f` and `t` its fraction digits. intl derives
  /// operands from a double itself, which rounds `i` and loses digits, so
  /// [_pluralOperands] hands it a small representative from which it
  /// derives operands every one of its rules reads identically. A magnitude
  /// of 10^21 or more, or more than 20 fraction digits, fails
  /// `magnitude_limit`, as the operation declares.
  @override
  skir.PluralCategory pluralCategory(skir.PortableNumber value, String locale) {
    // intl itself falls back from region to language to the root rules.
    final resolved = resolvePortableLocale(locale, (_) => true);
    final visible = _visibleDecimal(value).normalized();
    // A number whose integer part has 22 digits is at least 10^21.
    final wholeDigits =
        visible.unscaled.abs().toString().length - visible.scale;
    if (visible.scale > _pluralFractionDigits ||
        (!visible.isZero && wholeDigits > _pluralWholeDigits)) {
      portableMagnitudeLimit();
    }
    if (resolved == null) return skir.PluralCategory.other;
    final (howMany, precision) = _pluralOperands(visible);
    return Intl.pluralLogic(
      howMany,
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
        requireIntegerMagnitude(_boundedPower(value, exponent)),
      ),
      skir.PortableDecimalNumber(:final value) => () {
        final base = value.normalized();
        if (base.scale * exponent > portableMaximumDigits) {
          portableMagnitudeLimit();
        }
        return skir.PortableDecimalNumber(
          requireDecimalMagnitude(
            skir.PortableDecimal(
              _boundedPower(base.unscaled, exponent),
              base.scale * exponent,
            ).normalized(),
          ),
        );
      }(),
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

/// [base] to the power [exponent], failing `magnitude_limit` before
/// computing a power that surely has too many digits. The bases -1, 0 and 1
/// take any exponent.
BigInt _boundedPower(BigInt base, int exponent) {
  if (base.abs() > BigInt.one &&
      (base.bitLength - 1) * exponent > portableMaximumBits) {
    portableMagnitudeLimit();
  }
  return base.pow(exponent);
}

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

/// The decimal people read for [value]: a float's shortest round trip
/// decimal, otherwise the exact value.
skir.PortableDecimal _visibleDecimal(skir.PortableNumber value) =>
    switch (value) {
      skir.PortableFloat(:final value) => skir.PortableDecimal.parse(
        portableFloatText(value),
      ),
      _ => _exactDecimal(value),
    };

/// A number and precision from which intl's `startRuleEvaluation` derives
/// operands that agree with the exact operands of [value] on everything its
/// rules read.
///
/// intl's rules read `i` modulo 10, 100 and 1000000 and its equality with
/// small numbers; `v` as zero, nonzero or two; `f` and `t` modulo 10 and
/// 100 and their equality with zero or one; and `n` only through equality
/// with integers, so a fractional `n` never matches. The representative
/// keeps exactly these: `i` above 1000000 becomes 1000000 plus its remainder,
/// `v` above three becomes three, and `f` above 100 becomes 100 plus its
/// remainder (its last digit is nonzero, so `t` follows `f`). intl takes `i`
/// as the rounded number and `f` from the floor of the scaled number, so the
/// representative is `(i * 10^v + f + 0.5) / 10^v`, one lower when its
/// fraction would round `i` up. All of it stays far inside the doubles intl
/// computes with.
(num, int) _pluralOperands(skir.PortableDecimal value) {
  final magnitude = value.normalized();
  final unscaled = magnitude.unscaled.abs();
  final scale = magnitude.scale;
  final integer = scale <= 0
      ? unscaled * _ten.pow(-scale)
      : unscaled ~/ _ten.pow(scale);
  final fraction = scale <= 0 ? BigInt.zero : unscaled % _ten.pow(scale);
  final i = integer < _million
      ? integer.toInt()
      : (_million + integer % _million).toInt();
  if (scale <= 0) return (i, 0);
  final v = min(scale, 3);
  final f = fraction < _hundred
      ? fraction.toInt()
      : (_hundred + fraction % _hundred).toInt();
  final base = pow(10, v).toInt();
  final whole = 2 * f < base ? i : i - 1;
  return ((whole * base + f + 0.5) / base, v);
}

/// The bounds number.plural_category declares: magnitudes below 10^21 (at
/// most 21 integer digits) with at most 20 fraction digits.
const _pluralWholeDigits = 21;
const _pluralFractionDigits = 20;

final _million = BigInt.from(1000000);
final _hundred = BigInt.from(100);

Never _familyMismatch() =>
    _illTyped("Numeric operands must use one numeric family.");

Never _illTyped(String message) => throw skir.PortableOperationFailure(
  skir.PortableFailures.illTypedArgument,
  message,
);
