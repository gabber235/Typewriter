import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's integer operations. Bitwise operations treat integers as
/// unbounded two's complement, as Java's BigInteger does.
final class PanelIntegerKernel implements skir.IntegerKernel {
  const PanelIntegerKernel();

  @override
  BigInt bitAnd(BigInt first, BigInt second, List<BigInt> rest) =>
      rest.fold(first & second, (result, value) => result & value);

  @override
  BigInt bitNot(BigInt value) => ~value;

  @override
  BigInt bitOr(BigInt first, BigInt second, List<BigInt> rest) =>
      rest.fold(first | second, (result, value) => result | value);

  @override
  BigInt bitXor(BigInt first, BigInt second, List<BigInt> rest) =>
      rest.fold(first ^ second, (result, value) => result ^ value);

  @override
  BigInt gcd(BigInt first, BigInt second) => first.gcd(second);

  @override
  BigInt shiftLeft(BigInt value, int bits) => value << _distance(bits);

  @override
  BigInt shiftRight(BigInt value, int bits) => value >> _distance(bits);

  int _distance(int bits) => bits < 0
      ? throw skir.PortableOperationFailure(
          skir.PortableFailures.negativeShift,
          "The shift distance $bits is negative.",
        )
      : bits;
}
