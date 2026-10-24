import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

// Integers and decimals are arbitrary precision, so operations whose result
// size grows with their input (products, powers, shifts, parsed text) are
// capped: a result with more than portableMaximumDigits digits fails
// magnitude_limit. Digits count the decimal digits of an integer's magnitude,
// and of a decimal's canonical plain notation without sign and point.
// Operations whose size bound is visible before computing check that bound
// first, so an oversized result is never materialized. Kotlin's
// PortableMagnitude.kt applies the same rule.

/// The most decimal digits an integer or decimal result may have.
const portableMaximumDigits = 20000;

/// A magnitude of more bits always has more than [portableMaximumDigits]
/// decimal digits: ceil(20000 * log2(10)).
const portableMaximumBits = 66439;

/// Fails `magnitude_limit`.
Never portableMagnitudeLimit() => throw skir.PortableOperationFailure(
  skir.PortableFailures.magnitudeLimit,
  "The result would have more than $portableMaximumDigits digits.",
);

/// [value] when it has at most [portableMaximumDigits] digits.
BigInt requireIntegerMagnitude(BigInt value) {
  if (value.bitLength > portableMaximumBits ||
      value.abs().toString().length > portableMaximumDigits) {
    portableMagnitudeLimit();
  }
  return value;
}

/// [value] when its canonical plain notation has at most
/// [portableMaximumDigits] digits.
skir.PortableDecimal requireDecimalMagnitude(skir.PortableDecimal value) {
  final canonical = value.normalized();
  if (canonical.unscaled.bitLength > portableMaximumBits ||
      portableDecimalDigits(
            canonical.unscaled.abs().toString().length,
            canonical.scale,
          ) >
          portableMaximumDigits) {
    portableMagnitudeLimit();
  }
  return value;
}

/// The digits of the plain notation of a decimal whose coefficient has
/// [precision] digits and [scale] fraction digits (negative for trailing
/// zeros), computed without rendering it.
int portableDecimalDigits(int precision, int scale) => scale < 0
    ? precision - scale
    : scale >= precision
    ? scale + 1
    : precision;
