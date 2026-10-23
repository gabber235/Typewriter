import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Number and duration parsing over text far longer than any portable result:
/// the outcome depends on the significant digits only, never on how many
/// padding zeros or digits the text carries.
void main() {
  const kernel = PanelTextKernel();
  final zeros = "0" * 200000;

  test("a decimal with padding zeros cancelled by its exponent is small", () {
    expect(kernel.parseDecimal("1${zeros}e-200000").toString(), "1");
    expect(kernel.parseDecimal("0.${zeros}25e200001").toString(), "2.5");
    expect(kernel.parseDecimal("-$zeros.000").toString(), "0");
  });

  test("a decimal beyond the digit limit fails before it is built", () {
    expect(
      () => kernel.parseDecimal("1e200000"),
      _fails(skir.PortableFailures.magnitudeLimit),
    );
  });

  test("an exponent beyond 32 bits is not a number", () {
    expect(
      () => kernel.parseDecimal("1e${"9" * 100000}"),
      _fails(skir.PortableFailures.invalidNumberText),
    );
    expect(kernel.parseDecimal("1e${zeros}3").toString(), "1000");
  });

  test("a duration component of too many digits exceeds the range", () {
    expect(
      () => kernel.parseDuration("P${"9" * 100000}D"),
      _fails(skir.PortableFailures.durationRange),
    );
    expect(kernel.parseDuration("PT${zeros}90S"), const Duration(seconds: 90));
  });

  test("an integer whose digits exceed the limit in its radix fails", () {
    expect(
      () => kernel.parseInteger("z" * 13000, 36),
      _fails(skir.PortableFailures.magnitudeLimit),
    );
    expect(kernel.parseInteger("${zeros}ff", 16), BigInt.from(255));
  });
}

Matcher _fails(skir.FailureId failure) => throwsA(
  isA<skir.PortableOperationFailure>().having(
    (error) => error.failure,
    "failure",
    failure,
  ),
);
